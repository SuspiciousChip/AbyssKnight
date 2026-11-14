extends Node2D

const FIGMA_ART = preload("res://scripts/figma_art.gd")

const SKELETON: PackedScene = preload("res://scenes/skeleton.tscn")
const WIZARD: PackedScene = preload("res://scenes/wizard.tscn")
const SHADOW: PackedScene = preload("res://scenes/shadow.tscn")
const RUNE: PackedScene = preload("res://scenes/rune.tscn")
const SHARD: PackedScene = preload("res://scenes/shard.tscn")
const SPIKES: PackedScene = preload("res://scenes/spikes.tscn")
const TOPICS: Array[String] = ["arithmetic", "algebra", "geometry"]
const ATLAS: Texture2D = preload("res://art/abyss_atlas_concept.png")

# Counts vary: 3, 5, then 4. Positions avoid the gaps in each stage.
const WAVES: Array = [
	[[SKELETON, 140.0], [WIZARD, 540.0], [SHADOW, 1250.0]],
	[[SKELETON, 130.0], [SHADOW, 490.0], [SKELETON, 580.0], [WIZARD, 920.0], [SHADOW, 1300.0]],
	[[SHADOW, 160.0], [WIZARD, 540.0], [SKELETON, 940.0], [WIZARD, 1280.0]]
]
const FLOORS: Array = [
	[[80.0, 400.0], [480.0, 260.0], [860.0, 300.0], [1325.0, 550.0]],
	[[70.0, 380.0], [490.0, 300.0], [890.0, 320.0], [1365.0, 470.0]],
	[[60.0, 360.0], [480.0, 280.0], [870.0, 260.0], [1360.0, 480.0]]
]
const BRIDGES: Array = [
	[315.0, 660.0, 1030.0],
	[300.0, 685.0, 1090.0],
	[290.0, 680.0, 1060.0]
]
const GATE_ENTRY_X: float = 1535.0

var stage: int = 0
var gate_open: bool = false
var finished: bool = false
var shards_collected: int = 0
var shard_bonus_awarded: bool = false


func _enter_tree() -> void:
	get_node("/root/EquationManager").topic = TOPICS[0]


func _ready() -> void:
	$RetryUI.process_mode = Node.PROCESS_MODE_ALWAYS
	setup_parallax()
	setup_art_hud()
	build_stage()


func show_retry_ui() -> void:
	$RetryUI.show()
	get_tree().paused = true
	$RetryUI/Center/Panel/VBox/BounceBackButton.grab_focus()


func bounce_back_to_game() -> void:
	get_tree().paused = false
	$RetryUI.hide()
	$Knight.bounce_back()


func _process(_delta: float) -> void:
	var sword_slot: TextureRect = $HUD.get_node_or_null("SwordSlot")
	if sword_slot != null:
		sword_slot.modulate = Color.WHITE if $Knight.attack_ready else Color(0.55, 0.55, 0.6)
	var crystal_slot: TextureRect = $HUD.get_node_or_null("CrystalSlot")
	if crystal_slot != null:
		crystal_slot.modulate = Color.WHITE if $Knight.get_math_target() != null else Color(0.55, 0.55, 0.6)


func reward_math_solve() -> void:
	$Knight.potion_charges = min($Knight.potion_charges + 1, $Knight.max_potions)
	update_art_hud()


