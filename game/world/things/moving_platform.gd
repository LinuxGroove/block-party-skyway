class_name MovingPlatform
extends AnimatableBody3D
## A platform that glides back and forth between two points, carrying the
## hero. Moved on the physics tick, so riders keep their footing.

var level: Level
var model_name := "platform"
var size := Vector3(2, 0.4, 2)
var travel := Vector3(4, 0, 0)
var period := 4.0
## Where in its cycle it starts, 0 to 1.
var phase := 0.0

var _start := Vector3.ZERO
var _t := 0.0


static func make(p_travel: Vector3, p_period := 4.0, p_phase := 0.0, p_size := Vector3(2, 0.4, 2), p_model := "platform") -> MovingPlatform:
	var m := MovingPlatform.new()
	m.travel = p_travel
	m.period = p_period
	m.phase = p_phase
	m.size = p_size
	m.model_name = p_model
	return m


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_start = position
	_t = phase * period
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = -size.y / 2.0
	add_child(shape)
	# The kit's platforms are 1 by 1, so tile them across the top.
	var nx := int(roundf(size.x))
	var nz := int(roundf(size.z))
	for x in nx:
		for z in nz:
			var m := Kit.model(model_name)
			m.position = Vector3(x - (nx - 1) / 2.0, -size.y, z - (nz - 1) / 2.0)
			m.scale.y = size.y / 0.2 if model_name == "platform" else 1.0
			add_child(m)
	_place()


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


## Where it is at a moment, for tests and the autopilot.
func offset_at(t: float) -> Vector3:
	var u := (1.0 - cos(TAU * t / period)) / 2.0
	return travel * u


func _place() -> void:
	position = _start + offset_at(_t)
