class_name GearsRunaway
extends Area3D
## An islander who won't stand still: when the hero comes near he runs off
## round a loop of waypoints, a little slower than a run, and turns back if
## the hero heads him off. Touch him and he gives up.

signal caught

var level: Level
var model_name := "animal-fox"
var who := "Scamp"
## The loop he runs round, in level coordinates.
var path: Array = []
var flee_range := 7.0
var speed := 6.0
var is_caught := false
## Lines once caught (Talk).
var lines: Array = []

var _rig: RigCharacter
var _next := 0
var _dir := 1
## Seconds before he'll turn round again, so he doesn't dither.
var _turn_cool := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	add_to_group("talker")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	shape.shape = box
	shape.position.y = 0.45
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene(model_name), 0.4)
	add_child(_rig)
	if not path.is_empty():
		_next = _nearest(position)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var h := level.hero if level else null
	if is_caught or h == null or path.is_empty():
		return
	_turn_cool = maxf(_turn_cool - delta, 0.0)
	if overlaps_body(h):
		_catch()
		return
	var to_hero := Vector3(h.global_position.x - global_position.x, 0, h.global_position.z - global_position.z)
	if to_hero.length() > flee_range:
		_rig.play("idle")
		_face(to_hero)
		return
	var target: Vector3 = path[_next]
	var flat := Vector3(target.x - position.x, 0, target.z - position.z)
	# Headed straight at the hero? Turn round and run the other way.
	if _turn_cool <= 0.0 and flat.length() > 0.5 and to_hero.length() < 3.5 and flat.normalized().dot(to_hero.normalized()) > 0.5:
		_turn_cool = 1.2
		_dir = -_dir
		_next = posmod(_next + _dir, path.size())
		target = path[_next]
		flat = Vector3(target.x - position.x, 0, target.z - position.z)
	if flat.length() < 0.3:
		_next = posmod(_next + _dir, path.size())
		return
	var step := minf(speed * delta, flat.length())
	position += flat.normalized() * step
	position.y = lerpf(position.y, target.y, clampf(step / maxf(flat.length(), 0.01), 0.0, 1.0))
	_face(flat)
	_rig.play("run")


func _face(dir: Vector3) -> void:
	if dir.length() > 0.01:
		_rig.rotation.y = atan2(dir.x, dir.z)


func _nearest(p: Vector3) -> int:
	var best := 0
	for i in path.size():
		if (path[i] as Vector3).distance_to(p) < (path[best] as Vector3).distance_to(p):
			best = i
	return best


func _on_body_entered(body: Node3D) -> void:
	if level and body == level.hero:
		_catch()


func _catch() -> void:
	if is_caught:
		return
	is_caught = true
	_rig.play_once("dance")
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", 0.0)
	caught.emit()


## Stops running for good (caught on an earlier visit).
func settle() -> void:
	is_caught = true
	_rig.play("idle")


func can_talk() -> bool:
	return is_caught


func talk_range() -> float:
	return 1.6


func talk_text() -> String:
	return "Talk to %s" % who


func talk() -> void:
	_rig.play_once("gesture-positive")
	level.speak(who, lines)
