extends Control
## Bolinha do analógico que o TouchControls.gd arrasta dentro do raio da base.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(50, 50)

func _draw() -> void:
	draw_circle(size * 0.5, 25.0, Color(1, 1, 1, 0.55))
