extends CharacterBody2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")

@export_enum("skeleton", "wizard", "shadow") var enemy_kind: String = "skeleton"
const SPELL_SCENE: PackedScene = preload("res://scenes/spell.tscn")

var answer: int = 0
var solved: bool = false
var hits_remaining: int = 0
var defeated: bool = false
var hit_cooldown: float = 0.0
var gravity: float = 1000.0
var action_timer: float = 1.5
var home_x: float = 0.0
var patrol_direction: int = 1
var float_time: float = 0.0
@onready var appearance: Sprite2D = $Appearance
@onready var animated: AnimatedSprite2D = $Appearance/AnimatedSprite2D


func _ready() -> void:
	var frames: SpriteFrames = FIGMA_ART.character_frames(enemy_kind)
	if frames != null:
		animated.sprite_frames = frames
		animated.visible = true
		appearance.texture = null
		appearance.scale = Vector2.ONE
		animated.play("idle")
	home_x = global_position.x
	var question: Dictionary = get_node("/root/EquationManager").next_question()
	if question.is_empty():
		$EquationLabel.text = "No question left"
		return

	answer = question["answer"]
	hits_remaining = answer
	$EquationLabel.text = question["text"]


func _physics_process(delta: float) -> void:
	if not defeated:
		float_time += delta * 6.0
		if enemy_kind == "shadow":
			appearance.position.y = sin(float_time) * 3.0
	velocity.y += gravity * delta
	var knight: Node2D = get_tree().get_first_node_in_group("player")
	var distance: float = INF
	if knight != null:
		distance = global_position.distance_to(knight.global_position)
	if not defeated:
		if knight != null:
			if enemy_kind == "skeleton" and distance < 26.0:
				knight.take_damage(1)
			if enemy_kind == "shadow" and distance < 180.0 and hit_cooldown <= 0.0:
				velocity.x = sign(knight.global_position.x - global_position.x) * 65.0
				if distance < 27.0:
					knight.take_damage(1)
			elif enemy_kind == "wizard" and distance < 320.0:
				action_timer -= delta
				if action_timer <= 0.0:
					cast_spell(knight)
					action_timer = 2.5
	if hit_cooldown > 0.0:
		hit_cooldown -= delta
	elif enemy_kind == "skeleton" and not defeated:
		if global_position.x > home_x + 25.0:
			patrol_direction = -1
		elif global_position.x < home_x - 25.0:
			patrol_direction = 1
		velocity.x = patrol_direction * 25.0
	elif enemy_kind != "shadow" or defeated or knight == null or distance >= 180.0:
		velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	move_and_slide()
	if not defeated and abs(velocity.x) > 1.0:
		appearance.scale.x = -abs(appearance.scale.x) if velocity.x < 0.0 else abs(appearance.scale.x)
	if defeated and global_position.y > 500.0:
		queue_free()


func take_hit(direction: int) -> void:
	if not solved or defeated or hit_cooldown > 0.0:
		return
	hits_remaining -= 1
	if animated.visible and animated.sprite_frames.has_animation("hurt"):
		animated.play("hurt")
	appearance.modulate = Color(1.0, 0.45, 0.8)
	create_tween().tween_property(appearance, "modulate", Color.WHITE, 0.25)
	velocity.x = direction * 120.0
	velocity.y = -100.0
	hit_cooldown = 0.2
	if hits_remaining > 0:
		$EquationLabel.text = "Hits left: %d" % hits_remaining
	else:
		defeated = true
		$EquationLabel.text = ""
		$NameLabel.text = ""
		velocity.x = direction * 180.0
		velocity.y = -180.0
		collision_layer = 0
		collision_mask = 0
		var death_tween := create_tween()
		death_tween.set_parallel(true)
		death_tween.tween_property(appearance, "rotation", -PI / 2.0, 0.45)
		death_tween.tween_property(appearance, "modulate:a", 0.4, 0.45)


func cast_spell(knight: Node2D) -> void:
	if animated.visible and animated.sprite_frames.has_animation("cast"):
		animated.play("cast")
	var spell: Area2D = SPELL_SCENE.instantiate()
	var cast_direction: int = 1 if knight.global_position.x > global_position.x else -1
	get_parent().add_child(spell)
	spell.global_position = global_position + Vector2(cast_direction * 22.0, -5.0)
	spell.direction = cast_direction
