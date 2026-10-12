class_name SunnyPinch
extends Boss
## Captain Pinch, Sunny Isles' boss: a giant crab on his sand bar.
##
## He waits, then picks a move and shows it first, with a red line on the
## sand where he'll go:
## - a scuttle: he turns side-on to the hero, raises his claws and shuffles,
##   then rushes sideways at where the hero was. Step out of his way.
## - a charge (after two scuttles): he faces the hero, rears back and snaps
##   his claws, then charges straight ahead. Charging into one of the
##   arena's rocks leaves him dizzy, stars round his head, and only then
##   does a stomp, ground pound or dive hurt him. Charging at a gap, he
##   skids to a stop at the water's edge instead.
## He stops turning a moment before each rush (locked()) and the line
## blinks faster, so a quick step aside dodges it. Dizzy, his sides don't
## hurt, so the hero can run up and jump on him. Three hits beat him; each
## one makes him a little quicker. The hero is told how to beat him at the
## start, and again after a charge misses the rocks or a stomp bounces off
## his shell.

enum Act { WAIT, AIM_SCUTTLE, SCUTTLE, AIM_CHARGE, CHARGE, DIZZY, SKID, BACK }

const SCALE := 1.4
const SCUTTLE_SPEED := 9.0
const SCUTTLE_REACH := 9.0
const CHARGE_SPEED := 11.0
const WALK_SPEED := 3.5
const TURN := 4.0

## Seconds he shows a scuttle and a charge before going (less as he speeds
## up), and how long before the end he stops turning.
const SCUTTLE_TELL := 0.9
const CHARGE_TELL := 1.4
const SCUTTLE_LOCK := 0.45
const CHARGE_LOCK := 0.6
## Seconds he stays dizzy (less as he speeds up).
const DIZZY_TIME := 4.0
## Seconds he tries to walk back to the middle before fighting from where
## he is.
const BACK_TIME := 5.0
## What stops a step (see _stop()), besides a rock's index.
const FREE := -1
const EDGE := -2

## Centres of the rocks he can charge into (flat), and how big they are.
var rocks: Array[Vector3] = []
var rock_radius := 1.1
## The middle of the arena, and how far from it he may go.
var center := Vector3.ZERO
var edge := 10.0
var act := Act.WAIT
## Seconds spent in the current act.
var act_time := 0.0
## The way he moves in a scuttle or charge, flat and unit length.
var dir := Vector3.FORWARD
## Which way he faces, flat and unit length.
var facing := Vector3.BACK
var scuttles_left := 2
var dizzy_count := 0

var _rig: RigCharacter
var _stars: Node3D
var _line: MeshInstance3D
var _line_mat: StandardMaterial3D
var _travelled := 0.0
var _taunted := false
## Which hints the hero has had: how to beat him, a charge that missed, a
## stomp on his shell.
var _told := false
var _told_miss := false
var _told_shell := false
## Which way round a rock he last walked: 1 or -1.
var _round_side := 1.0


func _ready() -> void:
	super()
	boss_name = "Captain Pinch"
	_rig = RigCharacter.create(Kit.scene("animal-crab"), SCALE)
	add_child(_rig)
	_rig.set_looping("run")
	_rig.set_looping("gesture-negative")
	make_body(Vector3(3.0, 1.5, 1.8))
	_stars = Node3D.new()
	_stars.position.y = 2.6
	_stars.visible = false
	add_child(_stars)
	for i in 3:
		var s := Kit.model("star", 1.6)
		var a := TAU * i / 3.0
		s.position = Vector3(cos(a), 0, sin(a)) * 0.8
		_stars.add_child(s)
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
	_face(facing)


## How much quicker he is after each hit: 1, then a bit more.
func pace() -> float:
	return 1.0 + 0.15 * (max_health - health)


## True once a scuttle or charge is set: he won't turn any more until it's
## over.
func locked() -> bool:
	match act:
		Act.AIM_SCUTTLE:
			return act_time > SCUTTLE_TELL / pace() - SCUTTLE_LOCK
		Act.AIM_CHARGE:
			return act_time > CHARGE_TELL / pace() - CHARGE_LOCK
		Act.SCUTTLE, Act.CHARGE:
			return true
	return false