func setup_art_hud() -> void:
	var hud: CanvasLayer = $HUD
	var bottom: float = get_viewport().get_visible_rect().size.y
	var backdrop := ColorRect.new()
	backdrop.name = "HUDBackdrop"
	backdrop.position = Vector2(0, bottom - 150)
	backdrop.size = Vector2(790, 150)
	backdrop.color = Color(0.055, 0.035, 0.1, 0.78)
	hud.add_child(backdrop)
	hud.move_child(backdrop, 0)
	var math_font := SystemFont.new()
	math_font.font_names = PackedStringArray(["Menlo", "DejaVu Sans Mono", "Monospace"])
	for text_node in [$HUD/Stage, $HUD/Quest, $HUD/Hint]:
		text_node.add_theme_font_override("font", math_font)
	$HUD/Stage.add_theme_color_override("font_color", Color(1.0, 0.88, 0.59))
	$HUD/Quest.add_theme_color_override("font_color", Color(0.8, 0.68, 1.0))
	$HUD/Hint.add_theme_color_override("font_color", Color(0.66, 0.89, 0.96))
	$HUD/Stage.add_theme_font_size_override("font_size", 18)
	$HUD/Quest.add_theme_font_size_override("font_size", 14)
	$HUD/Hint.add_theme_font_size_override("font_size", 12)
	var portrait: Texture2D = FIGMA_ART.named_texture("ui/portrait")
	if portrait == null:
		return
	var picture := TextureRect.new()
	picture.name = "PortraitArt"
	picture.texture = portrait
	picture.position = Vector2(16, bottom - 88)
	picture.scale = Vector2(0.65, 0.65)
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hud.add_child(picture)
	$HUD/Stage.position = Vector2(110, bottom - 141)
	$HUD/Quest.position = Vector2(110, bottom - 117)
	$HUD/Hint.position = Vector2(110, bottom - 96)
	$HUD/HealthBar.hide()
	var health_texture: Texture2D = FIGMA_ART.named_texture("ui/health_bar")
	if health_texture != null:
		var art_bar := TextureProgressBar.new()
		art_bar.name = "ArtHealthBar"
		art_bar.texture_progress = health_texture
		art_bar.position = Vector2(110, bottom - 68)
		art_bar.scale = Vector2(0.6, 0.6)
		art_bar.max_value = $Knight.max_health
		art_bar.value = $Knight.health
		art_bar.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hud.add_child(art_bar)
	for index in range($Knight.max_health):
		var heart_texture: Texture2D = FIGMA_ART.named_texture("ui/heart_full")
		if heart_texture != null:
			var heart := TextureRect.new()
			heart.name = "Heart%d" % index
			heart.texture = heart_texture
			heart.position = Vector2(110 + index * 22, bottom - 49)
			heart.scale = Vector2(0.6, 0.6)
			heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			hud.add_child(heart)
	var slots := ["slot_sword", "slot_potion", "slot_crystal"]
	for index in range(slots.size()):
		var slot_texture: Texture2D = FIGMA_ART.named_texture("ui/" + slots[index])
		if slot_texture == null:
			continue
		var slot := TextureRect.new()
		slot.name = ["SwordSlot", "PotionSlot", "CrystalSlot"][index]
		slot.texture = slot_texture
		slot.position = Vector2(980 + index * 88, bottom - 100)
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hud.add_child(slot)
		var key := Label.new()
		key.text = ["J", "Q", "E"][index]
		key.position = slot.position + Vector2(34, 48)
		hud.add_child(key)
		if index == 1:
			var charges := Label.new()
			charges.name = "PotionCount"
			charges.position = slot.position + Vector2(54, 4)
			charges.add_theme_font_override("font", math_font)
			charges.add_theme_color_override("font_color", Color(1.0, 0.88, 0.59))
			charges.add_theme_font_size_override("font_size", 17)
			hud.add_child(charges)
	var counter_texture: Texture2D = FIGMA_ART.named_texture("ui/counter")
	if counter_texture != null:
		var counter := TextureRect.new()
		counter.texture = counter_texture
		counter.position = Vector2(1100, bottom - 170)
		counter.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hud.add_child(counter)
		var number_back := ColorRect.new()
		number_back.position = Vector2(1150, bottom - 158)
		number_back.size = Vector2(82, 31)
		number_back.color = Color(0.09, 0.05, 0.16)
		hud.add_child(number_back)
		var count := Label.new()
		count.name = "ShardCount"
		count.position = Vector2(1155, bottom - 155)
		count.text = "0"
		count.add_theme_font_override("font", math_font)
		count.add_theme_color_override("font_color", Color(1.0, 0.88, 0.59))
		hud.add_child(count)
	var mana_texture: Texture2D = FIGMA_ART.named_texture("ui/mana_bar")
	if mana_texture != null:
		var mana := TextureProgressBar.new()
		mana.name = "PotionEnergyBar"
		mana.texture_progress = mana_texture
		mana.position = Vector2(110, bottom - 25)
		mana.scale = Vector2(0.6, 0.6)
		mana.max_value = $Knight.max_potions
		mana.value = $Knight.potion_charges
		mana.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hud.add_child(mana)
	update_art_hud()


