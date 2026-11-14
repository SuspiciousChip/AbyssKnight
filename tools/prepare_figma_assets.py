#!/usr/bin/env python3
"""Convert 1× Figma PNG exports into native pixel assets for Godot.

Requires Pillow. Missing exports are reported and never replaced with blanks.
"""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image


POSES = {
    "knight": ["idle", "run_a", "run_b", "attack", "hurt"],
    "skeleton": ["idle", "attack", "hurt"],
    "wizard": ["idle", "cast", "hurt"],
    "shadow": ["idle", "hurt"],
}
DIVISORS = {"characters": 3, "fx": 3, "parallax": 3, "tiles": 4, "props": 6, "ui": 1}


def native_image(path: Path, divisor: int) -> Image.Image:
    with Image.open(path) as source:
        image = source.convert("RGBA")
    # Figma may add transparent padding. Round to the nearest native pixel.
    size = (max(1, round(image.width / divisor)), max(1, round(image.height / divisor)))
    return image.resize(size, Image.Resampling.NEAREST)


def trimmed(image: Image.Image) -> Image.Image:
    bounds = image.getchannel("A").getbbox()
    return image.crop(bounds) if bounds else image


def frame_cell(image: Image.Image, width: int, height: int, bob: int = 0) -> Image.Image:
    cell = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    image = trimmed(image)
    x = (width - image.width) // 2
    y = height - image.height - bob
    if x < 0 or y < 0:
        raise ValueError(f"Frame {image.size} exceeds character cell {(width, height)}")
    cell.alpha_composite(image, (x, y))
    return cell


def strip(frames: list[Image.Image], destination: Path) -> None:
    result = Image.new("RGBA", (frames[0].width * len(frames), frames[0].height), (0, 0, 0, 0))
    for index, frame in enumerate(frames):
        result.alpha_composite(frame, (index * frame.width, 0))
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination)
    import_preset(destination)


def import_preset(path: Path) -> None:
    # Godot reads these settings when it first imports each PNG.
    sidecar = Path(str(path) + ".import")
    sidecar.write_text(
        "[remap]\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n"
        "[deps]\nsource_file=\"res://" + str(path).replace('\\\\', '/') + "\"\n\n"
        "[params]\ncompress/mode=0\nmipmaps/generate=false\n"
    )


def prepare_character(name: str, source: Path, output: Path, missing: list[str]) -> dict | None:
    images: dict[str, Image.Image] = {}
    for pose in POSES[name]:
        path = source / "characters" / f"{name}_{pose}.png"
        if path.is_file():
            images[pose] = trimmed(native_image(path, 3))
        else:
            missing.append(str(path))
    if "idle" not in images:
        return None
    width = max(image.width for image in images.values()) + 2
    height = max(image.height for image in images.values()) + 2
    # All frames of this character share one cell and one bottom-centre anchor.
    width = int(math.ceil(width / 2) * 2)
    height = int(math.ceil(height / 2) * 2)
    sequences: dict[str, list[tuple[str, int]]] = {
        "idle": [("idle", 0), ("idle", 1), ("idle", 0), ("idle", 1)],
        "death": [("idle", 0)],
    }
    if "run_a" in images and "run_b" in images:
        sequences["run"] = [("run_a", 0), ("run_b", 0)]
    if "attack" in images:
        sequences["attack"] = [("idle", 0), ("attack", 0)]
    if "cast" in images:
        sequences["cast"] = [("idle", 0), ("cast", 0)]
    if "hurt" in images:
        sequences["hurt"] = [("hurt", 0)]
    animations: dict[str, dict] = {}
    for animation, sequence in sequences.items():
        filename = f"characters/{name}/{animation}.png"
        frames = [frame_cell(images[pose], width, height, bob) for pose, bob in sequence]
        strip(frames, output / filename)
        animations[animation] = {"file": filename, "frames": len(frames), "fps": 10 if animation in {"run", "hurt"} else 6}
    return {"cell": [width, height], "animations": animations}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path("art/figma_exports"))
    parser.add_argument("--out", type=Path, default=Path("assets"))
    args = parser.parse_args()
    output = args.out
    output.mkdir(parents=True, exist_ok=True)
    missing: list[str] = []
    manifest: dict[str, object] = {"characters": {}, "textures": {}}
    for name in POSES:
        character = prepare_character(name, args.source, output, missing)
        if character:
            manifest["characters"][name] = character
    for group in ("fx", "parallax", "tiles", "props", "ui"):
        group_source = args.source / group
        for path in sorted(group_source.glob("*.png")):
            try:
                image = native_image(path, DIVISORS[group])
            except (OSError, ValueError) as exc:
                missing.append(f"{path}: {exc}")
                continue
            target = output / group / path.name
            target.parent.mkdir(parents=True, exist_ok=True)
            image.save(target)
            import_preset(target)
            manifest["textures"][f"{group}/{path.stem}"] = f"{group}/{path.name}"
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n")
    (output / "missing.txt").write_text("\n".join(missing) + ("\n" if missing else ""))
    counts = {group: len(list((output / group).rglob("*.png"))) for group in DIVISORS}
    print("Prepared asset counts: " + json.dumps(counts, sort_keys=True))
    print(f"Missing or invalid exports: {len(missing)} (see {output / 'missing.txt'})")


if __name__ == "__main__":
    main()
