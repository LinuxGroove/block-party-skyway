class_name PirateCannon
extends Launcher
## A Pirate Kit cannon that fires on a beat, with fair warning: it rocks
## back and puffs a little smoke just before each shot, and a bigger puff
## when it fires.
##
##   add(PirateCannon.aim(Vector3.RIGHT, 2.4, 0.5), at)

## Seconds of warning before a shot.
const WARN := 0.55

var _warned := false
var _model: Node3D
static var _smoke_mat: StandardMaterial3D


## A cannon firing along `p_direction` every `p_period` seconds.
static func aim(p_direction: Vector3, p_period := 2.4, p_phase := 0.0) -> PirateCannon:
	var c := PirateCannon.new()
	c.model_name = "pirate:cannon"
	c.direction = p_direction.normalized()
	c.period = p_period
	c.phase = p_phase
	c.shot_scale = 1.0
	return c


func _ready() -> void:
	super()
	for n in get_children():
		if n is Node3D:
			_model = n
			break


func _physics_process(delta: float) -> void:
	super(delta)
	if _t < period - WARN:
		_warned = false
	elif not _warned:
		_warned = true
		_warn()


## Seconds since the last shot.
func since_shot() -> float:
	return _t


func _warn() -> void:
	if _model:
		var tw := create_tween()
		tw.tween_property(_model, "scale", Vector3(1.1, 0.85, 1.1), WARN * 0.8).set_ease(Tween.EASE_OUT)
		tw.tween_property(_model, "scale", Vector3.ONE, 0.1)
	_puff(0.25, 2)


func fire() -> Projectile:
	var p := super()
	_puff(0.5, 5)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", -12.0, 0.1)
	return p


## A few balls of smoke at the muzzle.
func _puff(size: float, count: int) -> void:
	if _smoke_mat == null:
		_smoke_mat = StandardMaterial3D.new()
		_smoke_mat.albedo_color = Color(1, 1, 1, 0.8)
		_smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in count:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = size * 0.5
		s.height = size
		s.radial_segments = 8
		s.rings = 4
		m.mesh = s
		m.material_override = _smoke_mat
		add_child(m)
		m.position = muzzle + direction * 0.9 + Vector3(randf_range(-0.2, 0.2), randf_range(0, 0.2), randf_range(-0.2, 0.2))
		var tw := m.create_tween()
		tw.set_parallel()
		tw.tween_property(m, "position", m.position + direction * 0.6 + Vector3.UP * 0.5, 0.6)
		tw.tween_property(m, "scale", Vector3.ONE * 0.05, 0.6).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(m.queue_free)
