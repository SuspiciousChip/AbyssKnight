extends CanvasLayer

const FIGMA_ART = preload("res://scripts/figma_art.gd")

@onready var question_label: Label = $Center/Panel/VBox/Question
@onready var answer_input: LineEdit = $Center/Panel/VBox/InputRow/Answer
@onready var message_label: Label = $Center/Panel/VBox/Message

var current_enemy: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.075, 0.045, 0.14, 0.98)
	panel_style.border_color = Color(0.52, 0.34, 0.77)
	panel_style.set_border_width_all(4)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(26)
	$Center/Panel.add_theme_stylebox_override("panel", panel_style)
	var rune: Texture2D = FIGMA_ART.named_texture("tiles/rune_crack")
	if rune != null:
		$Center/Panel/VBox/Header/RuneIcon.texture = rune
	$Dim.hide()
	$Center.hide()


func _input(event: InputEvent) -> void:
	if $Center.visible and event.is_action_pressed("ui_cancel"):
		$Center.hide()
		$Dim.hide()
		current_enemy = null
		get_tree().paused = false
		get_viewport().set_input_as_handled()

func open_for(enemy: Node2D) -> void:
	if enemy.solved:
		return
	current_enemy = enemy
	var topic: String = str(get_node("/root/EquationManager").topic)
	$Center/Panel/VBox/Header/Heading.text = "∑  %s" % topic.to_upper()
	match topic:
		"arithmetic":
			$Center/Panel/VBox/Prompt.text = "Add the numbers. The result becomes the number of hits."
			$Center/Panel/VBox/InputRow/XLabel.text = "= "
		"geometry":
			$Center/Panel/VBox/Prompt.text = "Find the rectangle width. It becomes the number of hits."
			$Center/Panel/VBox/InputRow/XLabel.text = "w ="
		_:
			$Center/Panel/VBox/Prompt.text = "Find x. Your answer becomes the number of hits."
			$Center/Panel/VBox/InputRow/XLabel.text = "x ="
	question_label.text = enemy.get_node("EquationLabel").text
	answer_input.text = ""
	message_label.text = ""
	$Dim.show()
	$Center.show()
	get_tree().paused = true
	answer_input.grab_focus()

func submit_answer() -> void:
	if not answer_input.text.is_valid_int():
		message_label.text = "Enter a whole number."
		return
	if answer_input.text.to_int() == current_enemy.answer:
		if current_enemy.has_method("resolve_answer"):
			current_enemy.resolve_answer()
		else:
			current_enemy.solved = true
			current_enemy.get_node("EquationLabel").text = "Hits left: %d" % current_enemy.hits_remaining
		if get_parent().has_method("reward_math_solve"):
			get_parent().reward_math_solve()
		$Center.hide()
		$Dim.hide()
		get_tree().paused = false
	else:
		message_label.text = "Try again."
		answer_input.select_all()

func _on_submit_pressed() -> void:
	submit_answer()

func _on_answer_text_submitted(_text: String) -> void:
	submit_answer()
