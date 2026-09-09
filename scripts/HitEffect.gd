extends GPUParticles3D
## Estourinho de partículas ao acertar um alvo ou inimigo. Toca uma vez e
## se autodestrói — instanciado dinamicamente pela Arrow.gd.

func _ready() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.035, 0.035, 0.035)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.45, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.7, 0.2, 1.0)
	mat.emission_energy_multiplier = 2.5
	mesh.material = mat
	draw_pass_1 = mesh

	var process_mat := ParticleProcessMaterial.new()
	process_mat.direction = Vector3(0, 1, 0)
	process_mat.spread = 180.0
	process_mat.gravity = Vector3(0, -4.5, 0)
	process_mat.initial_velocity_min = 1.2
	process_mat.initial_velocity_max = 3.0
	process_mat.scale_min = 0.5
	process_mat.scale_max = 1.3
	process_mat.damping_min = 2.0
	process_mat.damping_max = 4.0
	process_material = process_mat

	amount = 14
	lifetime = 0.45
	one_shot = true
	explosiveness = 1.0
	emitting = true

	get_tree().create_timer(1.0).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)
