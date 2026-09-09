extends Node3D
## Gerencia as ondas de inimigos no Modo Ondas: sorteia pontos de spawn,
## aumenta a dificuldade a cada onda e avisa a UI/GameState do progresso.

signal wave_started(wave_number: int, enemy_count: int)
signal wave_cleared(wave_number: int)
signal all_enemies_defeated

@export var enemy_scene: PackedScene
@export var base_enemy_count: int = 4
@export var enemies_per_wave_increase: int = 2
@export var time_between_waves: float = 4.0
@export var spawn_stagger: float = 0.6

var _spawn_points: Array[Node3D] = []
var _alive_enemies: int = 0
var _pending_spawns: int = 0
var _wave_active: bool = false
var _running: bool = false

## Se true, começa a primeira onda sozinho ao carregar a cena (usado pela
## cena dedicada do Modo Ondas). A tela de menu pode desligar isso e chamar
## start() manualmente quando o jogador escolher o modo.
@export var auto_start: bool = true
@export var first_wave_delay: float = 2.0

func _ready() -> void:
	for child in get_children():
		if child is Marker3D:
			_spawn_points.append(child)
	if auto_start:
		get_tree().create_timer(first_wave_delay).timeout.connect(start)
	GameState.game_over.connect(stop)

func start() -> void:
	if _running:
		return
	_running = true
	GameState.reset_run()
	_next_wave()

func stop() -> void:
	_running = false

func _next_wave() -> void:
	if not _running:
		return
	GameState.advance_wave()
	var count: int = base_enemy_count + (GameState.current_wave - 1) * enemies_per_wave_increase
	wave_started.emit(GameState.current_wave, count)
	_wave_active = true
	_spawn_wave(count)

func _spawn_wave(count: int) -> void:
	_pending_spawns = count
	for i in range(count):
		if not _running:
			return
		var delay: float = i * spawn_stagger
		get_tree().create_timer(delay).timeout.connect(_spawn_one)

func _spawn_one() -> void:
	_pending_spawns = max(0, _pending_spawns - 1)
	if not _running or _spawn_points.is_empty() or not enemy_scene:
		return
	var point: Node3D = _spawn_points[randi() % _spawn_points.size()]
	var enemy := enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = point.global_position
	enemy.died.connect(_on_enemy_died)
	_alive_enemies += 1

func _on_enemy_died() -> void:
	_alive_enemies -= 1
	if _alive_enemies <= 0 and _pending_spawns <= 0 and _wave_active:
		_wave_active = false
		wave_cleared.emit(GameState.current_wave)
		if GameState.health <= 0:
			return
		get_tree().create_timer(time_between_waves).timeout.connect(_next_wave)
