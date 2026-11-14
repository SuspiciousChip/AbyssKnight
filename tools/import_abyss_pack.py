#!/usr/bin/env python3
"""Import the supplied native-pixel Abyss Knight zip into Godot assets/."""

from __future__ import annotations

import json
import shutil
import sys
import zipfile
from pathlib import Path

from PIL import Image

from prepare_figma_assets import frame_cell, import_preset, strip


NAME_MAP = {
    "knight": "knight",
    "skeleton_fighter": "skeleton",
    "skeleton_wizard": "wizard",
    "shadow_raiser": "shadow",
}


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("Usage: import_abyss_pack.py path/to/abyss-knight-assets.zip")
    archive = Path(sys.argv[1])
    output = Path("assets")
    output.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as bundle:
        members = [item for item in bundle.infolist() if not item.is_dir()]
        for item in members:
            relative = Path(item.filename)
            if relative.is_absolute() or ".." in relative.parts or relative.parts[0] != "abyss-knight-assets":
                raise ValueError(f"Unsafe archive member: {item.filename}")
        pack = json.loads(bundle.read("abyss-knight-assets/manifest.json"))
        for item in members:
            relative = Path(item.filename).relative_to("abyss-knight-assets")
            if relative.parts[0] not in {"characters", "fx", "parallax", "tiles", "props", "ui"}:
                continue
            target = output / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            with bundle.open(item) as source, target.open("wb") as dest:
                shutil.copyfileobj(source, dest)
            if target.suffix == ".png":
                import_preset(target)
    manifest: dict = {"characters": {}, "textures": {}, "source": "abyss-knight-assets.zip"}
    for entry in pack["assets"].values():
        relative = entry["file"]
        group = relative.split("/", 1)[0]
        if group in {"fx", "parallax", "tiles", "props", "ui"}:
            manifest["textures"][f"{group}/{Path(relative).stem}"] = relative
    for pack_name, game_name in NAME_MAP.items():
        sheet = pack["character_sheets"].get(pack_name)
        if not sheet:
            continue
        source = output / sheet["file"]
        if not source.exists():
            continue
        atlas = Image.open(source).convert("RGBA")
        width, height = sheet["cell"]
        poses = {name: atlas.crop((frame["x"], frame["y"], frame["x"] + width, frame["y"] + height))
                 for name, frame in sheet["frames"].items()}
        if "idle" not in poses:
            continue
        sequences = {"idle": [("idle", 0), ("idle", 1), ("idle", 0), ("idle", 1)],
                     "death": [("idle", 0)]}
        if "run_a" in poses and "run_b" in poses:
            sequences["run"] = [("run_a", 0), ("run_b", 0)]
        for action in ("attack", "cast", "hurt"):
            if action in poses:
                sequences[action] = [("idle", 0), (action, 0)] if action != "hurt" else [("hurt", 0)]
        animations = {}
        for animation, sequence in sequences.items():
            relative = f"characters/{game_name}/{animation}.png"
            strip([frame_cell(poses[pose], width, height, bob) for pose, bob in sequence], output / relative)
            animations[animation] = {"file": relative, "frames": len(sequence), "fps": 10 if animation in {"run", "hurt"} else 6}
        manifest["characters"][game_name] = {"cell": [width, height], "animations": animations}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    (output / "source_manifest.json").write_text(json.dumps(pack, indent=2) + "\n")
    (output / "missing.txt").write_text("")
    counts = {group: len(list((output / group).rglob("*.png"))) for group in ("characters", "fx", "parallax", "tiles", "props", "ui")}
    print("Imported native pixel assets: " + json.dumps(counts, sort_keys=True))


if __name__ == "__main__":
    main()
