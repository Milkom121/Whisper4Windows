"""Generate matched Italian samples in a dedicated, pinned TTS environment."""

import argparse
import hashlib
import importlib.metadata
import json
import os
import random
import subprocess
import threading
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent
os.environ["HF_HOME"] = str(ROOT / ".cache" / "huggingface")
os.environ["HF_HUB_DISABLE_TELEMETRY"] = "1"
os.environ["DO_NOT_TRACK"] = "1"


def save_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2), encoding="utf-8")


class MemoryMonitor:
    def __init__(self):
        import psutil
        self.process = psutil.Process()
        self.rss_mb = 0
        self.gpu_used_mb = 0
        self.done = threading.Event()
        self.thread = threading.Thread(target=self.sample, daemon=True)

    def sample(self):
        while not self.done.is_set():
            self.rss_mb = max(self.rss_mb, self.process.memory_info().rss / 1024**2)
            try:
                result = subprocess.run(
                    ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
                    capture_output=True, text=True, timeout=5,
                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0),
                )
                if result.returncode == 0:
                    self.gpu_used_mb = max(self.gpu_used_mb, int(result.stdout.splitlines()[0]))
            except (OSError, subprocess.TimeoutExpired, ValueError):
                pass
            self.done.wait(0.5)

    def __enter__(self):
        self.thread.start()
        return self

    def __exit__(self, *args):
        self.done.set()
        self.thread.join(timeout=6)


def load_engine(engine, versions):
    import torch
    if engine == "qwen":
        from qwen_tts import Qwen3TTSModel
        path = str(ROOT / ".cache" / "models" / "qwen")
        model = Qwen3TTSModel.from_pretrained(
            path, device_map="cuda:0", dtype=torch.bfloat16, attn_implementation="sdpa"
        )
    else:
        from chatterbox.mtl_tts import ChatterboxMultilingualTTS
        path = str(ROOT / ".cache" / "models" / "chatterbox")
        model = ChatterboxMultilingualTTS.from_local(path, "cuda", t3_model="v3")
    return model


def prepare_voice(engine, model, reference):
    path = str(ROOT / "references" / reference["file"])
    if engine == "qwen":
        return model.create_voice_clone_prompt(
            ref_audio=path, ref_text=reference["text"], x_vector_only_mode=False
        )
    model.prepare_conditionals(path, exaggeration=0.5)
    return None


def synthesize(engine, model, text, prompt):
    if engine == "qwen":
        waves, rate = model.generate_voice_clone(
            text=text, language="Italian", voice_clone_prompt=prompt,
            non_streaming_mode=True, max_new_tokens=1024,
        )
        return waves[0], rate
    wave = model.generate(text, language_id="it", exaggeration=0.5, cfg_weight=0.5)
    return wave.detach().cpu().numpy().reshape(-1), model.sr


def generate_samples(args, model, versions, result):
    # Keep timing and output together so every sentence retains its measured seed/configuration.
    # Playback streaming is outside this benchmark.
    import numpy as np
    import soundfile as sf
    import torch
    references = json.loads((ROOT / "references" / "manifest.json").read_text(encoding="utf-8"))
    corpus = json.loads((ROOT / "corpus.json").read_text(encoding="utf-8"))
    output = ROOT / "outputs" / args.engine
    output.mkdir(parents=True, exist_ok=True)
    for voice in args.voices:
        start = time.perf_counter()
        prompt = prepare_voice(args.engine, model, references[voice])
        torch.cuda.synchronize()
        result["reference_prepare_s"][voice] = time.perf_counter() - start
        for sample in corpus:
            chunks, measures = [], []
            for index, text in enumerate(sample["segments"]):
                seed = versions["seed"] + index
                random.seed(seed)
                np.random.seed(seed)
                torch.manual_seed(seed)
                torch.cuda.reset_peak_memory_stats()
                torch.cuda.synchronize()
                start = time.perf_counter()
                wave, rate = synthesize(args.engine, model, text, prompt)
                torch.cuda.synchronize()
                elapsed = time.perf_counter() - start
                wave = np.asarray(wave, dtype=np.float32).reshape(-1)
                if not np.isfinite(wave).all() or len(wave) < rate:
                    raise RuntimeError(f"Invalid output for {voice}/{sample['id']}/{index}")
                measures.append({"text": text, "generation_s": elapsed,
                                 "audio_s": len(wave) / rate,
                                 "raw_peak": float(np.max(np.abs(wave))),
                                 "raw_clipped_fraction": float(np.mean(np.abs(wave) >= 1.0)),
                                 "rtf": elapsed / (len(wave) / rate),
                                 "cuda_peak_allocated_mb": torch.cuda.max_memory_allocated() / 1024**2,
                                 "cuda_peak_reserved_mb": torch.cuda.max_memory_reserved() / 1024**2})
                chunks.extend([wave, np.zeros(round(rate * 0.35), dtype=np.float32)])
                print(f"DONE {args.engine}/{voice}/{sample['id']}/{index}: {elapsed:.2f}s, audio {len(wave)/rate:.2f}s", flush=True)
            filename = f"{sample['id']}_{voice}.wav"
            audio = np.concatenate(chunks[:-1])
            sf.write(output / filename, audio, rate, subtype="PCM_16")
            result["samples"].append({"file": filename, "voice": voice,
                                      "title": sample["title"], "sample_rate": rate,
                                      "audio_s": len(audio) / rate, "segments": measures,
                                      "sha256": hashlib.sha256((output / filename).read_bytes()).hexdigest()})
            save_json(output / "results.json", result)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("engine", choices=["qwen", "chatterbox"])
    parser.add_argument("--voices", nargs="+", choices=["female", "male"], default=["female", "male"])
    args = parser.parse_args()
    import torch
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA required for this comparison; no silent CPU fallback")
    versions = json.loads((ROOT / "versions.json").read_text(encoding="utf-8"))
    result = {"engine": args.engine, "versions": versions, "device": torch.cuda.get_device_name(),
              "torch": torch.__version__, "cuda": torch.version.cuda,
              "generation": {"language": "Italian", "sentence_gap_s": 0.35,
                             "qwen": {"dtype": "bfloat16", "attention": "sdpa", "max_new_tokens": 1024, "non_streaming_mode": True},
                             "chatterbox": {"variant": "v3", "exaggeration": 0.5, "cfg_weight": 0.5}},
              "reference_prepare_s": {}, "samples": [],
              "timing_scope": "Offline inference per segment, not audible streaming latency; model download excluded only when precached.",
              "packages": {d.metadata["Name"]: d.version for d in importlib.metadata.distributions()}}
    with MemoryMonitor() as monitor:
        start = time.perf_counter()
        model = load_engine(args.engine, versions)
        torch.cuda.synchronize()
        result["model_load_s"] = time.perf_counter() - start
        print(f"LOADED {args.engine}: {result['model_load_s']:.2f}s", flush=True)
        generate_samples(args, model, versions, result)
    result["rss_peak_mb"] = monitor.rss_mb
    result["whole_gpu_peak_used_mb"] = monitor.gpu_used_mb
    result["whole_gpu_scope"] = "Includes other applications; 0.5s polling, not process-only allocation"
    save_json(ROOT / "outputs" / args.engine / "results.json", result)


if __name__ == "__main__":
    main()
