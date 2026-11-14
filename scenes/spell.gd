extends Area2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")

var direction: int = -1
var speed: float = 150.0
var lifetime: float = 3.0


func _ready() -> void:
	var image: Texture2D = FIGMA_ART.named_texture("fx/purple_orb")
	if image != null:
		var picture := Sprite2D.new()
		picture.texture = image
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(picture)
		$Appearance.hide()

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
		queue_free()