func update_art_hud() -> void:
	var bar: TextureProgressBar = $HUD.get_node_or_null("ArtHealthBar")
	if bar != null:
		bar.max_value = $Knight.max_health
		bar.value = $Knight.health
	var energy: TextureProgressBar = $HUD.get_node_or_null("PotionEnergyBar")
	if energy != null:
		energy.max_value = $Knight.max_potions
		energy.value = $Knight.potion_charges
	var charges: Label = $HUD.get_node_or_null("PotionCount")
	if charges != null:
		charges.text = str($Knight.potion_charges)
	var potion_slot: TextureRect = $HUD.get_node_or_null("PotionSlot")
	if potion_slot != null:
		potion_slot.modulate = Color.WHITE if $Knight.potion_charges > 0 else Color(0.45, 0.45, 0.5)
	var full: Texture2D = FIGMA_ART.named_texture("ui/heart_full")
	var empty: Texture2D = FIGMA_ART.named_texture("ui/heart_empty")
	for index in range($Knight.max_health):
		var heart: TextureRect = $HUD.get_node_or_null("Heart%d" % index)
		if heart == null and full != null:
			heart = TextureRect.new()
			heart.name = "Heart%d" % index
			heart.position = Vector2(110 + index * 22, get_viewport().get_visible_rect().size.y - 49)
			heart.scale = Vector2(0.6, 0.6)
			heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			$HUD.add_child(heart)
		if heart != null:
			heart.texture = full if index < $Knight.health else empty
	var count: Label = $HUD.get_node_or_null("ShardCount")
	if count != null:
		count.text = str(shards_collected)


func setup_parallax() -> void:
	var names := ["l0_sky_moon", "l1_far_mountains", "l2_haunted_castle", "l3_mid_ruins_trees"]
	var factors := [0.05, 0.15, 0.3, 0.6]
	var textures: Array[Texture2D] = []
	for name in names:
		var image: Texture2D = FIGMA_ART.named_texture("parallax/" + name)
		if image == null:
			return
		textures.append(image)
	$AbyssArt.hide()
	$DistantRuins.hide()
	$AbyssBackdrop.hide()
	var background := ParallaxBackground.new()
	background.layer = -10
	background.name = "FigmaParallax"
	add_child(background)
	for index in range(names.size()):
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(factors[index], factors[index])
		layer.motion_mirroring = Vector2(1280, 0)
		var picture := Sprite2D.new()
		picture.texture = textures[index]
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		picture.scale = Vector2(2, 2)
		picture.position = Vector2(640, 360)
		layer.add_child(picture)
		background.add_child(layer)
	var glow: Texture2D = FIGMA_ART.named_texture("parallax/l5_lighting_glow")
	if glow != null:
		var overlay := CanvasLayer.new()
		overlay.name = "FigmaGlow"
		overlay.layer = -1
		var picture := Sprite2D.new()
		picture.texture = glow
		picture.position = Vector2(640, 360)
		picture.scale = Vector2(2, 2)
		picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var material := CanvasItemMaterial.new()
		material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		picture.material = material
		overlay.add_child(picture)
		add_child(overlay)


