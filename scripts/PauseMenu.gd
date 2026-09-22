extends CanvasLayer
## Pausa o jogo de verdade (get_tree().paused) ao apertar Esc, com opções
## de continuar, reiniciar ou voltar ao menu. Continua processando entrada
## mesmo com a árvore pausada (process_mode = ALWAYS).

@onready var panel: Control = $Panel
@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

var _paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	GameState.game_over.connect(_on_game_over)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and GameState.health > 0:
		if _paused:
			_resume()
		else:
			_pause()

func _pause() -> void:
	_paused = true
	get_tree().paused = true
	panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_release_touch_actions()

## Com a árvore pausada o TouchControls para de processar, então um dedo
## que estava segurando o analógico/botão deixaria a ação presa.
func _release_touch_actions() -> void:
	var touch := get_tree().get_first_node_in_group("touch_controls")
	if touch and touch.has_method("release_all"):
		touch.release_all()

func _resume() -> void:
	_paused = false
	get_tree().paused = false
	panel.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_pressed() -> void:
	Audio.play("click")
	_resume()

func _on_restart_pressed() -> void:
	Audio.play("click")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	Audio.play("click")
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameState.flush_save()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _on_game_over() -> void:
	# Se o jogador morreu enquanto pausado, some com o menu de pausa —
	# a tela de fim de jogo do HUD assume.
	if _paused:
		_paused = false
		get_tree().paused = false
		panel.hide()
