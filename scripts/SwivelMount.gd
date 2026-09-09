extends Node3D
## Suporte giratório: o alvo vira de frente e de perfil (esconde a área de
## acerto), obrigando o jogador a cronometrar o disparo.

@export var swing_deg: float = 75.0
@export var speed: float = 0.8

var _t: float = 0.0

func _ready() -> void:
	_t = randf() * TAU

func _process(delta: float) -> void:
	_t += delta * speed
	rotation_degrees.y = sin(_t) * swing_deg
