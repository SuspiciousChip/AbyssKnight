#!/usr/bin/env python3
"""Export the Abyss Knight Figma components to PNG at 1×.

Reads FIGMA_TOKEN from the project .env. Never prints the token.
"""

from __future__ import annotations

import json
import re
import sys
import time
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


FILE_KEY = "xaK84eoB1nFhs7Wqyha0Cr"
BASE = "https://api.figma.com/v1"
MAP_PATH = Path("tools/figma_nodes.json")
OUTPUT = Path("art/figma_exports")

KNOWN: dict[str, dict[str, str]] = {
    "characters": {
        "knight_idle": "3:6", "knight_run_a": "3:109", "knight_run_b": "3:208",
        "knight_attack": "3:302", "knight_hurt": "3:395",
        "skeleton_idle": "3:498", "skeleton_attack": "3:578", "skeleton_hurt": "3:658",
        "wizard_idle": "3:738", "wizard_cast": "3:839", "wizard_hurt": "3:949",
        "shadow_idle": "3:1050", "shadow_hurt": "3:1135",
    },
    "fx": {
        "slash": "3:1220", "purple_orb": "3:1246", "magic_blade": "3:1268",
        "purple_flame": "3:1277",
    },
    "parallax": {
        "l0_sky_moon": "2004:26092", "l1_mountains": "2004:26730",
        "l2_castle": "2004:28692", "l3_ruins_trees": "2004:33451",
        "l4_foreground": "2005:37241", "l5_glow": "2005:52980",
    },
}

PREFIX_GROUP = {"Tile/": "tiles", "Prop/": "props", "Nature/": "props", "HUD/": "ui", "Icon/": "ui"}


class FigmaAPIError(Exception):
    pass


def token_from_env(path: Path) -> str:
    if not path.is_file():
        raise FigmaAPIError(f"Missing {path}. Put FIGMA_TOKEN in the project .env file.")
    for line in path.read_text().splitlines():
        if line.strip().startswith("FIGMA_TOKEN="):
            value = line.split("=", 1)[1].strip().strip('"').strip("'")
            if value:
                return value
    raise FigmaAPIError("FIGMA_TOKEN is missing or empty in .env.")


def request_bytes(url: str, token: str | None = None) -> bytes:
    headers = {"X-Figma-Token": token} if token else {}
    for attempt in range(2):
        try:
            with urlopen(Request(url, headers=headers), timeout=90) as response:
                return response.read()
        except HTTPError as exc:
            body = exc.read().decode("utf-8", "replace")
            try:
                payload = json.loads(body)
                message = str(payload.get("err") or payload.get("message") or body)
            except json.JSONDecodeError:
                message = body.strip() or exc.reason
            if exc.code == 429 and attempt == 0:
                time.sleep(3)
                continue
            raise FigmaAPIError(f"HTTP {exc.code}: {message}") from None
        except URLError as exc:
            raise FigmaAPIError(f"Network error: {exc.reason}") from None
    raise AssertionError("429 retry loop did not terminate")


def request_json(url: str, token: str) -> dict:
    return json.loads(request_bytes(url, token))


def slug(name: str) -> str:
    leaf = name.split("/", 1)[1]
    return re.sub(r"[^a-z0-9]+", "_", leaf.lower()).strip("_")


def discover_components(token: str) -> dict[str, dict[str, str]]:
    # The user supplied depth=4 for the initial lookup. The component metadata
    # map is included in the response and contains names even for deeper nodes.
    data = request_json(f"{BASE}/files/{FILE_KEY}?depth=4", token)
    found: dict[str, dict[str, str]] = {group: {} for group in PREFIX_GROUP.values()}
    for node_id, item in data.get("components", {}).items():
        name = str(item.get("name", ""))
        for prefix, group in PREFIX_GROUP.items():
            if name.startswith(prefix):
                found[group][slug(name)] = node_id
    def walk(node: dict) -> None:
        if node.get("type") == "COMPONENT":
            name = str(node.get("name", ""))
            for prefix, group in PREFIX_GROUP.items():
                if name.startswith(prefix):
                    found[group][slug(name)] = str(node["id"])
        for child in node.get("children", []):
            walk(child)
    walk(data.get("document", {}))
    return found


def load_or_make_map(token: str) -> dict[str, dict[str, str]]:
    if MAP_PATH.is_file():
        mapping = json.loads(MAP_PATH.read_text())
    else:
        mapping = discover_components(token)
        for group, entries in KNOWN.items():
            mapping[group] = entries
        MAP_PATH.write_text(json.dumps(mapping, indent=2, sort_keys=True) + "\n")
    return mapping


def export_group(group: str, entries: dict[str, str], token: str) -> int:
    if not entries:
        print(f"{group}: 0 nodes found")
        return 0
    params = urlencode({"ids": ",".join(entries.values()), "format": "png", "scale": 1})
    images = request_json(f"{BASE}/images/{FILE_KEY}?{params}", token).get("images", {})
    target = OUTPUT / group
    target.mkdir(parents=True, exist_ok=True)
    saved = 0
    for name, node_id in entries.items():
        image_url = images.get(node_id)
        if not image_url:
            print(f"{group}/{name}: Figma returned no image for node {node_id}")
            continue
        (target / f"{name}.png").write_bytes(request_bytes(image_url))
        saved += 1
    print(f"{group}: exported {saved}/{len(entries)}")
    return saved


def main() -> None:
    try:
        token = token_from_env(Path(".env"))
        mapping = load_or_make_map(token)
        totals = {group: export_group(group, entries, token) for group, entries in mapping.items()}
        (OUTPUT / "export_counts.json").write_text(json.dumps(totals, indent=2) + "\n")
    except FigmaAPIError as exc:
        print(str(exc), file=sys.stderr)
        raise SystemExit(1) from None


if __name__ == "__main__":
    main()
