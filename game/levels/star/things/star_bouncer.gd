class_name StarBouncer
extends Area3D
## A big bumble bee hovering over a gap that springs the hero up when they
## land on it, as often as they like (it squashes and puffs back up, so a
## fall never leaves a gap without its bee). Brushing past its side does
## nothing. It drifts back and forth along `travel`.
##
##   add(StarBouncer.make(Vector3(3, 0, 0), 3.0), at)

var level: Level
var model_name := "animal-bee"
var model_scale := 0.6
var travel := Vector3.ZERO
var period := 3.0
var phase := 0.0
## The launch speed, a little less than a spring's.
var power := 13.0
var size := Vector3(1.3, 0.8, 1.3)

var _start := Vector3.ZERO
var _t := 0.0
var _cool := 0.0
var _rig: RigCharacter


static func make(p_travel: Vector3, p_period := 3.0, p_phase := 0.0) -> StarBouncer:
	var b := StarBouncer.new()
	b.travel = p_travel
	b.period = p_period
	b.phase = p_phase
	return b


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	_start = position
	_t = phase * period
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene(model_name), model_scale)
	add_child(_rig)
	_rig.play("walk")
	_place()


## Where it is `t` seconds into its drift, for tests.
func offset_at(t: float) -> Vector3:
	if period <= 0.0:
		return Vector3.ZERO
	return travel * (1.0 - cos(TAU * t / period)) / 2.0


func _place() -> void:
	position = _start + offset_at(_t)


func _physics_process(delta: float) -> void:
	_t += delta
	_cool = maxf(_cool - delta, 0.0)
	_place()
	var h := level.hero if level else null
	if h == null or _cool > 0.0 or not overlaps_body(h):
		return
	# Only from above, on the way down.
	if h.velocity.y <= 0.5 and h.global_position.y > global_position.y + size.y * 0.3:
		h.bounce(power)
		_cool = 0.25
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_bump.ogg", -2.0, 0.1)
		var tw := create_tween()
		tw.tween_property(_rig, "scale", Vector3(1.3, 0.5, 1.3), 0.06)
		tw.tween_property(_rig, "scale", Vector3.ONE, 0.2)
