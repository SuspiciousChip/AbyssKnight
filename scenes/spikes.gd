extends Area2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")


func _ready() -> void:
	var image: Texture2D = FIGMA_ART.named_texture("tiles/spikes")
	if image != null:
		for x in [-32, 0, 32]:
			var picture := Sprite2D.new()
			picture.texture = image
			picture.position.x = x
			picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(picture)
		$Appearance.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.global_position = Vector2(0.0, 100.0)
		body.velocity = Vector2.ZERO
		body.take_damage(1)
