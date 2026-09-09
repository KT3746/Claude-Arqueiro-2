extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%TrainingButton.pressed.connect(_on_training_pressed)
	%WaveButton.pressed.connect(_on_wave_pressed)
	%QuitButton.pressed.connect(_on_quit_pressed)
	%TrainingButton.grab_focus()

func _on_training_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/TrainingRange.tscn")

func _on_wave_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/WaveArena.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
