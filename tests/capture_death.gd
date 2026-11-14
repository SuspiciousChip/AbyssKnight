extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	var level: Node2D = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	var knight: CharacterBody2D = level.get_node("Knight")
	knight.health = 1
	knight.take_damage(1)
	await create_timer(0.28).timeout
	save_screen("death_bounce.png")
	await create_timer(0.48).timeout
	save_screen("bounce_back_window.png")
	quit(0)


func save_screen(filename: String) -> void:
	var image: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://screenshots"))
	var path := ProjectSettings.globalize_path("res://screenshots/" + filename)
	print("Screenshot: ", path, " error=", image.save_png(path))
