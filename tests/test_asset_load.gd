extends SceneTree

const ART = preload("res://scripts/figma_art.gd")


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var manifest: Dictionary = ART.manifest()
	assert(not manifest.is_empty(), "Asset manifest missing")
	var textures: Dictionary = manifest.get("textures", {})
	for key in textures:
		assert(ART.named_texture(str(key)) != null, "Texture failed: " + str(key))
	var characters: Dictionary = manifest.get("characters", {})
	for name in ["knight", "skeleton", "wizard", "shadow"]:
		var frames: SpriteFrames = ART.character_frames(name)
		assert(frames != null, "SpriteFrames failed: " + name)
		for animation in characters[name]["animations"]:
			assert(frames.has_animation(animation), "Animation failed: " + name + "/" + animation)
			assert(frames.get_frame_count(animation) == characters[name]["animations"][animation]["frames"])
	var level: Node2D = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	await process_frame
	assert(level.get_node_or_null("FigmaParallax") != null, "Parallax missing")
	assert(level.get_node_or_null("FigmaGlow") != null, "Glow missing")
	assert(level.get_node_or_null("HUD/PortraitArt") != null, "HUD art missing")
	assert(level.get_node("Knight/Sprite2D/AnimatedSprite2D").visible, "Knight art missing")
	var visual_tiles := 0
	for platform in level.get_node("Terrain").get_children():
		for child in platform.get_children():
			if child is TileMapLayer:
				visual_tiles += 1
	assert(visual_tiles > 0, "TileSet visual tiles missing")
	var knight: CharacterBody2D = level.get_node("Knight")
	assert(knight.potion_charges == 1)
	knight.health = knight.max_health - 1
	assert(knight.use_potion(), "Potion should heal")
	assert(knight.health == knight.max_health and knight.potion_charges == 0)
	assert(not knight.use_potion(), "Empty potion should not heal")
	assert(level.get_node("HUD/PotionCount").text == "0")
	var math_ui: CanvasLayer = level.get_node("MathUI")
	var first_enemy: Node2D = level.get_node("Enemies").get_child(0)
	math_ui.open_for(first_enemy)
	assert(paused and math_ui.get_node("Center").visible and math_ui.get_node("Dim").visible)
	assert(math_ui.get_node("Center/Panel/VBox/Question").text == first_enemy.get_node("EquationLabel").text)
	assert(math_ui.get_node("Center/Panel/VBox/InputRow/XLabel").text == "= ")
	math_ui.get_node("Center/Panel/VBox/InputRow/Answer").text = str(first_enemy.answer)
	math_ui.submit_answer()
	assert(not paused and not math_ui.get_node("Center").visible and first_enemy.solved)
	assert(knight.potion_charges == 1, "Correct answer should restore one potion")
	assert(not knight.use_potion(), "Full health should not waste a potion")
	print("PASS: %d textures, %d character SpriteFrames, parallax, glow, HUD, TileSet" % [textures.size(), characters.size()])
	quit(0)