func think(delta: float) -> void:
	act_time += delta
	var h := hero()
	if not _taunted and time > 1.0:
		_taunted = true
		level.say("Captain Pinch: Nobody tricks ME into charging a rock! ...Nobody!")
	if not _told and time > 2.5:
		_told = true
		level.say("When he rears back to charge, stand by a rock so he runs into it. Then jump on him while he's dizzy!")
	_rig.position = Vector3.ZERO
	_rig.rotation = Vector3.ZERO
	match act:
		Act.WAIT:
			_rig.play("idle")
			if h:
				_turn_toward(_flat(h.global_position - global_position), delta)
			# A longer first wait, while he has his say.
			if act_time > (4.0 if time < 4.5 else 0.8 / pace()):
				if scuttles_left > 0:
					_start(Act.AIM_SCUTTLE)
					LGAudio.play_sfx("res://assets/kenney/audio/sfx/footstep_wood_001.ogg", -2.0, 0.1)
				else:
					_start(Act.AIM_CHARGE)
					LGAudio.play_sfx("res://assets/kenney/audio/sfx/maximize_003.ogg", -4.0)
		Act.AIM_SCUTTLE:
			# Side-on to the hero, claws up, feet shuffling.
			_rig.play("gesture-negative")
			if h and not locked():
				var to := _flat(h.global_position - global_position)
				_turn_toward(to.cross(Vector3.UP).normalized() if to.length() > 0.1 else facing, delta * 2.0)
				dir = to.normalized() if to.length() > 0.1 else dir
			_rig.position.x = sin(act_time * 40.0) * 0.06
			_show_line(SCUTTLE_REACH, 1.5)
			if act_time > SCUTTLE_TELL / pace():
				_start(Act.SCUTTLE)
				_travelled = 0.0
		Act.SCUTTLE:
			_rig.play("run", 0.1, 1.6)
			var step := SCUTTLE_SPEED * pace() * delta
			if not _move(dir * step, false):
				_travelled = SCUTTLE_REACH
			_travelled += step
			if _travelled >= SCUTTLE_REACH:
				scuttles_left -= 1
				_start(Act.WAIT)
		Act.AIM_CHARGE:
			# Face the hero, rear back, snap the claws.
			_rig.play("gesture-negative", 0.1, 1.5)
			if h and not locked():
				_turn_toward(_flat(h.global_position - global_position), delta * 2.0)
			dir = facing
			_rig.rotation.x = -0.22 * minf(act_time * 3.0, 1.0)
			_rig.position.z = -0.3 * minf(act_time * 3.0, 1.0)
			_show_line(edge * 3.0, 0.9)
			if act_time > CHARGE_TELL / pace():
				_start(Act.CHARGE)
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", 0.0)
		Act.CHARGE:
			_rig.play("run", 0.1, 2.0)
			_rig.rotation.x = 0.12
			_move(dir * CHARGE_SPEED * pace() * delta, true)
		Act.DIZZY:
			_rig.play("idle", 0.2, 0.5)
			_rig.rotation.z = sin(act_time * 5.0) * 0.12
			_stars.rotation.y += delta * 4.0
			if act_time > DIZZY_TIME / pace():
				_wake()
		Act.SKID:
			# Teetering at the water's edge.
			_rig.play("idle")
			_rig.rotation.x = sin(act_time * 14.0) * 0.1
			if act_time > 0.7:
				_start(Act.BACK)
		Act.BACK:
			# Scuttle sideways back to the middle, round any rock in the way.
			# Boxed in, or taking too long, he fights from where he is.
			var to := _flat(center - global_position)
			var way := Vector3.ZERO
			if to.length() >= 0.3 and act_time < BACK_TIME:
				way = _walk_round(to, minf(WALK_SPEED * pace() * delta, to.length()))
			if way == Vector3.ZERO:
				scuttles_left = 2
				_start(Act.WAIT)
			else:
				_rig.play("walk", 0.15, 1.4)
				_turn_toward(way.cross(Vector3.UP).normalized(), delta)
	if act != Act.AIM_SCUTTLE and act != Act.AIM_CHARGE:
		_line.visible = false


func _start(a: Act) -> void:
	act = a
	act_time = 0.0


## What stops a step from `from` to `next`: the index of a rock it runs
## into, EDGE past the edge, or FREE. A step away from a rock or back from
## the edge is never stopped, so he can't be stuck against one.
func _stop(from: Vector3, next: Vector3) -> int:
	for i in rocks.size():
		var d := _flat(next - rocks[i]).length()
		if d < rock_radius + 1.0 and d < _flat(from - rocks[i]).length():
			return i
	var out := _flat(next - center).length()
	if out > edge and out > _flat(from - center).length():
		return EDGE
	return FREE


