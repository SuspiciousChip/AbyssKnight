extends Area2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")


func _ready() -> void:
	var image: Texture2D = FIGMA_ART.named_texture("props/crystal")
	if image != null:
		var picture := Sprite2D.new()
		picture.texture = image
		picture.scale = Vector2(2, 2)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(picture)
		$Appearance.hide()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		get_parent().get_parent().collect_shard(self)
