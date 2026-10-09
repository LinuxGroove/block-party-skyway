class_name SpikeTrap
extends Area3D
## Spikes that pop up and sink back on a beat. They hurt only while up.

const DOWN_TIME := 1.4
const UP_TIME := 1.0

var level: Level
## Offset in the beat, 0 to 1, so rows of traps make a wave.
var phase := 0.0

var _anim: AnimationPlayer
var _t := 0.0
var _up := false


static func make(p_phase := 0.0) -> SpikeTrap:
	var s := SpikeTrap.new()
	s.phase = p_phase
	return s


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.95, 0.5, 0.95)
	shape.shape = box
	shape.position.y = 0.25
	add_child(shape)
	var m := Kit.model("trap-spikes-large", 1.3)
	add_child(m)
	_anim = m.find_children("*", "AnimationPlayer", true, false)[0] if not m.find_children("*", "AnimationPlayer", true, false).is_empty() else null
	_t = phase * (DOWN_TIME + UP_TIME)
	if _anim:
		_anim.play("hide")
		_anim.seek(_anim.current_animation_length, true)


func is_up() -> bool:
	return _up


func _physics_process(delta: float) -> void:
	_t = fmod(_t + delta, DOWN_TIME + UP_TIME)
	var up := _t >= DOWN_TIME
	if up != _up:
		_up = up
		if _anim:
			_anim.play("show" if up else "hide")
	if _up and level.hero and overlaps_body(level.hero):
		level.hurt_hero(global_position)
