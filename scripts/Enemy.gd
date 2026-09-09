extends CharacterBody3D
## Espectro das ruínas: flutua em direção ao jogador e ataca de perto.
## Tem duas hitboxes (cabeça/corpo) pra flechada valer mais em headshot.

signal died

@export var max_health: int = 40
@export var move_speed: float = 2.4
@export var attack_range: float = 1.7
@export var attack_damage: int = 8
@export var attack_cooldown: float = 1.1
@export var kill_bonus: int = 30

var health: int
var _attack_timer: float = 0.0
var _bob_time: float = 0.0
var _player: Node3D = null
var _dead: bool = false

@onready var visual: Node3D = $Visual

func _ready() -> void:
	health = max_health
	_bob_time = randf() * TAU
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if _dead or not is_instance_valid(_player):
		return

	_bob_time += delta * 2.2
	visual.position.y = 1.0 + sin(_bob_time) * 0.08

	var to_player: Vector3 = _player.global_position - global_position
	to_player.y = 0.0
	var dist: float = to_player.length()

	if dist > attack_range:
		var dir: Vector3 = to_player.normalized()
		velocity = dir * move_speed
		if dist > 0.05:
			var target_look: Vector3 = global_position + dir
			look_at(target_look, Vector3.UP)
	else:
		velocity = Vector3.ZERO
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = attack_cooldown
			GameState.take_damage(attack_damage)

	move_and_slide()

func take_damage(amount: int, is_headshot: bool) -> void:
	if _dead:
		return
	health -= amount
	if is_headshot:
		health -= 15
	if health <= 0:
		_die()

func _die() -> void:
	_dead = true
	GameState.register_hit(kill_bonus)
	died.emit()
	queue_free()
