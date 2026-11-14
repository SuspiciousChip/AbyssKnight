extends CharacterBody2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")

@export var move_speed: float = 220.0
@export var jump_speed: float = -420.0
@export var gravity: float = 1000.0

@onready var sword_area: Area2D = $SwordArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var animated: AnimatedSprite2D = $Sprite2D/AnimatedSprite2D
var facing: int = 1
var attack_ready: bool = true
var health: int = 3
var max_health: int = 3
var damage_cooldown: float = 0.0
var walk_time: float = 0.0
var potion_charges: int = 1
var max_potions: int = 2
var dead: bool = false
var hurt_time: float = 0.0


func _ready() -> void:
	var frames: SpriteFrames = FIGMA_ART.character_frames("knight")
	if frames != null:
		animated.sprite_frames = frames
		animated.visible = true
		animated.position.y = -2.0
		sprite.texture = null
		sprite.scale = Vector2.ONE
		animated.play("idle")


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y += gravity * delta
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		move_and_slide()
		return
	if global_position.y > 500.0:
		global_position = Vector2(0.0, 100.0)
		velocity = Vector2.ZERO
		take_damage(1)
	if damage_cooldown > 0.0:
		damage_cooldown -= delta
	if hurt_time > 0.0:
		hurt_time -= delta
	# Pull the knight down while in the air.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Move left or right using Godot's default arrow-key actions.
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * move_speed
	if direction != 0.0:
		facing = 1 if direction > 0.0 else -1
		sword_area.position.x = 25.0 * facing
		sprite.scale.x = abs(sprite.scale.x) * facing
		walk_time += delta * 12.0
		sprite.position.y = -2.0 + sin(walk_time) * 1.5
	else:
		sprite.position.y = move_toward(sprite.position.y, -2.0, 12.0 * delta)

	# Jump only while standing on a floor.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed

	move_and_slide()
	if animated.visible and attack_ready and hurt_time <= 0.0:
		var animation := "run" if direction != 0.0 and is_on_floor() and animated.sprite_frames.has_animation("run") else "idle"
		if animated.animation != animation:
			animated.play(animation)

	if Input.is_action_just_pressed("attack") and attack_ready:
		attack()
	if Input.is_action_just_pressed("potion"):
		use_potion()

	if Input.is_action_just_pressed("solve"):
		var target: Node2D = get_math_target()
		if target != null:
			get_parent().get_node("MathUI").open_for(target)


func get_math_target() -> Node2D:
	var rune: Node2D = get_parent().get_node_or_null("Rune")
	if rune != null and not rune.solved and global_position.distance_to(rune.global_position) < 85.0:
		return rune
	var nearest_enemy: Node2D = null
	var nearest_distance: float = 100.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.solved or enemy.defeated:
			continue
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	return nearest_enemy


func use_potion() -> bool:
	if dead or potion_charges <= 0 or health >= max_health:
		return false
	potion_charges -= 1
	health += 1
	$HealthLabel.text = "HP: %d" % health
	var health_bar: ProgressBar = get_parent().get_node_or_null("HUD/HealthBar")
	if health_bar != null:
		health_bar.value = health
	if get_parent().has_method("update_art_hud"):
		get_parent().update_art_hud()
	return true


func attack() -> void:
	attack_ready = false
	if animated.visible and animated.sprite_frames.has_animation("attack"):
		animated.play("attack")
	var slash_texture: Texture2D = FIGMA_ART.named_texture("fx/slash")
	if slash_texture != null:
		var slash := Sprite2D.new()
		slash.texture = slash_texture
		slash.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		slash.position = Vector2(facing * 29.0, -5.0)
		slash.flip_h = facing < 0
		add_child(slash)
		get_tree().create_timer(0.12).timeout.connect(slash.queue_free)
	sprite.rotation = -0.16 * facing
	create_tween().tween_property(sprite, "rotation", 0.0, 0.22)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.defeated:
			continue
		var horizontal: float = (enemy.global_position.x - global_position.x) * facing
		if horizontal > 0.0 and horizontal <= 52.0 and abs(enemy.global_position.y - global_position.y) <= 26.0:
			enemy.take_hit(facing)
	await get_tree().create_timer(0.4).timeout
	if dead:
		return
	attack_ready = true
	if animated.visible:
		animated.play("idle")


func take_damage(amount: int) -> void:
	if dead or damage_cooldown > 0.0:
		return
	health = max(0, health - amount)
	$HealthLabel.text = "HP: %d" % health
	var health_bar: ProgressBar = get_parent().get_node_or_null("HUD/HealthBar")
	if health_bar != null:
		health_bar.max_value = max_health
		health_bar.value = health
	if get_parent().has_method("update_art_hud"):
		get_parent().update_art_hud()
	if health <= 0:
		start_death()
		return
	damage_cooldown = 1.0
	hurt_time = 0.1
	if animated.visible and animated.sprite_frames.has_animation("hurt"):
		animated.play("hurt")
	sprite.modulate = Color(1.0, 0.45, 0.65)
	var flicker := create_tween()
	for index in range(4):
		flicker.tween_property(sprite, "modulate:a", 0.35, 0.1)
		flicker.tween_property(sprite, "modulate:a", 1.0, 0.1)
	flicker.tween_property(sprite, "modulate", Color.WHITE, 0.01)


func start_death() -> void:
	dead = true
	attack_ready = false
	velocity = Vector2(-facing * 170.0, -300.0)
	if animated.visible and animated.sprite_frames.has_animation("death"):
		animated.play("death")
	var death_tween := create_tween().set_parallel(true)
	death_tween.tween_property(sprite, "rotation", -PI / 2.0, 0.6)
	death_tween.tween_property(sprite, "modulate:a", 0.4, 0.6)
	await get_tree().create_timer(0.65).timeout
	if is_inside_tree() and dead:
		get_parent().show_retry_ui()


func bounce_back() -> void:
	dead = false
	attack_ready = true
	hurt_time = 0.0
	health = max_health
	damage_cooldown = 1.0
	global_position = Vector2(0.0, 100.0)
	velocity = Vector2.ZERO
	sprite.rotation = 0.0
	sprite.modulate = Color.WHITE
	sprite.position.y = -2.0
	if animated.visible:
		animated.play("idle")
	$HealthLabel.text = "HP: %d" % health
	var health_bar: ProgressBar = get_parent().get_node_or_null("HUD/HealthBar")
	if health_bar != null:
		health_bar.value = health
	if get_parent().has_method("update_art_hud"):
		get_parent().update_art_hud()
