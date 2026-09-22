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
var _flash: float = 0.0
var _flash_mats: Array[StandardMaterial3D] = []
var _base_emission: Array = []

@onready var visual: Node3D = $Visual

func _ready() -> void:
	health = max_health
	_bob_time = randf() * TAU
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	_setup_flash_materials()

## Cada espectro precisa da própria cópia do material, senão o clarão de
## dano acenderia todos os inimigos da cena ao mesmo tempo.
func _setup_flash_materials() -> void:
	for path in ["Robe", "Head"]:
		var mesh: MeshInstance3D = visual.get_node_or_null(path)
		if mesh == null:
			continue
		var mat = mesh.get_surface_override_material(0)
		if mat == null:
			continue
		mat = mat.duplicate()
		mesh.set_surface_override_material(0, mat)
		_flash_mats.append(mat)
		_base_emission.append({"on": mat.emission_enabled, "color": mat.emission, "energy": mat.emission_energy_multiplier})

func _physics_process(delta: float) -> void:
	if _dead or not is_instance_valid(_player):
		return
	if GameState.is_game_over:
		velocity = Vector3.ZERO # a partida acabou: para de perseguir e atacar
		return

	_bob_time += delta * 2.2
	visual.position.y = 1.0 + sin(_bob_time) * 0.08
	_update_flash(delta)

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
	_flash = 1.0 # clarão: sem isso não dá pra saber que a flechada acertou
	if health <= 0:
		_die()

## Acende o espectro por um instante ao levar dano e dá um "soco" na escala.
func _update_flash(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash = max(0.0, _flash - delta * 3.4)
	visual.scale = Vector3.ONE * (1.0 + _flash * 0.12)
	for i in range(_flash_mats.size()):
		var mat: StandardMaterial3D = _flash_mats[i]
		var base: Dictionary = _base_emission[i]
		mat.emission_enabled = true
		mat.emission = Color(base.color).lerp(Color(1.0, 0.86, 0.72), _flash * 0.85)
		mat.emission_energy_multiplier = lerp(float(base.energy), 1.9, _flash)
		if _flash <= 0.0:
			mat.emission_enabled = base.on
			mat.emission = base.color
			mat.emission_energy_multiplier = base.energy

func _die() -> void:
	_dead = true
	GameState.register_hit(kill_bonus, "Abatido")
	Audio.play("enemy_death")
	died.emit()
	queue_free()
