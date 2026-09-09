extends Control
## Anel do analógico virtual — desenhado em torno da origem local (que o
## TouchControls.gd sempre posiciona exatamente onde o dedo tocou a tela).

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	draw_circle(Vector2.ZERO, 85.0, Color(1, 1, 1, 0.12))
	draw_arc(Vector2.ZERO, 85.0, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 3.0, true)
