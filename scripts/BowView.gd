extends Node3D
## Modelo do arco em primeira pessoa: monta o limbo curvo com segmentos retos
## orientados em runtime (a mesma técnica usada pra corda) — mais simples e
## confiável do que depender de CSGPolygon3D junto de um Path3D.

@export var rest_nock_z: float = 0.03
@export var max_pull_z: float = 0.32

@onready var top_tip: Marker3D = $TopTip
@onready var bottom_tip: Marker3D = $BottomTip
@onready var nock: Node3D = $Nock
@onready var string_top: MeshInstance3D = $StringTop
@onready var string_bottom: MeshInstance3D = $StringBottom
@onready var nocked_arrow: MeshInstance3D = $NockedArrow
@onready var limb_top_a: MeshInstance3D = $LimbTopA
@onready var limb_top_b: MeshInstance3D = $LimbTopB
@onready var limb_bottom_a: MeshInstance3D = $LimbBottomA
@onready var limb_bottom_b: MeshInstance3D = $LimbBottomB

const GRIP_TOP := Vector3(0.0, 0.09, 0.0)
const GRIP_BOTTOM := Vector3(0.0, -0.09, 0.0)
const TOP_MID := Vector3(0.0, 0.24, 0.11)
const BOTTOM_MID := Vector3(0.0, -0.24, 0.11)

func _ready() -> void:
	# O limbo é estático — monta uma vez só.
	_orient_segment(limb_top_a, GRIP_TOP, TOP_MID)
	_orient_segment(limb_top_b, TOP_MID, top_tip.position)
	_orient_segment(limb_bottom_a, GRIP_BOTTOM, BOTTOM_MID)
	_orient_segment(limb_bottom_b, BOTTOM_MID, bottom_tip.position)

	nock.position.z = rest_nock_z
	_update_string()

func set_draw(t: float) -> void:
	t = clamp(t, 0.0, 1.0)
	nock.position.z = lerp(rest_nock_z, max_pull_z, t)
	nocked_arrow.visible = t > 0.001
	_update_string()

func _update_string() -> void:
	_orient_segment(string_top, top_tip.position, nock.position)
	_orient_segment(string_bottom, bottom_tip.position, nock.position)
	nocked_arrow.position.z = nock.position.z - 0.38

func _orient_segment(node: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var mid: Vector3 = (a + b) * 0.5
	var diff: Vector3 = b - a
	var length: float = diff.length()
	if length < 0.001:
		node.visible = false
		return
	node.visible = true
	node.position = mid
	node.basis = Basis(Quaternion(Vector3.UP, diff.normalized()))
	node.scale = Vector3(1.0, length, 1.0)
