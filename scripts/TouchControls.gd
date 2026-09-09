extends CanvasLayer
## Controles de toque pra celular: analógico flutuante (esquerda = andar),
## arrastar em qualquer lugar da direita = olhar, e dois botões (mirar/atirar).
## Só aparece se o dispositivo tiver tela sensível ao toque; em desktop com
## mouse fica invisível e não interfere em nada.

@export var look_sensitivity: float = 0.006
@export var joystick_radius: float = 85.0
@export var joystick_dead_zone: float = 10.0

var player: Node = null

var _joy_touch_index: int = -1
var _joy_center: Vector2 = Vector2.ZERO
var _joy_output: Vector2 = Vector2.ZERO

var _look_touch_index: int = -1
var _shoot_touch_index: int = -1
var _aim_touch_index: int = -1

@onready var joystick_layer: Control = $JoystickLayer
@onready var shoot_button: Control = $ShootButton
@onready var aim_button: Control = $AimButton

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available():
		visible = false
		set_process(false)
		set_process_input(false)
		return
	player = get_tree().get_first_node_in_group("player")
	joystick_layer.visible = false

func _shoot_rect() -> Rect2:
	return Rect2(shoot_button.global_position, shoot_button.size)

func _aim_rect() -> Rect2:
	return Rect2(aim_button.global_position, aim_button.size)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start(event.index, event.position)
		else:
			_touch_end(event.index)
	elif event is InputEventScreenDrag:
		_touch_drag(event.index, event.position, event.relative)

func _touch_start(index: int, pos: Vector2) -> void:
	if _shoot_rect().has_point(pos):
		_shoot_touch_index = index
		Input.action_press("shoot", 1.0)
		return
	if _aim_rect().has_point(pos):
		_aim_touch_index = index
		Input.action_press("aim", 1.0)
		return
	var viewport_width: float = get_viewport().get_visible_rect().size.x
	if pos.x < viewport_width * 0.5:
		_joy_touch_index = index
		_joy_center = pos
		_joy_output = Vector2.ZERO
		joystick_layer.visible = true
		joystick_layer.position = pos
		_update_joystick_visual()
	else:
		_look_touch_index = index

func _touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if index == _joy_touch_index:
		var offset: Vector2 = pos - _joy_center
		if offset.length() > joystick_radius:
			offset = offset.normalized() * joystick_radius
		_joy_output = offset / joystick_radius
		_update_joystick_visual()
	elif index == _look_touch_index and is_instance_valid(player):
		player.apply_look_delta(relative * look_sensitivity)

func _touch_end(index: int) -> void:
	if index == _joy_touch_index:
		_joy_touch_index = -1
		_joy_output = Vector2.ZERO
		joystick_layer.visible = false
	elif index == _look_touch_index:
		_look_touch_index = -1
	elif index == _shoot_touch_index:
		_shoot_touch_index = -1
		Input.action_release("shoot")
	elif index == _aim_touch_index:
		_aim_touch_index = -1
		Input.action_release("aim")

func _update_joystick_visual() -> void:
	var knob: Control = joystick_layer.get_node("Knob")
	knob.position = _joy_output * joystick_radius - knob.size * 0.5

func _process(_delta: float) -> void:
	if _joy_touch_index == -1:
		return
	var v: Vector2 = _joy_output
	if v.length() < joystick_dead_zone / joystick_radius:
		v = Vector2.ZERO
	_drive_axis("move_left", "move_right", v.x)
	_drive_axis("move_forward", "move_back", v.y)

func _drive_axis(neg_action: String, pos_action: String, value: float) -> void:
	if value < -0.02:
		Input.action_press(neg_action, clamp(-value, 0.0, 1.0))
		Input.action_release(pos_action)
	elif value > 0.02:
		Input.action_press(pos_action, clamp(value, 0.0, 1.0))
		Input.action_release(neg_action)
	else:
		Input.action_release(neg_action)
		Input.action_release(pos_action)
