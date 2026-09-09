extends Control
## Botão redondo pra tela de toque (mirar/atirar). Desenhado via código —
## sem depender de nenhuma imagem.

@export var label_text: String = ""
@export var button_color: Color = Color(1, 1, 1, 0.22)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var r: float = size.x * 0.5
	var center: Vector2 = size * 0.5
	draw_circle(center, r, button_color)
	draw_arc(center, r, 0.0, TAU, 32, Color(1, 1, 1, 0.5), 3.0, true)
	if label_text != "":
		var font: Font = ThemeDB.fallback_font
		var font_size: int = 15
		var text_size: Vector2 = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.35), label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.9))
