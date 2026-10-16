"""Check actual audio artifacts, matched texts, and preservation of the working app."""

import hashlib
import json
import subprocess
import wave
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPOSITORY = ROOT.parent.parent


def validate():
    baseline = json.loads((ROOT / "baseline.local.json").read_text(encoding="utf-8"))
    for name, expected in baseline.items():
        if name != "backend_packages":
            assert hashlib.sha256((REPOSITORY / name).read_bytes()).hexdigest() == expected, name
    packages = subprocess.check_output(
        [str(REPOSITORY / "backend/venv/Scripts/python.exe"), "-m", "pip", "freeze"], text=True
    )
    assert packages == baseline["backend_packages"], "Dictation environment changed"
    corpus = json.loads((ROOT / "corpus.json").read_text(encoding="utf-8"))
    expected_files = {f"{item['id']}_{voice}.wav" for item in corpus for voice in ["female", "male"]}
    expected_text = {item["title"]: item["segments"] for item in corpus}
    for engine in ["qwen", "chatterbox"]:
        folder = ROOT / "outputs" / engine
        result = json.loads((folder / "results.json").read_text(encoding="utf-8"))
        assert {s["file"] for s in result["samples"]} == expected_files, engine
        assert "4080" in result["device"] and result["cuda"], engine
        for sample in result["samples"]:
            path = folder / sample["file"]
            assert hashlib.sha256(path.read_bytes()).hexdigest() == sample["sha256"], path
            assert [s["text"] for s in sample["segments"]] == expected_text[sample["title"]]
            assert all(s["generation_s"] > 0 and s["cuda_peak_allocated_mb"] > 0 for s in sample["segments"])
            assert all(s["raw_clipped_fraction"] < 0.001 for s in sample["segments"]), path
            with wave.open(str(path)) as audio:
                assert audio.getnchannels() == 1 and audio.getsampwidth() == 2, path
                assert audio.getframerate() == sample["sample_rate"], path
                assert abs(audio.getnframes() / audio.getframerate() - sample["audio_s"]) < 0.01
                pcm = array("h", audio.readframes(audio.getnframes()))
                assert sum(value * value for value in pcm) / len(pcm) > 100**2, (path, "Silent output")
    print("PASS: 16 valid WAVs, matched texts, CUDA inference, hashes and dictation environment preserved.")


if __name__ == "__main__":
    validate()
