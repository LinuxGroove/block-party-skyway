class_name PirateBarrel
extends AnimatableBody3D
## A barrel bobbing in the sea, upright, to hop across like stepping stones.
## Its top rises and sinks a little on a slow beat; place it at the water
## line and its top sits about `TOP` above.

const TOP := 0.55

var level: Level
## How far it bobs up and down, and how long a bob takes.
var bob := 0.25
var period := 2.8
var phase := 0.0

var _home := Vector3.ZERO
var _t := 0.0
var _model: Node3D


static func make(p_phase := 0.0, p_bob := 0.25, p_period := 2.8) -> PirateBarrel:
	var b := PirateBarrel.new()
	b.phase = p_phase
	b.bob = p_bob
	b.period = p_period
	return b


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase * period
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.55
	cyl.height = 1.2
	shape.shape = cyl
	shape.position.y = TOP - 0.6
	add_child(shape)
	_model = Kit.model("pirate:barrel", 0.85)
	_model.position.y = TOP - 1.23 * 0.85
	_model.rotation.y = fmod(_home.x * 1.7 + _home.z, TAU)
	add_child(_model)
	_place()


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


## The top's height above home at a moment.
func lift_at(t: float) -> float:
	return sin(TAU * t / period) * bob


## Where the top will be `ahead` seconds from now.
func top_at(ahead := 0.0) -> Vector3:
	return _home + Vector3.UP * (TOP + lift_at(_t + ahead))


func _place() -> void:
	position = _home + Vector3.UP * lift_at(_t)
	_model.rotation.z = sin(TAU * _t / period * 0.5) * 0.06
