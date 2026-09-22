extends CanvasLayer
## HUD do jogo: pontuação, vida, onda, combo, indicador de força do arco,
## mira, feedback de acerto/dano e tela de fim de jogo.
## Escuta os sinais do GameState (autoload).

const LOW_HEALTH_RATIO := 0.35 # abaixo disso a vinheta vermelha pulsa

@onready var score_label: Label = $Margin/ScoreLabel
@onready var wave_label: Label = $Margin/WaveLabel
@onready var combo_label: Label = $Margin/ComboLabel
@onready var health_bar: ProgressBar = $Margin/HealthBar
@onready var draw_bar: ProgressBar = $Margin/DrawBar
@onready var hit_popup: Label = $Margin/HitPopup
@onready var crosshair: Control = $Crosshair
@onready var vignette: ColorRect = $Vignette
@onready var game_over_panel: Control = $GameOverPanel
@onready var title_label: Label = $GameOverPanel/Center/Box/TitleLabel
@onready var final_score_label: Label = $GameOverPanel/Center/Box/FinalScoreLabel
@onready var accuracy_label: Label = $GameOverPanel/Center/Box/AccuracyLabel
@onready var record_label: Label = $GameOverPanel/Center/Box/RecordLabel
@onready var restart_button: Button = $GameOverPanel/Center/Box/RestartButton
@onready var menu_button: Button = $GameOverPanel/Center/Box/MenuButton
@onready var wave_banner: Label = $Margin/WaveBanner

var player: Node = null
var _banner_timer: float = 0.0
var _popup_timer: float = 0.0
var _damage_flash: float = 0.0
var _last_health: int = -1
var _pulse_time: float = 0.0
## Posição de repouso do texto de pontos. Precisa ser guardada: mexer em
## `position` sobrescreve o que as âncoras calcularam, e sem a referência
## original o texto acabava no topo da tela, fora de vista.
var _popup_base_pos: Vector2 = Vector2.ZERO
var _popup_base_saved: bool = false

func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	GameState.health_changed.connect(_on_health_changed)
	GameState.wave_changed.connect(_on_wave_changed)
	GameState.combo_changed.connect(_on_combo_changed)
	GameState.hit_registered.connect(_on_hit_registered)
	GameState.game_over.connect(_on_game_over)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

	player = get_tree().get_first_node_in_group("player")
	var wave_manager := get_tree().get_first_node_in_group("wave_manager")
	if wave_manager and wave_manager.has_signal("wave_cleared"):
		wave_manager.wave_cleared.connect(_on_wave_cleared)

	_last_health = GameState.health
	_on_score_changed(GameState.score)
	_on_health_changed(GameState.health, GameState.MAX_HEALTH)
	_on_wave_changed(GameState.current_wave)
	_on_combo_changed(GameState.combo)
	game_over_panel.hide()
	draw_bar.hide()
	wave_banner.hide()
	hit_popup.modulate.a = 0.0
	_set_vignette(0.0)

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

	# texto de pontos sobe devagar e some
	if _popup_timer > 0.0:
		_popup_timer = max(0.0, _popup_timer - delta)
		hit_popup.modulate.a = min(1.0, _popup_timer * 1.6)
		hit_popup.position = _popup_base_pos + Vector2(0.0, -22.0 * (1.0 - _popup_timer))

	_update_vignette(delta)

## Vinheta vermelha: pisca ao tomar dano e fica pulsando com vida baixa.
func _update_vignette(delta: float) -> void:
	_damage_flash = max(0.0, _damage_flash - delta * 2.2)
	var low: float = 0.0
	var ratio: float = float(GameState.health) / float(GameState.MAX_HEALTH)
	if GameState.health > 0 and ratio < LOW_HEALTH_RATIO:
		_pulse_time += delta * 3.0
		var danger: float = 1.0 - (ratio / LOW_HEALTH_RATIO)
		low = (0.22 + 0.10 * sin(_pulse_time)) * danger
	_set_vignette(max(_damage_flash, low))

func _set_vignette(v: float) -> void:
	var mat := vignette.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", clamp(v, 0.0, 1.0))

func _on_score_changed(s: int) -> void:
	score_label.text = "Pontos: %d" % s

func _on_health_changed(h: int, max_h: int) -> void:
	health_bar.max_value = max_h
	health_bar.value = h
	if _last_health != -1 and h < _last_health:
		_damage_flash = 0.85
	_last_health = h

## Marcador de acerto na mira + "+120 Ouro" flutuando.
func _on_hit_registered(points: int, label: String) -> void:
	if not _popup_base_saved:
		_popup_base_pos = hit_popup.position
		_popup_base_saved = true
	var big: bool = points >= GameState.BIG_HIT_THRESHOLD
	crosshair.flash_hit(big)
	hit_popup.text = ("+%d %s" % [points, label]).strip_edges()
	hit_popup.modulate = Color(1.0, 0.82, 0.35) if big else Color(1, 1, 1)
	hit_popup.modulate.a = 1.0
	_popup_timer = 0.9

func _on_wave_changed(w: int) -> void:
	if w <= 0:
		wave_label.hide()
		return
	wave_label.show()
	wave_label.text = "Onda %d" % w
	_show_banner("Onda %d" % w, Color(0.96, 0.92, 0.8))

func _on_wave_cleared(w: int) -> void:
	_show_banner("Onda %d limpa!" % w, Color(0.6, 0.95, 0.6))

func _show_banner(text: String, color: Color) -> void:
	wave_banner.text = text
	wave_banner.add_theme_color_override("font_color", color)
	wave_banner.show()
	_banner_timer = 2.0

func _on_combo_changed(c: int) -> void:
	if c > 1:
		combo_label.show()
		combo_label.text = "Combo x%d" % c
	else:
		combo_label.hide()

func _on_game_over() -> void:
	title_label.text = "Novo Recorde!" if GameState.is_new_record() else "Você Caiu"
	final_score_label.text = "Pontuação final: %d" % GameState.score
	accuracy_label.text = "Precisão: %.0f%% (%d de %d flechas)" % [
		GameState.get_accuracy(), GameState.arrows_hit, GameState.arrows_fired]
	record_label.text = "Recorde: %d pontos · Onda %d" % [GameState.high_score, GameState.best_wave]
	game_over_panel.show()
	_set_vignette(0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	restart_button.grab_focus()

func _on_restart_pressed() -> void:
	Audio.play("click")
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	Audio.play("click")
	Engine.time_scale = 1.0
	GameState.flush_save()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
