class_name PirateBoat
extends AnimatableBody3D
## A rowing boat that glides back and forth across the water, carrying the
## hero: a moving platform for the cove. Its seat is `DECK` above where it's
## placed, so place it a little under the water line.
##
##   add(PirateBoat.make(Vector3(6, 0, 0), 5.0), Vector3(0, -0.9, 0))

## Height of the floor the hero stands on, above the keel.
const DECK := 0.42

var level: Level
var model_name := "pirate:boat-row-large"
var travel := Vector3(4, 0, 0)
var period := 5.0
## Where in its cycle it starts, 0 to 1.
var phase := 0.0
## Which way the bow points; left at zero, along the way it travels.
var heading := Vector3.ZERO

var _start := Vector3.ZERO
var _t := 0.0


static func make(p_travel: Vector3, p_period := 5.0, p_phase := 0.0, p_model := "pirate:boat-row-large") -> PirateBoat:
	var b := PirateBoat.new()
	b.travel = p_travel
	b.period = p_period
	b.phase = p_phase
	b.model_name = p_model
	return b


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_start = position
	_t = phase * period
	var dir := heading if heading.length() > 0.01 else travel
	var turn := atan2(dir.x, dir.z) if dir.length() > 0.01 else 0.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 0.4, 2.6)
	shape.shape = box
	shape.position.y = DECK - 0.2
	shape.rotation.y = turn
	add_child(shape)
	var m := Kit.model(model_name)
	m.rotation.y = turn
	add_child(m)
	_place()


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


## Where it is at a moment, from where it started (for the autopilot).
func offset_at(t: float) -> Vector3:
	var u := (1.0 - cos(TAU * t / period)) / 2.0
	return travel * u


## Where the seat will be `ahead` seconds from now.
func seat_at(ahead := 0.0) -> Vector3:
	return _start + offset_at(_t + ahead) + Vector3.UP * DECK


func _place() -> void:
	position = _start + offset_at(_t)