func _physics_process(_delta: float) -> void:
	if finished:
		if Input.is_action_just_pressed("ui_accept"):
			get_node("/root/EquationManager").reset_questions()
			get_tree().reload_current_scene()
		return
	if not gate_open:
		var enemies_remaining := 0
		for enemy in $Enemies.get_children():
			if enemy.is_in_group("enemies") and not enemy.defeated:
				enemies_remaining += 1
		if enemies_remaining == 0 and $Rune.solved:
			gate_open = true
			$Gate.color = Color(0.25, 0.9, 0.7, 0.8)
			$HUD/Hint.text = "Gate open! Enter the glowing gate on the right."
			$GateStatus.text = "ENTER GATE →"
			$GateStatus.add_theme_color_override("font_color", Color(0.55, 1.0, 0.75))
		elif enemies_remaining == 0:
			$HUD/Hint.text = "Enemies cleared. Solve the rune near the gate with E."
			$GateStatus.text = "Solve rune with E"
		else:
			var noun := "enemy" if enemies_remaining == 1 else "enemies"
			$HUD/Hint.text = "Defeat %d %s, then solve the rune." % [enemies_remaining, noun]
			$GateStatus.text = "← %d %s left" % [enemies_remaining, noun]
	if gate_open and $Knight.global_position.x >= GATE_ENTRY_X:
		advance_stage()


func build_stage() -> void:
	get_node("/root/EquationManager").topic = TOPICS[stage]
	gate_open = false
	$Gate.color = Color(0.9, 0.2, 0.4, 0.85)
	$GateStatus.text = "Defeat enemies to open gate"
	$GateStatus.add_theme_color_override("font_color", Color(1.0, 0.82, 0.9))
	clear_container($Terrain)
	clear_container($Props)
	clear_container($Enemies)
	clear_container($Collectibles)
	clear_container($Hazards)
	for segment in FLOORS[stage]:
		add_platform(segment[0], segment[1], 150.0, Color(0.18, 0.12, 0.28))
	for bridge_x in BRIDGES[stage]:
		add_platform(bridge_x, 105.0, 80.0, Color(0.28, 0.2, 0.4))
		var spikes: Area2D = SPIKES.instantiate()
		spikes.position = Vector2(bridge_x, 240.0)
		$Hazards.add_child(spikes)
	add_prop("gravestone", Vector2(220, 110), Vector2(2, 2))
	add_prop("lantern", Vector2(910, 118), Vector2(2, 2))
	add_prop("dead_tree", Vector2(1380, 93), Vector2(1.5, 1.5))
	for entry in WAVES[stage]:
		var enemy: CharacterBody2D = entry[0].instantiate()
		enemy.position = Vector2(entry[1], 114.0)
		$Enemies.add_child(enemy)
	for old_rune in get_children():
		if old_rune.name.begins_with("Rune"):
			remove_child(old_rune)
			old_rune.queue_free()
	var rune: Node2D = RUNE.instantiate()
	rune.position = Vector2(1490.0, 105.0)
	add_child(rune)
	for shard_x in BRIDGES[stage]:
		var shard: Area2D = SHARD.instantiate()
		shard.position = Vector2(shard_x, 40.0)
		$Collectibles.add_child(shard)
	$Knight.global_position = Vector2(0.0, 100.0)
	$Knight.velocity = Vector2.ZERO
	$Knight.health = $Knight.max_health
	$Knight.damage_cooldown = 0.0
	$Knight.get_node("HealthLabel").text = "HP: %d" % $Knight.health
	$HUD/HealthBar.max_value = $Knight.max_health
	$HUD/HealthBar.value = $Knight.health
	update_hud()


