extends Node3D
## Espalha árvores e pedras estilizadas ao redor da arena usando MultiMesh
## (bom desempenho, muitas instâncias em poucas chamadas de desenho).
## Mantém uma área livre no centro (onde o jogador e os alvos ficam).

@export var tree_count: int = 46
@export var rock_count: int = 18
@export var area_size: Vector2 = Vector2(70, 90)
## Área retangular (o "corredor" de tiro) onde nada deve ser plantado.
@export var clear_half_width: float = 9.0
@export var clear_z_min: float = -34.0
@export var clear_z_max: float = 6.0
@export var scatter_seed: int = 1337

@onready var trunk_mm: MultiMeshInstance3D = $TrunkMultiMesh
@onready var foliage_mm: MultiMeshInstance3D = $FoliageMultiMesh
@onready var rock_mm: MultiMeshInstance3D = $RockMultiMesh

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed
	_build_trees(rng)
	_build_rocks(rng)

func _is_in_lane(pos: Vector3) -> bool:
	return abs(pos.x) < clear_half_width and pos.z > clear_z_min and pos.z < clear_z_max

func _random_clear_position(rng: RandomNumberGenerator) -> Vector3:
	var pos := Vector3.ZERO
	for _try in range(20):
		pos = Vector3(
			rng.randf_range(-area_size.x * 0.5, area_size.x * 0.5),
			0.0,
			rng.randf_range(-area_size.y * 0.5, area_size.y * 0.5)
		)
		if not _is_in_lane(pos):
			break
	return pos

func _build_trees(rng: RandomNumberGenerator) -> void:
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.14
	trunk_mesh.bottom_radius = 0.2
	trunk_mesh.height = 2.2
	trunk_mesh.radial_segments = 6
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.27, 0.18, 0.12)
	trunk_mat.roughness = 0.95
	trunk_mesh.material = trunk_mat

	var foliage_mesh := SphereMesh.new()
	foliage_mesh.radius = 1.3
	foliage_mesh.height = 2.4
	foliage_mesh.radial_segments = 7
	foliage_mesh.rings = 5
	var foliage_mat := StandardMaterial3D.new()
	foliage_mat.albedo_color = Color(0.24, 0.4, 0.17)
	foliage_mat.roughness = 0.9
	foliage_mesh.material = foliage_mat

	var trunk_multimesh := MultiMesh.new()
	trunk_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	trunk_multimesh.mesh = trunk_mesh
	trunk_multimesh.instance_count = tree_count

	var foliage_multimesh := MultiMesh.new()
	foliage_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	foliage_multimesh.mesh = foliage_mesh
	foliage_multimesh.instance_count = tree_count

	for i in range(tree_count):
		var pos: Vector3 = _random_clear_position(rng)
		var scale_v: float = rng.randf_range(0.8, 1.5)
		var rot: float = rng.randf_range(0.0, TAU)
		var basis := Basis(Vector3.UP, rot).scaled(Vector3(scale_v, scale_v, scale_v))
		trunk_multimesh.set_instance_transform(i, Transform3D(basis, pos + Vector3(0.0, 1.1 * scale_v, 0.0)))
		foliage_multimesh.set_instance_transform(i, Transform3D(basis, pos + Vector3(0.0, 2.6 * scale_v, 0.0)))

	trunk_mm.multimesh = trunk_multimesh
	foliage_mm.multimesh = foliage_multimesh

func _build_rocks(rng: RandomNumberGenerator) -> void:
	var rock_mesh := BoxMesh.new()
	rock_mesh.size = Vector3(0.8, 0.6, 0.7)
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.45, 0.44, 0.4)
	rock_mat.roughness = 1.0
	rock_mesh.material = rock_mat

	var rock_multimesh := MultiMesh.new()
	rock_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	rock_multimesh.mesh = rock_mesh
	rock_multimesh.instance_count = rock_count

	for i in range(rock_count):
		var pos: Vector3 = _random_clear_position(rng)
		var scale_v: Vector3 = Vector3(
			rng.randf_range(0.5, 1.4), rng.randf_range(0.4, 1.0), rng.randf_range(0.5, 1.4)
		)
		var rot: float = rng.randf_range(0.0, TAU)
		var basis := Basis(Vector3.UP, rot).scaled(scale_v)
		rock_multimesh.set_instance_transform(i, Transform3D(basis, pos + Vector3(0.0, scale_v.y * 0.3, 0.0)))

	rock_mm.multimesh = rock_multimesh
