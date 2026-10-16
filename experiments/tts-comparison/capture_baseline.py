"""Capture the existing app environment before preparing the TTS experiment."""

import hashlib
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
REPOSITORY = ROOT.parent.parent


def capture():
    baseline = {}
    for name in ["backend/requirements.txt", "frontend/src-tauri/Cargo.toml"]:
        baseline[name] = hashlib.sha256((REPOSITORY / name).read_bytes()).hexdigest()
    baseline["backend_packages"] = subprocess.check_output(
        [str(REPOSITORY / "backend/venv/Scripts/python.exe"), "-m", "pip", "freeze"], text=True
    )
    # Refuse to replace evidence from before installation with a later environment state.
    with (ROOT / "baseline.local.json").open("x", encoding="utf-8") as output:
        json.dump(baseline, output, indent=2)
    print("Pre-installation dictation baseline saved.")


if __name__ == "__main__":
    capture()
