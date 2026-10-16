"""Prepare two attributed Italian reference clips without installing TTS packages."""

import hashlib
import json
import tarfile
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def prepare():
    versions = json.loads((ROOT / "versions.json").read_text(encoding="utf-8"))
    revision = versions["reference_revision"]
    base = f"https://huggingface.co/datasets/google/fleurs/resolve/{revision}/data/it_it"
    target = ROOT / "references"
    target.mkdir(exist_ok=True)
    with urllib.request.urlopen(f"{base}/dev.tsv", timeout=60) as response:
        metadata = response.read().decode("utf-8")
    candidates = {}
    for line in metadata.splitlines():
        row = line.split("\t")
        if len(row) == 7 and 96000 <= int(row[5]) <= 192000:
            candidates[row[1]] = row
    references = {}
    # Streaming stops after the two selected members; archive paths are never extracted.
    with urllib.request.urlopen(f"{base}/audio/dev.tar.gz", timeout=120) as response:
        with tarfile.open(fileobj=response, mode="r|gz") as archive:
            for member in archive:
                row = candidates.get(Path(member.name).name)
                if not row or not member.isfile() or row[6].lower() in references:
                    continue
                gender = row[6].lower()
                source = archive.extractfile(member)
                data = source.read()
                filename = f"reference_{gender}.wav"
                (target / filename).write_bytes(data)
                references[gender] = {
                    "file": filename, "text": row[2], "original_file": row[1],
                    "sample_count": int(row[5]), "sha256": hashlib.sha256(data).hexdigest(),
                    "source": f"{base}/audio/dev.tar.gz", "dataset": "Google FLEURS",
                    "license": "CC-BY-4.0", "split": "validation", "locale": "it_it",
                    "use": "Local evaluation reference; no claim of speaker identity or endorsement."
                }
                print(f"Reference {gender}: {row[1]} — {row[2]}", flush=True)
                if {"female", "male"}.issubset(references):
                    break
    if set(references) != {"female", "male"}:
        raise RuntimeError("Both Italian reference voices are required")
    (target / "manifest.json").write_text(
        json.dumps(references, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("Two references ready; no application or microphone started.", flush=True)


if __name__ == "__main__":
    prepare()
