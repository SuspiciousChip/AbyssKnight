# Abyss Knight

A 2D math platformer built with Godot 4.7. Solve an enemy's equation, then hit it the answer's number of times. Clear the enemies and solve the rune to open each level's gate.

## Play

Open `project.godot` in Godot 4.7 and run the project.

| Key | Action |
| --- | --- |
| A / D or arrow keys | Move |
| Space | Jump |
| J | Sword attack |
| Q | Heal using one potion charge |
| E | Solve a nearby enemy or rune equation |
| Esc | Close the equation window |

Correct answers restore one potion charge, up to two. Echo shards are an optional quest that can increase maximum health.
After the knight falls, choose **Bounce Back to Game** to return to the current stage with full health while keeping your progress.

## Tests

From the project directory, run:

```sh
godot --headless --path . --script res://tests/test_gate_progression.gd
godot --headless --path . --script res://tests/test_asset_load.gd
```

The native pixel art is in `assets/`. Its source pack manifest is `assets/source_manifest.json`. Figma export scripts in `tools/` are retained for future asset updates; the game does not need a Figma token to run.
