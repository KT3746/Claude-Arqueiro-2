extends GPUParticles3D
## Folhas caindo lentamente pela arena — só um toque de vida no ambiente.

func _ready() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.55, 0.22)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mesh.material = mat
	draw_pass_1 = mesh

	var process_mat := ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0, -1, 0)
	process_mat.spread = 25.0
	process_mat.gravity = Vector3(0, -0.35, 0)
	process_mat.initial_velocity_min = 0.1
	process_mat.initial_velocity_max = 0.4
	process_mat.angular_velocity_min = -60.0
	process_mat.angular_velocity_max = 60.0
	process_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_mat.emission_box_extents = Vector3(28.0, 1.0, 28.0)
	process_mat.scale_min = 0.6
	process_mat.scale_max = 1.4
	process_material = process_mat

	amount = 90
	lifetime = 14.0
	preprocess = 14.0
	visibility_aabb = AABB(Vector3(-30, -12, -30), Vector3(60, 24, 60))
