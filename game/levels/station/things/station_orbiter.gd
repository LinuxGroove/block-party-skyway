class_name StationOrbiter
extends AnimatableBody3D
## A platform that circles a hub, carrying the hero round: the Orbit Ring.
## Flat round the hub, or up and over it like a wheel (staying level). A
## glowing spoke ties it to the hub so the circle reads. Moved on the
## physics tick, so riders keep their footing.
##
##   add(StationOrbiter.make(5.0, 8.0, 0.25), hub)   # at the circle's centre

var level: Level
var radius := 5.0
## Seconds for one lap; negative goes the other way round.
var period := 8.0
## Where on the circle it starts, 0 to 1 (0 is east, 0.25 south).
var phase := 0.0
var size := Vector3(2, 0.5, 2)
var model_name := "block-moving-blue"
## Up and over the hub, east and west, instead of round it.
var wheel := false

var _center := Vector3.ZERO
var _t := 0.0
var _spoke: MeshInstance3D


static func make(p_radius: float, p_period := 8.0, p_phase := 0.0, p_size := Vector3(2, 0.5, 2), p_model := "block-moving-blue") -> StationOrbiter:
	var o := StationOrbiter.new()
	o.radius = p_radius
	o.period = p_period
	o.phase = p_phase
	o.size = p_size
	o.model_name = p_model
	return o


## One of a wheel's platforms: 0 is east, 0.25 the top, 0.5 west.
static func make_wheel(p_radius: float, p_period := 8.0, p_phase := 0.0, p_size := Vector3(2, 0.5, 2)) -> StationOrbiter:
	var o := make(p_radius, p_period, p_phase, p_size)
	o.wheel = true
	return o


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_center = position
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
			var m := Kit.model(model_name)
			m.position = Vector3(x - (nx - 1) / 2.0, -size.y, z - (nz - 1) / 2.0)
			m.scale.y = size.y / 0.2 if model_name == "platform" else 1.0
			add_child(m)
	var lamp := MeshInstance3D.new()
	var dot := SphereMesh.new()
	dot.radius = 0.12
	dot.height = 0.24
	lamp.mesh = dot
	lamp.material_override = StationDeco.glow(Color("9fe3f0"))
	lamp.position = Vector3(0, -size.y - 0.1, 0)
	add_child(lamp)
	_spoke = MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.1, 0.1, maxf(radius - minf(size.x, size.z) / 2.0, 0.1))
	_spoke.mesh = bar
	_spoke.material_override = StationDeco.glow(Color("9fe3f0"), 0.6)
	_spoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_spoke)
	_place()


## Where it is at time `t` (seconds since the level started), for the
## autopilot and tests.
func at_time(t: float) -> Vector3:
	var a := TAU * (phase + t / period)
	if wheel:
		return _center + Vector3(cos(a), sin(a), 0) * radius
	return _center + Vector3(cos(a), 0, sin(a)) * radius


## Where it is `ahead` seconds from now.
func ahead(seconds: float) -> Vector3:
	return at_time(_t + seconds)


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	var at := at_time(_t)
	position = at
	if _spoke:
		# Halfway between the platform's edge and the hub, pointing at it.
		# (Reading position back here would give last tick's: the physics
		# server applies it.)
		var back := (_center - at).normalized()
		var out := minf(size.x, size.z) / 2.0
		_spoke.position = back * (out + (radius - out) / 2.0) + Vector3(0, -size.y / 2.0, 0)
		var up := Vector3.BACK if wheel else Vector3.UP
		_spoke.basis = Basis.looking_at(back, up)
