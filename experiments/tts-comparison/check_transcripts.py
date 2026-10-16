"""Assist content review using a cached Whisper model on CPU; never score voice quality."""

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--model-path", type=Path, required=True)
    args = parser.parse_args()
    from faster_whisper import WhisperModel
    model = WhisperModel(str(args.model_path), device="cpu", compute_type="int8", cpu_threads=4)
    results = []
    for engine in ["qwen", "chatterbox"]:
        folder = ROOT / "outputs" / engine
        measured = json.loads((folder / "results.json").read_text(encoding="utf-8"))
        for sample in measured["samples"]:
            segments, _ = model.transcribe(
                str(folder / sample["file"]), language="it", beam_size=3,
                vad_filter=False, condition_on_previous_text=False,
            )
            transcript = " ".join(segment.text.strip() for segment in segments)
            results.append({"engine": engine, "file": sample["file"],
                            "expected": " ".join(s["text"] for s in sample["segments"]),
                            "recognized": transcript})
            print(engine, sample["file"], transcript, flush=True)
            (ROOT / "outputs" / "transcripts.json").write_text(
                json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8"
            )
    print("Content transcripts ready; spelling/number differences require review, not a naturalness score.")


if __name__ == "__main__":
    main()
