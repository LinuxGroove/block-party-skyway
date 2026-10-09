class_name CastleBallista
extends StaticBody3D
## A ballista: every few seconds it fires a bolt straight ahead at knee
## height, which flies until it hits something. Jump the bolts, or wait
## behind a wall for one to pass.
##
##   add(CastleBallista.make(Vector3.LEFT, 2.5), at)

const MODEL := "castle:siege-ballista"

var level: Level
var direction := Vector3.FORWARD
var period := 2.5
var phase := 0.0
var speed := 9.0
## How far a bolt flies before it's gone.
var bolt_range := 20.0
var model_scale := 1.2

var _t := 0.0
var _model: Node3D
var _arrow: Node3D


static func make(p_direction: Vector3, p_period := 2.5, p_phase := 0.0) -> CastleBallista:
	var b := CastleBallista.new()
	b.direction = Vector3(p_direction.x, 0, p_direction.z).normalized()
	b.period = p_period
	b.phase = p_phase
	return b


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	_t = phase * period
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 0.9, 1.2)
	shape.shape = box
	shape.position.y = 0.45
	add_child(shape)
	# The kit's ballista shoots along its +x.
	_model = Kit.model(MODEL, model_scale)
	_model.rotation.y = atan2(-direction.z, direction.x)
	add_child(_model)
	_arrow = _model.find_child("arrow", true, false) as Node3D


func _physics_process(delta: float) -> void:
	if level == null:
		return
	_t += delta
	if _arrow:
		# The next bolt slides into place just before it's fired.
		_arrow.visible = _t > period * 0.45
	if _t >= period:
		_t -= period
		fire()


## Height of a bolt above the ballista's feet.
func bolt_height() -> float:
	return 0.42 * model_scale


func fire() -> CastleBolt:
	var b := CastleBolt.new()
	b.velocity = direction * speed
	b.life = bolt_range / speed
	if _arrow is MeshInstance3D:
		b.arrow_mesh = (_arrow as MeshInstance3D).mesh
		b.arrow_scale = model_scale
	level.add(b, position + direction * 1.1 * model_scale + Vector3.UP * bolt_height())
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -10.0, 0.1)
	return b
