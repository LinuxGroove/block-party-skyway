class_name CastleCatapult
extends StaticBody3D
## One of King Thud's catapults: every few seconds its arm swings up and
## lobs a stone (CastleShot) in a high arc, with a red ring where it will
## land. It throws at the hero when they're in range (keep moving and it
## misses), or at its own list of spots in turn. A breakable one gives way
## to a ground pound.
##
##   add(CastleCatapult.make(Vector3.BACK, 2.4), at)                 # at the hero
##   var c := CastleCatapult.make(Vector3.LEFT, 2.0); c.spots = [a, b]  # at spots
##   c.model_name = "castle:siege-trebuchet"; c.arm_name = "arm"         # a trebuchet

signal wrecked

const MODEL := "castle:siege-catapult"
const WRECK := "castle:siege-catapult-demolished"

var level: Level
## Which way it faces (its arm throws this way).
var facing := Vector3.FORWARD
var period := 2.4
var phase := 0.0
## Seconds each stone is in the air, and how hard it's pulled down.
var flight := 1.3
var gravity := 20.0
## It throws at the hero between these distances.
var reach := 16.0
var min_reach := 3.0
## Spots in the level to throw at in turn instead of at the hero.
var spots: Array = []
## Breaks when ground pounded (and stops throwing).
var breakable := false
var model_scale := 1.3
## The model, the arm in it that swings, and how high (at scale 1) the stone
## leaves from: a catapult, or a trebuchet with a taller arm.
var model_name := MODEL
var arm_name := "catapult"
var muzzle_height := 1.6
var is_wrecked := false

var _t := 0.0
var _next_spot := 0
var _model: Node3D
var _arm: Node3D


static func make(p_facing: Vector3, p_period := 2.4, p_phase := 0.0) -> CastleCatapult:
	var c := CastleCatapult.new()
	c.facing = Vector3(p_facing.x, 0, p_facing.z).normalized()
	c.period = p_period
	c.phase = p_phase
	return c


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	if breakable:
		add_to_group("poundable")
	_t = phase * period
	# Small enough that landing anywhere on it is a pound close to its middle.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 1.0, 1.0)
	shape.shape = box
	shape.position.y = 0.5
	shape.rotation.y = atan2(-facing.z, facing.x)
	add_child(shape)
	_show(WRECK if is_wrecked else model_name)


## The kit's catapult throws along its +x; turn that to `facing`.
func _show(model: String) -> void:
	if _model:
		_model.queue_free()
	_model = Kit.model(model, model_scale)
	_model.rotation.y = atan2(-facing.z, facing.x)
	add_child(_model)
	_arm = _model.find_child(arm_name, true, false) as Node3D


func _physics_process(delta: float) -> void:
	if is_wrecked or level == null:
		return
	_t += delta
	if _t >= period:
		_t -= period
		var at := _aim()
		if at != Vector3.INF:
			fire(at)


## Where to throw next, in level space, or INF to hold fire.
func _aim() -> Vector3:
	if not spots.is_empty():
		var s: Vector3 = spots[_next_spot % spots.size()]
		_next_spot += 1
		return s
	var h := level.hero
	if h == null:
		return Vector3.INF
	var to := h.global_position - global_position
	var flat := Vector2(to.x, to.z).length()
	if flat < min_reach or flat > reach or absf(to.y) > 7.0:
		return Vector3.INF
	return Vector3(h.global_position.x, h.last_floor_y, h.global_position.z) - level.global_position


## Throws a stone to land on `at` (level space).
func fire(at: Vector3) -> CastleShot:
	var from := position + facing * 0.9 * model_scale + Vector3.UP * muzzle_height * model_scale
	var shot := CastleShot.lob(from, at, flight, gravity)
	level.add(shot, from)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -8.0, 0.1)
	if _arm:
		var tw := create_tween()
		tw.tween_property(_arm, "rotation:z", deg_to_rad(-95.0), 0.12)
		tw.tween_property(_arm, "rotation:z", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	return shot


func pound() -> void:
	if not breakable or is_wrecked:
		return
	is_wrecked = true
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", -2.0, 0.1)
	_show(WRECK)
	_model.scale = Vector3(model_scale * 1.3, model_scale * 0.4, model_scale * 1.3)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3.ONE * model_scale, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	wrecked.emit()
