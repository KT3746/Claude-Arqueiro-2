extends Node
## Estado global do jogo: pontuação, vida, wave atual e recordes.
## Autoload — acessível de qualquer lugar como `GameState`.

signal score_changed(new_score: int)
signal health_changed(new_health: int, max_health: int)
signal wave_changed(new_wave: int)
signal combo_changed(combo: int)
signal game_over
signal big_hit # acerto de destaque (bullseye/headshot) — pra tremor de câmera/hit-stop
signal hit_registered(points: int, label: String) # pra marcador de acerto e texto flutuante
signal high_score_changed(new_high: int)

const MAX_HEALTH := 100
const COMBO_WINDOW := 2.5 # segundos para manter o combo entre acertos
const BIG_HIT_THRESHOLD := 50
const SAVE_PATH := "user://save.dat"

var score: int = 0
var high_score: int = 0
var best_wave: int = 0
var health: int = MAX_HEALTH
var current_wave: int = 0
var combo: int = 0
var arrows_fired: int = 0
var arrows_hit: int = 0

## True do momento da morte até o próximo reset_run(). Impede que cada
## ataque extra de inimigo dispare game_over de novo.
var is_game_over: bool = false

var _combo_timer: float = 0.0
## Recorde no início da run — pra saber se a run realmente bateu o recorde,
## já que high_score é atualizado ao vivo durante a partida.
var _high_score_at_run_start: int = 0
var _save_dirty: bool = false

func _ready() -> void:
	_load()
	_high_score_at_run_start = high_score

func _process(delta: float) -> void:
	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0:
			combo = 0
			combo_changed.emit(combo)

func reset_run() -> void:
	flush_save()
	score = 0
	health = MAX_HEALTH
	current_wave = 0
	combo = 0
	_combo_timer = 0.0
	arrows_fired = 0
	arrows_hit = 0
	is_game_over = false
	_high_score_at_run_start = high_score
	score_changed.emit(score)
	health_changed.emit(health, MAX_HEALTH)
	wave_changed.emit(current_wave)
	combo_changed.emit(combo)

func register_shot() -> void:
	arrows_fired += 1

func register_hit(base_points: int, label: String = "") -> void:
	if is_game_over:
		return
	arrows_hit += 1
	combo += 1
	_combo_timer = COMBO_WINDOW
	var multiplier: float = 1.0 + (min(combo, 10) - 1) * 0.15
	var points: int = int(round(base_points * multiplier))
	score += points
	if score > high_score:
		high_score = score
		high_score_changed.emit(high_score)
		_save_dirty = true # grava em disco só no fim da run, não a cada flecha
	score_changed.emit(score)
	combo_changed.emit(combo)
	hit_registered.emit(points, label)
	if base_points >= BIG_HIT_THRESHOLD:
		big_hit.emit()

func take_damage(amount: int) -> void:
	if is_game_over:
		return
	health = max(0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0:
		is_game_over = true
		game_over.emit()
		flush_save()

func heal(amount: int) -> void:
	if is_game_over:
		return
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

func advance_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)
	if current_wave > best_wave:
		best_wave = current_wave
		_save_dirty = true
		flush_save() # onda nova é raro o bastante pra valer gravar na hora

## A run atual superou o recorde que existia quando ela começou?
func is_new_record() -> bool:
	return score > _high_score_at_run_start

func get_accuracy() -> float:
	if arrows_fired == 0:
		return 0.0
	return float(arrows_hit) / float(arrows_fired) * 100.0

## Grava em disco só se algo mudou. Chamado no fim da run / troca de cena.
func flush_save() -> void:
	if not _save_dirty:
		return
	_save_dirty = false
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var({"high_score": high_score, "best_wave": best_wave})

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		flush_save()

func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var data = file.get_var()
	if typeof(data) == TYPE_DICTIONARY:
		high_score = int(data.get("high_score", 0))
		best_wave = int(data.get("best_wave", 0))
