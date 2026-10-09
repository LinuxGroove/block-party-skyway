class_name GearsPiston
extends AnimatableBody3D
## A steel piston that pumps up and down on a beat, carrying whoever stands
## on its head: it rests low, rises, waits at the top, then sinks again. A
## lift to ride, or a step that's only high half the time. Its head's top
## is at the node's position when low; the shaft runs down into a housing.
##
##   add(GearsPiston.make(3.0), at)          # rises 3 m
##   add(GearsPiston.make(2.0, 0.5), at)     # half a beat later

var level: Level
## The head: its top is the platform.
var size := Vector3(2, 0.5, 2)
var lift := 3.0
## Seconds resting low, rising, resting high and sinking.
var low_time := 1.2
var rise_time := 1.1
var high_time := 1.2
var sink_time := 1.1
var phase := 0.0
## Draws the housing the shaft runs into (leave off when it stands in a floor).
var housing := true

var _home := Vector3.ZERO
var _t := 0.0
var _shaft: MeshInstance3D


static func make(p_lift := 3.0, p_phase := 0.0, p_size := Vector3(2, 0.5, 2)) -> GearsPiston:
	var p := GearsPiston.new()
	p.lift = p_lift
	p.phase = p_phase
	p.size = p_size
	return p


func cycle() -> float:
	return low_time + rise_time + high_time + sink_time


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase * cycle()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = -size.y / 2.0
	add_child(shape)
	var nx := int(roundf(size.x))
	var nz := int(roundf(size.z))
	for x in nx:
		for z in nz:
			var m := Kit.model("block-moving-large")
			m.position = Vector3(x - (nx - 1) / 2.0, -size.y, z - (nz - 1) / 2.0)
			m.scale.y = size.y / 0.5
			add_child(m)
	_shaft = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.28
	cyl.bottom_radius = 0.28
	cyl.height = 1.0
	_shaft.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("aab2c0")
	mat.metallic = 0.7
	mat.roughness = 0.3
	_shaft.material_override = mat
	add_child(_shaft)
	if housing:
		var casing := Kit.model("factory:piston-round")
		casing.top_level = true
		add_child(casing)
		casing.scale = Vector3(1.3, 1.0, 1.3)
		casing.global_position = global_position + Vector3.DOWN * (size.y + 1.0)
	_place()


## Height above the low rest at time t.
func offset_at(t: float) -> float:
	var u := fposmod(t, cycle())
	if u < low_time:
		return 0.0
	u -= low_time
	if u < rise_time:
		return lift * smoothstep(0.0, 1.0, u / rise_time)
	u -= rise_time
	if u < high_time:
		return lift
	u -= high_time
	return lift * (1.0 - smoothstep(0.0, 1.0, u / sink_time))


## Where the head's top is now (for tests and the pilot).
func top_at(ahead := 0.0) -> Vector3:
	return _home + Vector3.UP * offset_at(_t + ahead)


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	var off := offset_at(_t)
	position = _home + Vector3.UP * off
	# The shaft fills the gap between the head and where it rests.
	var length := off + (1.0 if housing else 0.0)
	_shaft.visible = length > 0.02
	_shaft.scale.y = maxf(length, 0.02)
	_shaft.position.y = -size.y - length / 2.0
