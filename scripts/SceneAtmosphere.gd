extends WorldEnvironment
## Monta o céu, a névoa e a luz dourada de entardecer via código — evita
## depender de um recurso Environment gigante escrito à mão no .tscn.

@export var sun: DirectionalLight3D

func _ready() -> void:
	var env := Environment.new()

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.29, 0.42, 0.62)
	sky_material.sky_horizon_color = Color(0.92, 0.72, 0.48)
	sky_material.sky_curve = 0.15
	sky_material.ground_bottom_color = Color(0.35, 0.28, 0.2)
	sky_material.ground_horizon_color = Color(0.92, 0.72, 0.48)
	sky_material.sun_angle_max = 12.0
	sky_material.sun_curve = 0.15

	var sky := Sky.new()
	sky.sky_material = sky_material

	env.background_mode = Environment.BG_SKY
	env.sky = sky

	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.72, 0.58)
	env.fog_light_energy = 1.0
	env.fog_density = 0.0022
	env.fog_sky_affect = 0.12
	env.fog_aerial_perspective = 0.35

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95

	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 1.2

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.ssao_enabled = true

	environment = env

	if sun:
		sun.light_color = Color(1.0, 0.86, 0.68)
		sun.light_energy = 1.3
		sun.shadow_enabled = true
