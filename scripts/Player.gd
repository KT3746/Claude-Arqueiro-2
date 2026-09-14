extends CharacterBody3D
## Controlador do jogador em primeira pessoa: movimento, câmera e a mecânica
## do arco (mirar com o botão direito, puxar/segurar o botão esquerdo,
## soltar para disparar uma flecha física de verdade).

@export_group("Movimento")
@export var walk_speed: float = 4.5
@export var sprint_speed: float = 7.0
@export var aim_speed_mult: float = 0.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0025
@export var acceleration: float = 45.0

@export_group("Arco")
@export var min_draw_time: float = 0.15
@export var max_draw_time: float = 0.9
@export var min_launch_speed: float = 16.0
@export var max_launch_speed: float = 44.0
@export var normal_fov: float = 75.0
@export var aim_fov: float = 55.0

const GRAVITY: float = 9.8

var _yaw: float = 0.0
var _pitch: float = 0.0
var is_aiming: bool = false
var is_drawing: bool = false
var draw_time: float = 0.0
var _aim_amount: float = 0.0
var _bob_time: float = 0.0
var _last_bob_phase: float = 0.0
var _shake_strength: float = 0.0
var _last_health: int = -1
var alive: bool = true

var arrow_scene: PackedScene = preload("res://scenes/entities/Arrow.tscn")

@onready var head: Node3D = $Head
@onready var camera_rig: Node3D = $Head/CameraRig
@onready var camera: Camera3D = $Head/CameraRig/Camera3D
@onready var muzzle: Marker3D = $Head/CameraRig/Camera3D/MuzzlePoint
@onready var bow_view: Node3D = $Head/CameraRig/Camera3D/BowView

var _bow_hip_pos := Vector3(0.30, -0.30, -0.55)
var _bow_hip_rot := Vector3(0.0, deg_to_rad(18), deg_to_rad(-8))
var _bow_aim_pos := Vector3(0.0, -0.15, -0.40)
var _bow_aim_rot := Vector3.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.fov = normal_fov
	bow_view.position = _bow_hip_pos
	bow_view.rotation = _bow_hip_rot
	GameState.game_over.connect(_on_game_over)
	GameState.big_hit.connect(_on_big_hit)
	GameState.health_changed.connect(_on_health_changed)
	_last_health = GameState.health

func _unhandled_input(event: InputEvent) -> void:
	if not alive:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		apply_look_delta(event.relative * mouse_sensitivity)

## Gira a câmera. `delta` já vem multiplicado pela sensibilidade de quem
## chama (mouse ou o dedo no controle de toque no celular).
func apply_look_delta(delta: Vector2) -> void:
	_yaw -= delta.x
	_pitch = clamp(_pitch - delta.y, deg_to_rad(-85.0), deg_to_rad(85.0))

func _physics_process(delta: float) -> void:
	if not alive:
		return
	rotation.y = _yaw
	head.rotation.x = _pitch

	is_aiming = Input.is_action_pressed("aim")
	_handle_draw(delta)
	_handle_movement(delta)
	_update_bow_pose(delta)
	_update_camera_fov(delta)

func _handle_movement(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump") and not is_drawing:
		velocity.y = jump_velocity

	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var target_speed: float = walk_speed
	if Input.is_action_pressed("sprint") and not is_aiming and not is_drawing and input_dir.y < 0.0:
		target_speed = sprint_speed
	if is_aiming:
		target_speed *= aim_speed_mult

	velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)

	move_and_slide()

	# Balanço de câmera bem sutil ao andar, pra dar vida sem distrair a mira.
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and horizontal_speed > 0.5:
		_bob_time += delta * horizontal_speed * 1.6
		var phase: float = fmod(_bob_time, TAU)
		if phase < _last_bob_phase:
			Audio.play("footstep", -10.0, randf_range(0.9, 1.1))
		_last_bob_phase = phase
	else:
		_bob_time = lerp(_bob_time, 0.0, delta * 4.0)
		_last_bob_phase = fmod(_bob_time, TAU)
	camera_rig.position.y = sin(_bob_time) * 0.03 * (0.3 if is_aiming else 1.0)

	# Tremor de câmera (headshot/bullseye/dano) — decai sozinho com o tempo.
	if _shake_strength > 0.001:
		camera_rig.rotation.z = randf_range(-1.0, 1.0) * _shake_strength
		camera_rig.rotation.x = randf_range(-1.0, 1.0) * _shake_strength * 0.5
		_shake_strength = move_toward(_shake_strength, 0.0, delta * 5.0)
	elif camera_rig.rotation != Vector3.ZERO:
		camera_rig.rotation = Vector3.ZERO

func _handle_draw(delta: float) -> void:
	if Input.is_action_just_pressed("shoot") and not is_drawing:
		is_drawing = true
		draw_time = 0.0
		Audio.play("draw", -8.0)
	if is_drawing:
		if Input.is_action_pressed("shoot"):
			draw_time = min(draw_time + delta, max_draw_time)
		if Input.is_action_just_released("shoot"):
			_fire_arrow()
			is_drawing = false
			draw_time = 0.0

func _fire_arrow() -> void:
	var t: float = clamp(draw_time / max_draw_time, 0.0, 1.0)
	if draw_time < min_draw_time:
		t = 0.15
	var speed: float = lerp(min_launch_speed, max_launch_speed, t)
	var arrow: RigidBody3D = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	var dir: Vector3 = -camera.global_transform.basis.z
	arrow.launch(muzzle.global_position, dir * speed)
	GameState.register_shot()
	Audio.play("release", -2.0, lerp(0.9, 1.15, t))

func _on_big_hit() -> void:
	_shake_strength = max(_shake_strength, 0.12)
	Engine.time_scale = 0.06
	get_tree().create_timer(0.05, true, false, true).timeout.connect(func():
		Engine.time_scale = 1.0
	)

func _on_health_changed(h: int, _max_h: int) -> void:
	if _last_health != -1 and h < _last_health:
		_shake_strength = max(_shake_strength, 0.06)
		Audio.play("damage")
	_last_health = h

func _update_bow_pose(delta: float) -> void:
	var aim_target: float = 1.0 if is_aiming else 0.0
	_aim_amount = move_toward(_aim_amount, aim_target, delta * 6.0)
	bow_view.position = _bow_hip_pos.lerp(_bow_aim_pos, _aim_amount)
	bow_view.rotation = _bow_hip_rot.lerp(_bow_aim_rot, _aim_amount)
	if bow_view.has_method("set_draw"):
		var draw_t: float = (draw_time / max_draw_time) if is_drawing else 0.0
		bow_view.set_draw(draw_t)

func _update_camera_fov(delta: float) -> void:
	var target_fov: float = aim_fov if is_aiming else normal_fov
	camera.fov = move_toward(camera.fov, target_fov, delta * 80.0)

func _on_game_over() -> void:
	alive = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
