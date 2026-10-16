"""Create level-matched listening copies and a local ZIP with provenance."""

import json
import random
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def match_levels(destination, mapping):
    import numpy as np
    import pyloudnorm as pyln
    import soundfile as sf
    levels = []
    for label, engine in mapping.items():
        result = json.loads((ROOT / "outputs" / engine / "results.json").read_text(encoding="utf-8"))
        for sample in result["samples"]:
            data, rate = sf.read(ROOT / "outputs" / engine / sample["file"])
            loudness = float(pyln.Meter(rate).integrated_loudness(data))
            gain = min(10 ** ((-24 - loudness) / 20), 0.98 / max(float(np.max(np.abs(data))), 1e-8))
            output = destination / f"{label}_{sample['file']}"
            sf.write(output, data * gain, rate, subtype="PCM_16")
            levels.append({"file": output.name, "original_lufs": loudness,
                           "gain": gain, "final_lufs": float(pyln.Meter(rate).integrated_loudness(data * gain))})
    return levels


def package():
    destination = ROOT / "outputs" / "ascolto"
    destination.mkdir(exist_ok=True)
    engines = ["qwen", "chatterbox"]
    random.Random(42).shuffle(engines)
    mapping = dict(zip(["A", "B"], engines))
    levels = match_levels(destination, mapping)
    notes = (
        "CAMPIONI ITALIANI — 16 ottobre 2026\n\n"
        "Ascolta A e B sullo stesso testo, prima femminile e poi maschile.\n"
        "I numeri 01-04 indicano racconto, dialogo, numeri/date e testo tecnico.\n"
        "Inizia dal racconto; i numeri/date sono volutamente lasciati senza correzioni.\n"
        "Le copie d'ascolto hanno volume confrontabile: solo guadagno costante,\n"
        "senza modificare velocita', pause, intonazione o togliere errori.\n"
        "Livello obiettivo: -24 LUFS, con limite di picco per evitare saturazione.\n\n"
        "Riferimenti: Google FLEURS, it_it, validation, CC-BY-4.0.\n"
        "https://huggingface.co/datasets/google/fleurs\n"
        "https://creativecommons.org/licenses/by/4.0/\n"
        "Entrambi i motori ricevono la stessa clip per ciascuna voce.\n"
        "Campioni sintetici di valutazione: nessuna identita' del parlante attribuita.\n\n"
        "La corrispondenza A/B e' nel file chiave.json.\n"
        "Le misure sono generazione offline, non latenza di riproduzione in streaming.\n"
    )
    (destination / "LEGGIMI.txt").write_text(notes, encoding="utf-8")
    (destination / "chiave.json").write_text(json.dumps(mapping, indent=2), encoding="utf-8")
    (destination / "volumi.json").write_text(json.dumps(levels, indent=2), encoding="utf-8")
    for engine in engines:
        shutil.copy2(ROOT / "outputs" / engine / "results.json", destination / f"misure_{engine}.json")
    for name, source in [("corpus.json", ROOT / "corpus.json"),
                         ("versions.json", ROOT / "versions.json"),
                         ("requirements-qwen.lock.txt", ROOT / "requirements-qwen.lock.txt"),
                         ("requirements-chatterbox.lock.txt", ROOT / "requirements-chatterbox.lock.txt"),
                         ("trascrizioni_di_controllo.json", ROOT / "outputs" / "transcripts.json"),
                         ("riferimenti.json", ROOT / "references" / "manifest.json"),
                         ("checkpoint_hashes.json", ROOT / ".cache" / "checkpoint_hashes.json")]:
        shutil.copy2(source, destination / name)
    archive = ROOT / "outputs" / "Campioni_italiani_Qwen_Chatterbox_2026-10-16.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as bundle:
        for path in sorted(destination.iterdir()):
            if path.is_file():
                bundle.write(path, path.name)
    print(f"Packaged {len(levels)} listening WAVs: {archive}", flush=True)


if __name__ == "__main__":
    package()
