extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var title: Control = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	for index in range(4):
		await process_frame
	save_screen("title.png")
	root.remove_child(title)
	title.queue_free()
	var level: Node2D = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	for index in range(12):
		await process_frame
	save_screen("level_1.png")
	level.get_node("Knight").global_position = Vector2(1190, 100)
	for index in range(12):
		await process_frame
	save_screen("level_1_shadow.png")
	var enemy: Node2D = level.get_node("Enemies").get_child(0)
	level.get_node("MathUI").open_for(enemy)
	for index in range(4):
		await process_frame
	save_screen("math_dialog.png")
	quit(0)


func save_screen(filename: String) -> void:
	var image: Image = root.get_texture().get_image()
	var destination := "res://screenshots/" + filename
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	var error := image.save_png(ProjectSettings.globalize_path(destination))
	print("Screenshot: ", destination, " error=", error, " size=", image.get_size())
