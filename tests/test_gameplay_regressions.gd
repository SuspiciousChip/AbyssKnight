extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var level: Node2D = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	var knight: CharacterBody2D = level.get_node("Knight")
	var enemies: Array[Node] = level.get_node("Enemies").get_children()
	var skeleton: CharacterBody2D = enemies[0]
	var wizard: CharacterBody2D = enemies[1]
	wizard.cast_spell(knight)
	await physics_frame
	assert(level.get_node("Enemies").get_child_count() == 4, "Wizard spell was not created")
	assert(not level.gate_open, "Spell changed gate state")
	skeleton.global_position = Vector2(390, 600)
	await physics_frame
	await physics_frame
	assert(not skeleton.defeated and skeleton.global_position.y < 500.0, "Fallen enemy did not return")
	knight.global_position = Vector2(100, 100)
	skeleton.global_position = Vector2(130, 100)
	skeleton.solved = true
	skeleton.hits_remaining = 1
	knight.facing = -1
	knight.sword_area.position.x = -25.0
	knight.attack()
	assert(knight.get_node("SwordSound").playing, "Sword swish did not play")
	assert(not skeleton.defeated, "Left attack hit enemy on right")
	await create_timer(0.45).timeout
	knight.global_position = Vector2(100, 100)
	skeleton.global_position = Vector2(130, 100)
	knight.velocity = Vector2.ZERO
	skeleton.velocity = Vector2.ZERO
	skeleton.hit_cooldown = 0.0
	knight.facing = 1
	knight.sword_area.position.x = 25.0
	knight.attack()
	assert(skeleton.get_node("HitSound").playing, "Enemy hit sound did not play")
	assert(skeleton.defeated, "Right attack missed enemy on right")
	var math_ui: CanvasLayer = level.get_node("MathUI")
	math_ui.open_for(wizard)
	assert(paused)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	assert(not paused and not math_ui.get_node("Center").visible, "Escape did not close math dialog")
	knight.health = 1
	knight.damage_cooldown = 0.0
	knight.take_damage(1)
	assert(knight.get_node("DeathSound").playing, "Death sound did not play")
	assert(knight.dead and knight.health == 0, "Knight did not enter death state")
	await create_timer(0.75).timeout
	assert(level.get_node("RetryUI").visible and paused, "Death window did not appear")
	assert(level.get_node("RetryUI/Center/Panel/VBox/BounceBackButton").text == "Bounce Back to Game")
	level.bounce_back_to_game()
	assert(not paused and not knight.dead and knight.health == knight.max_health)
	assert(knight.global_position == Vector2(0, 100), "Bounce back did not return to stage start")
	var bridge: StaticBody2D = level.get_node("Terrain").get_child(4)
	var drawn_width := 0.0
	for child in bridge.get_children():
		if child is Sprite2D and child.region_enabled:
			drawn_width += child.region_rect.size.x
	assert(is_equal_approx(drawn_width, 105.0), "Bridge art does not match collision width")
	assert(level.get_node("Enemies").get_child_count() > 3, "Wizard spell expired before gate check")
	for enemy in level.get_node("Enemies").get_children():
		if enemy.is_in_group("enemies") and not enemy.defeated:
			enemy.solved = true
			while not enemy.defeated:
				enemy.hit_cooldown = 0.0
				enemy.take_hit(1)
	level.get_node("Rune").resolve_answer()
	knight.global_position = Vector2(1540, 100)
	await physics_frame
	await physics_frame
	assert(level.stage == 1, "Active spell blocked the level transition")
	var music: AudioStreamPlayer = root.get_node("BackgroundMusic")
	for attempt in range(5):
		if music.playing:
			break
		await process_frame
	assert(music.playing, "Background music stopped during gameplay")
	assert(music.process_mode == Node.PROCESS_MODE_ALWAYS, "Background music must run while paused")
	paused = true
	await process_frame
	assert(music.playing, "Background music stopped during pause")
	paused = false
	level.queue_free()
	await process_frame
	print("PASS: spell counting, enemy recovery, directional sword, dialog cancel, death bounce, bridge art")
	quit(0)
