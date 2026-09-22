extends Control
## Mira desenhada via código (sem depender de textura): um pequeno círculo
## que fecha conforme o jogador puxa a corda, mais um marcador de acerto
## que pisca quando a flecha encontra o alvo.

var draw_amount: float = 0.0 # 0..1, força atual do puxão
var is_aiming: bool = false

var _hit_marker: float = 0.0 # 1 -> 0, tempo restante do marcador
var _hit_was_big: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_state(new_draw_amount: float, aiming: bool) -> void:
	if is_equal_approx(draw_amount, new_draw_amount) and aiming == is_aiming:
		return
	draw_amount = new_draw_amount
	is_aiming = aiming
	queue_redraw()

## Pisca o "X" de acerto. `big` deixa dourado (bullseye / cabeça).
func flash_hit(big: bool) -> void:
	_hit_marker = 1.0
	_hit_was_big = big
	queue_redraw()

func _process(delta: float) -> void:
	if _hit_marker > 0.0:
		_hit_marker = max(0.0, _hit_marker - delta * 2.5)
		queue_redraw()

func _draw() -> void:
	var center: Vector2 = size * 0.5
	var base_radius: float = 10.0 if not is_aiming else 5.0
	var gap: float = lerp(6.0, 1.0, draw_amount)
	var color := Color(1, 1, 1, 0.85)
	if draw_amount > 0.75:
		color = Color(1.0, 0.82, 0.35, 0.95)

	# quatro tracinhos em cruz que se fecham conforme a força aumenta
	for i in range(4):
		var angle: float = i * PI * 0.5
		var dir := Vector2(cos(angle), sin(angle))
		var from: Vector2 = center + dir * (base_radius + gap)
		var to: Vector2 = center + dir * (base_radius + gap + 6.0)
		draw_line(from, to, color, 2.0, true)

	draw_circle(center, 1.5, color)

	# marcador de acerto: um "X" que abre e some
	if _hit_marker > 0.0:
		var hit_color := Color(1.0, 0.8, 0.25, _hit_marker) if _hit_was_big else Color(1, 1, 1, _hit_marker)
		var spread: float = lerp(20.0, 12.0, _hit_marker)
		var length: float = 7.0
		for i in range(4):
			var angle: float = PI * 0.25 + i * PI * 0.5
			var dir := Vector2(cos(angle), sin(angle))
			draw_line(center + dir * spread, center + dir * (spread + length), hit_color, 2.5, true)
