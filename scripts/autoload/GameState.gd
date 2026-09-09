extends Node
## Estado global do jogo: pontuação, vida, wave atual e recordes.
## Autoload — acessível de qualquer lugar como `GameState`.

signal score_changed(new_score: int)
signal health_changed(new_health: int, max_health: int)
signal wave_changed(new_wave: int)
signal combo_changed(combo: int)
signal game_over

const MAX_HEALTH := 100
const COMBO_WINDOW := 2.5 # segundos para manter o combo entre acertos

var score: int = 0
var high_score: int = 0
var health: int = MAX_HEALTH
var current_wave: int = 0
var combo: int = 0
var _combo_timer: float = 0.0
var arrows_fired: int = 0
var arrows_hit: int = 0

func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(combo)

func reset_run() -> void:
	score = 0
	health = MAX_HEALTH
	current_wave = 0
	combo = 0
	_combo_timer = 0.0
	arrows_fired = 0
	arrows_hit = 0
	score_changed.emit(score)
	health_changed.emit(health, MAX_HEALTH)
	wave_changed.emit(current_wave)
	combo_changed.emit(combo)

func register_shot() -> void:
	arrows_fired += 1

func register_hit(base_points: int) -> void:
	arrows_hit += 1
	combo += 1
	_combo_timer = COMBO_WINDOW
	var multiplier: float = 1.0 + (min(combo, 10) - 1) * 0.15
	var points: int = int(round(base_points * multiplier))
	score += points
	if score > high_score:
		high_score = score
	score_changed.emit(score)
	combo_changed.emit(combo)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		game_over.emit()

func heal(amount: int) -> void:
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

func advance_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)

func get_accuracy() -> float:
	if arrows_fired == 0:
		return 0.0
	return float(arrows_hit) / float(arrows_fired) * 100.0
