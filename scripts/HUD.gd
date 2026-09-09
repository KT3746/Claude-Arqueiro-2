extends CanvasLayer
## HUD do jogo: pontuação, vida, onda, combo, indicador de força do arco,
## mira e tela de fim de jogo. Escuta os sinais do GameState (autoload).

@onready var score_label: Label = $Margin/ScoreLabel
@onready var wave_label: Label = $Margin/WaveLabel
@onready var combo_label: Label = $Margin/ComboLabel
@onready var health_bar: ProgressBar = $Margin/HealthBar
@onready var draw_bar: ProgressBar = $Margin/DrawBar
@onready var crosshair: Control = $Crosshair
@onready var game_over_panel: Control = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/Center/Box/FinalScoreLabel
@onready var accuracy_label: Label = $GameOverPanel/Center/Box/AccuracyLabel
@onready var restart_button: Button = $GameOverPanel/Center/Box/RestartButton
@onready var wave_banner: Label = $Margin/WaveBanner

var player: Node = null
var _banner_timer: float = 0.0

func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)

	player = get_tree().get_first_node_in_group("player")

	_on_score_changed(GameState.score)
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_on_wave_changed(GameState.current_wave)
	_on_combo_changed(GameState.combo)
	game_over_panel.hide()
	draw_bar.hide()
	wave_banner.hide()

func _process(delta: float) -> void:
	if is_instance_valid(player):
		var t: float = 0.0
		if player.is_drawing:
			t = clamp(player.draw_time / player.max_draw_time, 0.0, 1.0)
		draw_bar.value = t * 100.0
		draw_bar.visible = player.is_drawing
		crosshair.set_state(t, player.is_aiming)

	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			wave_banner.hide()

func _on_score_changed(s: int) -> void:
	score_label.text = "Pontos: %d" % s

func _on_health_changed(h: int, max_h: int) -> void:
	health_bar.max_value = max_h
	health_bar.value = h

func _on_wave_changed(w: int) -> void:
	if w <= 0:
		wave_label.hide()
		return
	wave_label.show()
	wave_label.text = "Onda %d" % w
	wave_banner.text = "Onda %d" % w
	wave_banner.show()
	_banner_timer = 2.0

func _on_combo_changed(c: int) -> void:
	if c > 1:
		combo_label.show()
		combo_label.text = "Combo x%d" % c
	else:
		combo_label.hide()

func _on_game_over() -> void:
	final_score_label.text = "Pontuação final: %d" % GameState.score
	accuracy_label.text = "Precisão: %.0f%%" % GameState.get_accuracy()
	game_over_panel.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_restart_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()
