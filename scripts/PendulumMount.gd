extends Node3D
## Suporte que balança um alvo pendurado, tipo pêndulo. Encaixe um Target.tscn
## como filho e ele vai balançar junto.

@export var amplitude_deg: float = 35.0
@export var speed: float = 1.1

var _t: float = 0.0

func _ready() -> void:
	_t = randf() * TAU # começa em fases diferentes pra não sincronizar

func _process(delta: float) -> void:
	_t += delta * speed
	rotation_degrees.z = sin(_t) * amplitude_deg