func clear_container(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func add_prop(name: String, location: Vector2, size: Vector2) -> void:
	var image: Texture2D = FIGMA_ART.named_texture("props/" + name)
	if image == null:
		return
	var picture := Sprite2D.new()
	picture.texture = image
	picture.position = location
	picture.scale = size
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$Props.add_child(picture)


func add_platform(center_x: float, width: float, center_y: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = Vector2(center_x, center_y)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 32.0)
	collision.shape = shape
	body.add_child(collision)
	var appearance := Polygon2D.new()
	appearance.color = color
	appearance.polygon = PackedVector2Array([
		Vector2(-width / 2.0, -16.0), Vector2(width / 2.0, -16.0),
		Vector2(width / 2.0, 16.0), Vector2(-width / 2.0, 16.0)
	])
	body.add_child(appearance)
	var full_tiles: int = int(floor(width / 32.0))
	var last_width: float = width - full_tiles * 32.0
	var tile_texture: Texture2D = FIGMA_ART.named_texture("tiles/ground_top" if center_y == 150.0 else "tiles/floating_ledge")
	if tile_texture != null and tile_texture.get_size() == Vector2(32, 32):
		var tile_set := TileSet.new()
		tile_set.tile_size = Vector2i(32, 32)
		var source := TileSetAtlasSource.new()
		source.texture = tile_texture
		source.texture_region_size = Vector2i(32, 32)
		source.create_tile(Vector2i.ZERO)
		var source_id: int = tile_set.add_source(source)
		var map := TileMapLayer.new()
		map.tile_set = tile_set
		map.position = Vector2(-width / 2.0, -16.0)
		map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		for tile_index in range(full_tiles):
			map.set_cell(Vector2i(tile_index, 0), source_id, Vector2i.ZERO)
		body.add_child(map)
		if last_width > 0.0:
			add_tile_piece(body, tile_texture, Vector2(-width / 2.0 + full_tiles * 32.0, -16.0), last_width)
	elif tile_texture != null and tile_texture.get_width() == 32:
		for tile_index in range(full_tiles):
			add_tile_piece(body, tile_texture, Vector2(-width / 2.0 + tile_index * 32.0, -16.0), 32.0)
		if last_width > 0.0:
			add_tile_piece(body, tile_texture, Vector2(-width / 2.0 + full_tiles * 32.0, -16.0), last_width)
	else:
		for tile_index in range(full_tiles + int(last_width > 0.0)):
			var tile := Sprite2D.new()
			tile.texture = ATLAS
			tile.region_enabled = true
			var source_x: float = [16.0, 226.0, 296.0][stage]
			var piece_width: float = last_width if tile_index == full_tiles else 32.0
			tile.region_rect = Rect2(source_x, 35.0, piece_width * 2.0, 64.0)
			tile.scale = Vector2(0.5, 0.5)
			tile.centered = false
			tile.position = Vector2(-width / 2.0 + tile_index * 32.0, -16.0)
			tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			body.add_child(tile)
	$Terrain.add_child(body)


func add_tile_piece(body: StaticBody2D, texture: Texture2D, offset: Vector2, piece_width: float) -> void:
	var tile := Sprite2D.new()
	tile.texture = texture
	tile.region_enabled = true
	tile.region_rect = Rect2(0, 0, piece_width, texture.get_height())
	tile.centered = false
	tile.position = offset
	tile.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(tile)


func collect_shard(shard: Area2D) -> void:
	if shard.is_queued_for_deletion():
		return
	shards_collected += 1
	shard.queue_free()
	$Knight.health = min($Knight.health + 1, $Knight.max_health)
	if shards_collected >= 3 and not shard_bonus_awarded:
		shard_bonus_awarded = true
		$Knight.max_health += 1
		$Knight.health = $Knight.max_health
	$Knight.get_node("HealthLabel").text = "HP: %d" % $Knight.health
	$HUD/HealthBar.max_value = $Knight.max_health
	$HUD/HealthBar.value = $Knight.health
	update_hud()


func advance_stage() -> void:
	stage += 1
	if stage >= TOPICS.size():
		finished = true
		$HUD/Stage.text = "You cleared the abyss!"
		$HUD/Hint.text = "Press Enter to play again."
		$Knight.set_physics_process(false)
		return
	build_stage()


func update_hud() -> void:
	update_art_hud()
	$HUD/Stage.text = "Level %d/3 — %s" % [stage + 1, TOPICS[stage].capitalize()]
	if shard_bonus_awarded:
		$HUD/Quest.text = "Side quest complete: +1 maximum HP"
	else:
		$HUD/Quest.text = "Side quest: echo shards %d/3 (+1 maximum HP)" % shards_collected
	$HUD/Hint.text = "A/D move • Space jump • J attack • Q heal • E solve. Clear enemies and rune."
