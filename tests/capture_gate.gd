extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var level: Node2D = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	level.get_node("Knight").global_position = Vector2(1490, 100)
	for index in range(8):
		await process_frame
	level.get_node("Rune").resolve_answer()
	for index in range(8):
		await process_frame
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	var path := ProjectSettings.globalize_path("res://screenshots/gate_locked.png")
	print("Screenshot: ", path, " error=", image.save_png(path))
	quit(0)
