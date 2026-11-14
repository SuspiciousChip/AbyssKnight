# Abyss art in the prototype

The game currently uses four transparent, still character sprites:

- `knight_idle.png`
- `skeleton_idle.png`
- `wizard_idle.png`
- `shadow_idle.png`

They were generated from the supplied visual references and are used by the four character scenes. Collision shapes stay separate from the pictures, so replacing a picture should not change movement or combat. The sprites are scaled in their `.tscn` scenes because the source images are much larger than the game characters.

`abyss_atlas_concept.png` is the supplied concept atlas. The level script displays a selected background region and repeats selected terrain regions as temporary tiles. Its labels and irregular layout make it unsuitable as a final TileSet. When final art is ready, replace these regions with aligned 32 × 32 transparent tiles in a Godot `TileMapLayer`.

The current characters have simple code motion, not frame animations. Final strips are still needed for idle, run, attack, jump, hurt, and death. Keep a consistent frame size and foot position so changing animation does not shift the collision shape.
