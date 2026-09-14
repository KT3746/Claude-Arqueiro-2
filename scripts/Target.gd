extends Node3D
## Alvo de treino: 5 zonas concêntricas (ouro/vermelho/azul/preto/branco,
## igual a um alvo olímpico de tiro com arco). A pontuação é calculada pela
## distância real do impacto ao centro, não por áreas sobrepostas.

signal hit(points: int, zone_name: String)

## Desligue para alvos pendurados (pêndulo) que não fazem sentido ter um
## suporte de madeira saindo do meio do ar.
@export var show_stand: bool = true

const ZONES := [
	{"radius": 0.06, "points": 100, "name": "Ouro"},
	{"radius": 0.12, "points": 80, "name": "Vermelho"},
	{"radius": 0.18, "points": 60, "name": "Azul"},
	{"radius": 0.24, "points": 40, "name": "Preto"},
	{"radius": 0.30, "points": 20, "name": "Branco"},
]

func _ready() -> void:
	if not show_stand:
		var post: Node = get_node_or_null("Post")
		if post:
			post.visible = false
			post.set_collision_layer_value(1, false)

func register_hit(world_pos: Vector3) -> void:
	var local_pos: Vector3 = to_local(world_pos)
	var dist: float = Vector2(local_pos.x, local_pos.y).length()
	for zone in ZONES:
		if dist <= zone.radius:
			GameState.register_hit(zone.points)
			if zone.points >= 80:
				Audio.play("bullseye")
			hit.emit(zone.points, zone.name)
			return
	GameState.register_hit(5)
	hit.emit(5, "Tábua")