## Moves him, stopping at the rocks and the edge. In a charge, a rock
## leaves him dizzy and the edge makes him skid. Returns false if he
## stopped.
func _move(by: Vector3, charging: bool) -> bool:
	var next := global_position + by
	var stop := _stop(global_position, next)
	if stop == FREE:
		global_position = next
		return true
	if charging:
		if stop == EDGE:
			_skid()
		else:
			_bonk(rocks[stop])
	return false


## Steps him `step` toward `to` (flat), round a rock if one is in the way:
## straight on if he can, else turned further and further, trying first
## the side he last went round. Returns the way he went, or zero if every
## way is blocked.
func _walk_round(to: Vector3, step: float) -> Vector3:
	var d := to.normalized()
	for turn: float in [0.0, 30.0, 60.0, 90.0, 120.0, -30.0, -60.0, -90.0, -120.0]:
		var way := d.rotated(Vector3.UP, deg_to_rad(turn) * _round_side)
		if _move(way * step, false):
			if turn < 0.0:
				_round_side = -_round_side
			return way
	return Vector3.ZERO


## Where a rush along `dir` from here would stop: at a rock, the edge or
## `reach` metres on.
func rush_end(reach: float) -> Vector3:
	var at := global_position
	var gone := 0.0
	while gone < reach:
		var step := minf(0.25, reach - gone)
		if _stop(at, at + dir * step) != FREE:
			break
		at += dir * step
		gone += step
	return at


## Shows the line on the sand where a rush will go, from his front (`front`
## metres ahead of him) to where it'll be when he stops, blinking faster
## once he's locked on.
func _show_line(reach: float, front: float) -> void:
	var from := global_position + dir * front
	var to := rush_end(reach) + dir * front
	var length := maxf(_flat(to - from).length(), 0.1)
	_line.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP).scaled_local(Vector3(1, 1, length)), (from + to) / 2.0 + Vector3.UP * 0.05)
	_line_mat.albedo_color.a = 0.35 + 0.25 * sin(act_time * (16.0 if locked() else 6.0))
	_line.visible = true


func _bonk(rock: Vector3) -> void:
	global_position += _flat(global_position - rock).normalized() * 0.6
	_start(Act.DIZZY)
	open = true
	_stars.visible = true
	dizzy_count += 1
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactSoft_heavy_000.ogg", 0.0)
	if dizzy_count == 1:
		level.say("He's dizzy! Jump on him!")


## Teetering at the water's edge after a charge: if he's never hit a rock
## yet, the hero is shown how again.
func _skid() -> void:
	_start(Act.SKID)
	if dizzy_count == 0 and not _told_miss:
		_told_miss = true
		level.say("He missed the rocks! Wait in front of one, and step aside when his red line blinks fast.")


func _wake() -> void:
	open = false
	_stars.visible = false
	_start(Act.BACK)


## Right after a hit he's harmless for a moment, while the hero bounces
## clear of him, and while he's dizzy only a stomp, pound or dive does
## anything. A stomp on his shell when he isn't dizzy hurts, and says why.
func _on_touched(body: Node3D) -> void:
	if beaten or body != level.hero:
		return
	if invulnerable > 0.6 and not open:
		return
	var h := level.hero
	var stomp := h.is_pounding() or h.is_diving() or (_above <= 3 and h.velocity.y < 1.0)
	if open and not stomp:
		return
	if not open and stomp and invulnerable <= 0.0 and not _told_shell:
		_told_shell = true
		level.say("Ouch, his shell's too hard! Make him charge into a rock first.")
	super(body)


func _on_hit() -> void:
	_stars.visible = false
	_line.visible = false
	# Throw the hero clear, so the bounce doesn't come down on him again.
	var h := hero()
	if h:
		var away := _flat(h.global_position - global_position)
		away = away.normalized() if away.length() > 0.1 else -facing
		h.velocity.x = away.x * 6.0
		h.velocity.z = away.z * 6.0
	_start(Act.BACK)


func _turn_toward(want: Vector3, delta: float) -> void:
	if want.length() < 0.01:
		return
	var angle := facing.signed_angle_to(want.normalized(), Vector3.UP)
	_face(facing.rotated(Vector3.UP, clampf(angle, -TURN * delta, TURN * delta)))


func _face(f: Vector3) -> void:
	facing = _flat(f).normalized() if _flat(f).length() > 0.01 else facing
	rotation.y = atan2(facing.x, facing.z)


static func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)
