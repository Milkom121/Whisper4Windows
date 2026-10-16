"""Download only pinned public checkpoints; verify available LFS SHA-256 hashes."""

import concurrent.futures
import hashlib
import json
import time
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CHATTERBOX_FILES = {
    "ve.pt", "t3_mtl23ls_v3.safetensors", "s3gen.pt",
    "grapheme_mtl_merged_expanded_v1.json", "conds.pt", "Cangjie5_TC.json",
}


def digest(path):
    hasher = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(4 * 1024**2), b""):
            hasher.update(chunk)
    return hasher.hexdigest()


def download_one(job):
    engine, repo, revision, item = job
    name = item["rfilename"]
    target = ROOT / ".cache" / "models" / engine / name
    target.parent.mkdir(parents=True, exist_ok=True)
    expected = item.get("lfs", {}).get("sha256")
    size = item.get("size")
    if target.exists() and (not size or target.stat().st_size == size):
        found = digest(target)
        if not expected or found == expected:
            return {"engine": engine, "file": name, "sha256": found, "bytes": target.stat().st_size}
    url = f"https://huggingface.co/{repo}/resolve/{revision}/{urllib.parse.quote(name)}"
    partial = target.with_name(target.name + ".partial")
    for attempt in range(3):
        try:
            print(f"DOWNLOAD {engine}/{name}", flush=True)
            with urllib.request.urlopen(url, timeout=120) as source, partial.open("wb") as output:
                count = 0
                next_report = 256 * 1024**2
                for chunk in iter(lambda: source.read(1024**2), b""):
                    output.write(chunk)
                    count += len(chunk)
                    if count >= next_report:
                        print(f"PROGRESS {engine}/{name}: {count // 1024**2} MiB", flush=True)
                        next_report += 256 * 1024**2
            found = digest(partial)
            if expected and found != expected:
                raise RuntimeError(f"Checkpoint hash mismatch: {engine}/{name}")
            if size and partial.stat().st_size != size:
                raise RuntimeError(f"Checkpoint size mismatch: {engine}/{name}")
            partial.replace(target)
            print(f"VERIFIED {engine}/{name}: {target.stat().st_size // 1024**2} MiB", flush=True)
            return {"engine": engine, "file": name, "sha256": found, "bytes": target.stat().st_size}
        except Exception:
            if attempt == 2:
                raise
            time.sleep(2 * (attempt + 1))


def main():
    versions = json.loads((ROOT / "versions.json").read_text(encoding="utf-8"))
    jobs = []
    for engine in ["qwen", "chatterbox"]:
        repo, revision = versions[f"{engine}_model"], versions[f"{engine}_model_revision"]
        api = f"https://huggingface.co/api/models/{repo}/revision/{revision}?blobs=true"
        with urllib.request.urlopen(api, timeout=60) as response:
            info = json.load(response)
        for item in info["siblings"]:
            name = item["rfilename"]
            if engine == "chatterbox" and name not in CHATTERBOX_FILES:
                continue
            if engine == "qwen" and name.startswith("."):
                continue
            jobs.append((engine, repo, revision, item))
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(download_one, jobs))
    path = ROOT / ".cache" / "checkpoint_hashes.json"
    path.write_text(json.dumps(results, indent=2), encoding="utf-8")
    print("All pinned checkpoints verified.", flush=True)


if __name__ == "__main__":
    main()
