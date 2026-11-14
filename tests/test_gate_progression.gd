extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var level: Node2D = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	for expected_stage in range(3):
		assert(level.stage == expected_stage)
		level.get_node("Knight").global_position = Vector2(1540, 100)
		await physics_frame
		assert(level.stage == expected_stage, "Gate advanced before puzzle was complete")
		var enemies: Array[Node] = level.get_node("Enemies").get_children()
		for index in range(enemies.size() - 1):
			enemies[index].defeated = true
		await physics_frame
		assert(level.stage == expected_stage, "Gate advanced before rune was solved")
		level.get_node("Rune").resolve_answer()
		await physics_frame
		assert(level.stage == expected_stage, "One remaining enemy should keep gate closed")
		assert(level.get_node("GateStatus").text.contains("1 enemy left"))
		enemies.back().defeated = true
		await physics_frame
		assert(level.stage == expected_stage + 1, "Entering the open gate did not advance")
	assert(level.finished, "Final gate did not complete the game")
	print("PASS: walking into each solved gate advances all three stages")
	quit(0)
