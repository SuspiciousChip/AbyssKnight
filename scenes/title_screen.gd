extends Control

const FIGMA_ART = preload("res://scripts/figma_art.gd")


func _ready() -> void:
	var sky: Texture2D = FIGMA_ART.named_texture("parallax/l0_sky_moon")
	if sky != null:
		$Background.texture = sky
	$Start.grab_focus()


func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/test_level.tscn")
