# Exporting the Figma kit for the Godot prototype

The Godot game and its math combat stay in place. This guide prepares art only. The supplied Figma file is currently unavailable to the connected account, so the names and sizes below come from the pasted asset list. The current generated sprites remain in use until the exported art is checked in Godot.

1. In Figma, open a component such as **Knight/Idle**. Select the component itself, not the entire board or a frame containing several sprites.
2. In the right sidebar, add an **Export** setting. Choose **PNG**, **1×**, and keep the background transparent. Export the other character poses, FX, tiles, props, UI items, and six scene layers in the same way. Do not include board labels or guide rectangles.
3. Name each export with lowercase words and underscores. Put every PNG in `art/figma_exports/`. Examples: `knight_idle.png`, `knight_run_a.png`, `skeleton_attack.png`, `wizard_cast.png`, `shadow_hurt.png`, `ground_top.png`, `l0_sky_moon.png`.
4. To batch-export, select all intended components with export settings and use Figma's **Export multiple** action. Export characters as individual poses, tiles as individual tiles, props as individual objects, and scene layers as six separate full-size images. Keep the source 1× sizes; the preparation script scales them down.
   For the components whose node IDs were supplied, you can instead create a local `.env` file containing `FIGMA_TOKEN=...` and run `python3 tools/export_figma_nodes.py`. This calls Figma's image endpoint at PNG 1× and saves the files under `art/figma_exports/`. Your token needs file-read access. Export tiles, props, and UI manually because their individual node IDs were not provided. Never commit `.env`.
5. Install Pillow with `python3 -m pip install Pillow`, then run `python3 tools/prepare_figma_assets.py --source art/figma_exports`. It writes native-size PNGs and character strips to `art/figma_ready/` and lists missing exports. It uses nearest-neighbor downscaling: ÷3 for characters, FX, and scene layers; ÷4 for tiles; ÷6 for props. UI exports keep their 1× size because the brief gives no UI divisor.
6. The script pads each character pose into a transparent 48×48 art-pixel cell, centered horizontally and feet-aligned at the bottom, then makes one horizontal strip per character. `manifest.json` gives the frame order. Import the results into Godot with **Nearest** texture filtering. Keep collision shapes on the existing character nodes; art must not change collision behavior.

Expected folders after preparation:

```text
art/figma_ready/
  characters/  knight_idle.png, knight_strip.png, skeleton_strip.png, wizard_strip.png, shadow_strip.png, ...
  fx/          slash.png, purple_orb.png, magic_blade.png, purple_flame.png
  tiles/       ground_top.png, stone_floor.png, spikes.png, ...
  props/       key.png, crystal.png, dead_tree.png, ...
  scene/       l0_sky_moon.png ... l5_glow.png
  ui/          heart_full.png, health_bar.png, dialog_box.png, ...
  manifest.json
```

Before replacing the art in `knight.tscn`, `skeleton.tscn`, `wizard.tscn`, `shadow.tscn`, and `test_level.tscn`, compare the exports with the design boards. The names and scales above are ready, but the Figma connector could not inspect the file, so this project has not yet been matched visually to those boards. The existing gameplay scripts and scene logic need no changes for an art swap.
