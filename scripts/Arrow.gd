extends RigidBody3D
## Flecha física: voa em arco real (gravidade), gira para acompanhar a
## velocidade, e finca no primeiro obstáculo/alvo/inimigo que atingir.

const STICK_OFFSET := 0.05 # recua um pouco a ponta pra não atravessar visualmente
const MIN_STICK_SPEED := 1.5

var _stuck := false
var damage: int = 20

var hit_effect_scene: PackedScene = preload("res://scenes/entities/HitEffect.tscn")

@onready var tip_sensor: Area3D = $TipSensor
@onready var mesh_root: Node3D = $MeshRoot
@onready var trail: GPUParticles3D = $Trail

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	body_entered.connect(_on_body_entered)
	tip_sensor.area_entered.connect(_on_tip_area_entered)

func _physics_process(_delta: float) -> void:
	if _stuck:
		return
	if linear_velocity.length() > 0.5:
		look_at(global_position + linear_velocity.normalized(), Vector3.UP if abs(linear_velocity.normalized().dot(Vector3.UP)) < 0.99 else Vector3.FORWARD)

func launch(from: Vector3, velocity: Vector3) -> void:
	global_position = from
	linear_velocity = velocity
	if velocity.length() > 0.1:
		look_at(from + velocity.normalized(), Vector3.UP if abs(velocity.normalized().dot(Vector3.UP)) < 0.99 else Vector3.FORWARD)

func _on_body_entered(body: Node) -> void:
	if _stuck:
		return
	if body is RigidBody3D or body.is_in_group("arrow"):
		return
	Audio.play("impact_wood", -4.0, randf_range(0.9, 1.1))
	_stick_to(body)

func _on_tip_area_entered(area: Area3D) -> void:
	if _stuck:
		return
	if area.is_in_group("target_zone"):
		var target = area.get_parent()
		if target and target.has_method("register_hit"):
			target.register_hit(tip_sensor.global_position)
		Audio.play("impact_wood", -2.0, randf_range(0.95, 1.1))
		_spawn_hit_effect(tip_sensor.global_position)
		_stick_to(area)
	elif area.is_in_group("enemy_hitbox"):
		var enemy = area.get_parent()
		var is_headshot: bool = area.name == "Head"
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(damage, is_headshot)
		GameState.register_hit(50 if is_headshot else 20)
		Audio.play("impact_flesh", -2.0, randf_range(0.9, 1.15))
		_spawn_hit_effect(tip_sensor.global_position)
		_stick_to(area)

func _spawn_hit_effect(at_position: Vector3) -> void:
	var fx := hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = at_position

func _stick_to(body: Node) -> void:
	_stuck = true
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	tip_sensor.set_deferred("monitoring", false)
	if trail:
		trail.emitting = false
	# Gruda visualmente no objeto atingido, seguindo-o se ele se mover (alvo pendular, inimigo).
	# Reparentar precisa ser adiado: estamos dentro de um callback de física,
	# e mexer na árvore de nós agora seria inseguro.
	if body is Node3D and is_instance_valid(body):
		call_deferred("_reparent_to", body)
	# Some segundos depois some, pra não acumular infinitas flechas na cena.
	get_tree().create_timer(12.0).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

func _reparent_to(body: Node) -> void:
	if not is_instance_valid(self) or not is_instance_valid(body):
		return
	var xform := global_transform
	var parent := get_parent()
	if parent:
		parent.remove_child(self)
	body.add_child(self)
	global_transform = xform
