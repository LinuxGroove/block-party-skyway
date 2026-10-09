class_name FrostyBigChill
extends Boss
## The Big Chill: a huge polar bear who owns the ice rink. He turns to face
## the hero and crouches while a line on the ice shows where he'll go, then
## belly-slides along it until he slams into the snow wall round the rink.
## Dazed, with stars spinning round his head, he's open to a stomp or a
## ground pound. Every hit makes him aim quicker and slide faster.

enum State { WAIT, AIM, SLIDE, DAZED, RECOVER }

## Seconds he aims, how fast he slides and how long he's dazed, by hits
## taken (none, one, two).
const AIM_TIME := [1.5, 1.15, 0.9]
const SLIDE_SPEED := [10.0, 13.0, 16.0]
const DAZE_TIME := [3.4, 3.0, 2.6]
## The last part of the aim, when the line stops following the hero.
const LOCK_TIME := 0.45
const RECOVER_TIME := 1.2
const BODY := Vector3(1.9, 1.5, 1.9)

var state := State.WAIT
## The rink's middle and how far its walls are from it (their inner faces).
var center := Vector3.ZERO
var half := 9.0

var _dir := Vector3.FORWARD
var _t := 0.0
var _end := Vector3.ZERO
var _rig: RigCharacter
var _line: MeshInstance3D
var _line_mat: StandardMaterial3D
var _stars: Node3D
var _told := false


func _ready() -> void:
	super()
	make_body(BODY)
	_rig = RigCharacter.create(Kit.scene("animal-polar"), 1.3)
	add_child(_rig)
	_rig.play("idle")
	_line = MeshInstance3D.new()
	_line.top_level = true
	_line_mat = StandardMaterial3D.new()
	_line_mat.albedo_color = Color(1.0, 0.35, 0.3, 0.0)
	_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line.material_override = _line_mat
	_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var strip := BoxMesh.new()
	strip.size = Vector3(1.6, 0.03, 1.0)
	_line.mesh = strip
	_line.visible = false
	add_child(_line)
	_stars = Node3D.new()
	_stars.position.y = 2.3
	for i in 3:
		var s := Kit.model("star", 1.2)
		var a := TAU * i / 3.0
		s.position = Vector3(cos(a), 0, sin(a)) * 0.7
		_stars.add_child(s)
	_stars.visible = false
	add_child(_stars)


## 0, 1 or 2: how many hits he's taken, for his timings.
func anger() -> int:
	return clampi(max_health - health, 0, 2)


func think(delta: float) -> void:
	_t += delta
	var h := hero()
	match state:
		State.WAIT:
			_face(h, delta, 3.0)
			if time > 1.6:
				_aim()
		State.AIM:
			var aim: float = AIM_TIME[anger()]
			if _t < aim - LOCK_TIME:
				_face(h, delta, 6.0)
				_dir = _facing()
				_end = _slide_end()
			# The line blinks faster just before he goes.
			var blink := 6.0 if _t < aim - LOCK_TIME else 16.0
			_line_mat.albedo_color.a = 0.35 + 0.25 * sin(_t * blink)
			_show_line()
			_rig.scale = Vector3(1.0, 1.0 - 0.15 * minf(_t / aim, 1.0), 1.0)
			if not _told and level and time > 2.0:
				_told = true
				level.say("The Big Chill slides your way! Dodge him, then jump on him while he's dizzy.")
			if _t >= aim:
				_slide()
		State.SLIDE:
			var speed: float = SLIDE_SPEED[anger()]
			var step := speed * delta
			var left := Vector3(_end.x - position.x, 0, _end.z - position.z).length()
			if step >= left:
				position = Vector3(_end.x, position.y, _end.z)
				_slam()
			else:
				position += _dir * step
		State.DAZED:
			_stars.rotation.y += delta * 4.0
			_rig.rotation.z = sin(_t * 5.0) * 0.12
			if _t >= DAZE_TIME[anger()]:
				_recover()
		State.RECOVER:
			_face(h, delta, 4.0)
			if _t >= RECOVER_TIME:
				_aim()


func _aim() -> void:
	state = State.AIM
	_t = 0.0
	_rig.rotation = Vector3(0, _rig.rotation.y, 0)
	_rig.play("gesture-negative")
	_dir = _facing()
	_end = _slide_end()
	_line.visible = true


func _slide() -> void:
	state = State.SLIDE
	_t = 0.0
	_line.visible = false
	_rig.scale = Vector3.ONE
	# Down on his belly, nose first.
	_rig.rotation.x = deg_to_rad(75.0)
	_rig.position.y = 0.35
	_rig.play("run")
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -2.0, 0.05)


func _slam() -> void:
	state = State.DAZED
	_t = 0.0
	open = true
	_rig.rotation.x = 0.0
	_rig.position.y = 0.0
	_rig.play("idle")
	_stars.visible = true
	# A little bounce back off the wall.
	var tw := create_tween()
	tw.tween_property(self, "position", position - _dir * 0.4, 0.2).set_ease(Tween.EASE_OUT)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", 0.0, 0.05)


func _recover() -> void:
	state = State.RECOVER
	_t = 0.0
	open = false
	_stars.visible = false
	_rig.rotation.z = 0.0
	_rig.play_once("gesture-negative")


func _on_hit() -> void:
	_stars.visible = false
	_rig.rotation.z = 0.0
	_rig.play_once("gesture-negative")
	state = State.RECOVER
	_t = 0.0
	if level:
		level.say(["Ow! Now I'm cross!", "Grr! Faster, then!"][clampi(max_health - health - 1, 0, 1)])


func _on_beaten() -> void:
	_line.visible = false
	_stars.visible = false
	super()


## Turns towards the hero, `rate` radians a second at most.
func _face(h: Hero, delta: float, rate: float) -> void:
	if h == null:
		return
	var to := h.global_position - global_position
	to.y = 0.0
	if to.length() < 0.1:
		return
	var want := atan2(to.x, to.z)
	var cur := _rig.rotation.y
	_rig.rotation.y = cur + clampf(wrapf(want - cur, -PI, PI), -rate * delta, rate * delta)


func _facing() -> Vector3:
	return Vector3(sin(_rig.rotation.y), 0, cos(_rig.rotation.y))


## Where a slide along `_dir` stops: his side touching a wall.
func _slide_end() -> Vector3:
	var r := BODY.x / 2.0
	var lim := half - r
	var best := 1000.0
	for axis in [0, 2]:
		var d: float = _dir[axis]
		if absf(d) < 0.001:
			continue
		var wall: float = center[axis] + (lim if d > 0.0 else -lim)
		var t := (wall - position[axis]) / d
		if t >= 0.0:
			best = minf(best, t)
	return position + _dir * best


func _show_line() -> void:
	var from := global_position + _dir * (BODY.x / 2.0)
	var to := global_position + (_end - position)
	var length := maxf(from.distance_to(to), 0.1)
	_line.global_transform = Transform3D(Basis.looking_at(_dir, Vector3.UP).scaled(Vector3(1, 1, length)), (from + to) / 2.0 + Vector3.UP * 0.05)
