extends AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var soundtrack := (preload("res://assets/audio/abyss_theme.wav") as AudioStreamWAV).duplicate() as AudioStreamWAV
	soundtrack.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream = soundtrack
	volume_db = -18.0
	ensure_playing.call_deferred()


func ensure_playing() -> void:
	if not playing:
		play()


func _process(_delta: float) -> void:
	ensure_playing()
