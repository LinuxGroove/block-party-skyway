class_name CastleDrawbridge
extends AnimatableBody3D
## A drawbridge that lowers across a gap, stays down a while, then swings
## up on its hinge and stays up: wait for it to come down, then cross.
## Raised, it stands across the gateway behind it like a wall. Anyone left
## on it as it rises slides off.
##
##   add(CastleDrawbridge.make(Vector3(0, 0, 6), 3.0), hinge)   # lowers towards +z

const MODEL := "castle:bridge-draw"

var level: Level
## From the hinge to the far end when lowered (flat).
var reach := Vector3(0, 0, 6)
var width := 3.0
## Seconds lowered, swinging, raised and swinging back.
var down_time := 4.0
var swing_time := 1.2
var up_time := 2.4
var phase := 0.0
## How far up it swings, in degrees (90 stands it upright).
var raised_angle := 88.0

var _t := 0.0
var _axis := Vector3.RIGHT
var _shape: CollisionShape3D
var _chains: Array[MeshInstance3D] = []


static func make(p_reach: Vector3, p_width := 3.0, p_down := 4.0, p_up := 2.4, p_phase := 0.0) -> CastleDrawbridge:
	var d := CastleDrawbridge.new()
	d.reach = Vector3(p_reach.x, 0, p_reach.z)
	d.width = p_width
	d.down_time = p_down
	d.up_time = p_up
	d.phase = p_phase
	return d


func cycle() -> float:
	return down_time + swing_time + up_time + swing_time


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_t = phase * cycle()
	var dir := reach.normalized()
	_axis = dir.cross(Vector3.UP).normalized()
	_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 0.3, reach.length())
	_shape.shape = box
	_shape.basis = Basis.looking_at(dir, Vector3.UP)
	_shape.position = reach / 2.0 + Vector3.DOWN * 0.15
	add_child(_shape)
	# The kit's drawbridge runs from its origin out along -x, 0.83 wide.
	var plank := Kit.model(MODEL)
	plank.scale = Vector3(reach.length(), 2.5, width / 0.83)
	plank.rotation.y = atan2(dir.z, -dir.x)
	plank.position = Vector3.DOWN * 0.25
	add_child(plank)
	# Chains from the far corners up to the gateway, dark iron.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("4a4c58")
	for i in 2:
		var chain := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.05
		cyl.bottom_radius = 0.05
		cyl.height = 1.0
		cyl.radial_segments = 6
		chain.mesh = cyl
		chain.material_override = mat
		chain.top_level = true
		add_child(chain)
		_chains.append(chain)
	_place()


## Degrees raised at time t: 0 is down (flat).
func angle_at(t: float) -> float:
	var u := fposmod(t, cycle())
	if u < down_time:
		return 0.0
	u -= down_time
	if u < swing_time:
		return raised_angle * smoothstep(0.0, 1.0, u / swing_time)
	u -= swing_time
	if u < up_time:
		return raised_angle
	u -= up_time
	return raised_angle * (1.0 - smoothstep(0.0, 1.0, u / swing_time))


## True while it's flat and will stay so for at least `seconds` more.
func is_down_for(seconds: float, ahead := 0.0) -> bool:
	var u := fposmod(_t + ahead, cycle())
	return u + seconds <= down_time


func is_down() -> bool:
	return angle_at(_t) < 0.5


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	basis = Basis(_axis, deg_to_rad(angle_at(_t)))
	if not is_inside_tree():
		return
	for i in _chains.size():
		var s := -1.0 if i == 0 else 1.0
		var across := _axis * s * (width / 2.0 - 0.15)
		var foot := global_transform * (reach * 0.85 + across)
		var top := global_position + across + Vector3.UP * reach.length() * 0.7
		var along := top - foot
		var chain := _chains[i]
		chain.global_position = (foot + top) / 2.0
		chain.global_basis = Basis(Quaternion(Vector3.UP, along.normalized())).scaled_local(Vector3(1.0, along.length(), 1.0))
