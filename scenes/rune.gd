extends Node2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")

var answer: int = 0
var solved: bool = false

func _ready() -> void:
	var image: Texture2D = FIGMA_ART.named_texture("tiles/rune_crack")
	if image != null:
		var picture := Sprite2D.new()
		picture.texture = image
		picture.scale = Vector2(1.5, 1.5)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(picture)
		$Appearance.hide()
	var question: Dictionary = get_node("/root/EquationManager").next_question()
	answer = question["answer"]
	$EquationLabel.text = question["text"]

func resolve_answer() -> void:
	solved = true
	$EquationLabel.text = ""
	$NameLabel.text = "Rune awakened"
	$Appearance.color = Color(0.25, 0.9, 0.7, 1)
