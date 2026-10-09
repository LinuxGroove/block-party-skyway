class_name SunnyPinch
extends Boss
## Captain Pinch, Sunny Isles' boss: a giant crab on his sand bar.
##
## He waits, then picks a move and shows it first:
## - a scuttle: he turns side-on to the hero, raises his claws and shuffles,
##   then rushes sideways at where the hero was. Step out of his way.
## - a charge (after two scuttles): he faces the hero, rears back and snaps
##   his claws, then charges straight ahead. Charging into one of the
##   arena's rocks leaves him dizzy, stars round his head, and only then
##   does a stomp, ground pound or dive hurt him. Charging at a gap, he
##   skids to a stop at the water's edge instead.
## He stops turning a moment before each rush (locked()), so a quick step
## aside dodges it. Three hits beat him; each one makes him a little
## quicker.

enum Act { WAIT, AIM_SCUTTLE, SCUTTLE, AIM_CHARGE, CHARGE, DIZZY, SKID, BACK }

const SCALE := 1.4
const SCUTTLE_SPEED := 9.0
const SCUTTLE_REACH := 9.0
const CHARGE_SPEED := 11.0
const WALK_SPEED := 3.5
const TURN := 4.0

## Seconds he shows a scuttle and a charge before going (less as he speeds
## up), and how long before the end he stops turning.
const SCUTTLE_TELL := 0.8
const CHARGE_TELL := 1.2
const SCUTTLE_LOCK := 0.3
const CHARGE_LOCK := 0.4

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
var _travelled := 0.0
var _taunted := false


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
	_rig.position = Vector3.ZERO
	_rig.rotation = Vector3.ZERO
	match act:
		Act.WAIT:
			_rig.play("idle")
			if h:
				_turn_toward(_flat(h.global_position - global_position), delta)
			# A longer first wait, while he has his say.
			if act_time > (3.0 if time < 3.5 else 0.8 / pace()):
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
			if act_time > 3.2 / pace():
				_wake()
		Act.SKID:
			# Teetering at the water's edge.
			_rig.play("idle")
			_rig.rotation.x = sin(act_time * 14.0) * 0.1
			if act_time > 0.7:
				_start(Act.BACK)
		Act.BACK:
			# Scuttle sideways back to the middle.
			var to := _flat(center - global_position)
			if to.length() < 0.3:
				scuttles_left = 2
				_start(Act.WAIT)
			else:
				_rig.play("walk", 0.15, 1.4)
				_turn_toward(to.cross(Vector3.UP).normalized(), delta)
				_move(to.normalized() * minf(WALK_SPEED * pace() * delta, to.length()), false)


func _start(a: Act) -> void:
	act = a
	act_time = 0.0


## Moves him, stopping at the rocks and the edge. In a charge, a rock
## leaves him dizzy and the edge makes him skid. Returns false if he
## stopped.
func _move(by: Vector3, charging: bool) -> bool:
	var next := global_position + by
	for r in rocks:
		if _flat(next - r).length() < rock_radius + 1.0:
			if charging:
				_bonk(r)
			return false
	if _flat(next - center).length() > edge:
		if charging:
			_start(Act.SKID)
		return false
	global_position = next
	return true


func _bonk(rock: Vector3) -> void:
	global_position += _flat(global_position - rock).normalized() * 0.6
	_start(Act.DIZZY)
	open = true
	_stars.visible = true
	dizzy_count += 1
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactSoft_heavy_000.ogg", 0.0)
	if dizzy_count == 1:
		level.say("He's dizzy! Jump on him!")


func _wake() -> void:
	open = false
	_stars.visible = false
	_start(Act.BACK)


## Right after a hit he's harmless for a moment, while the hero bounces
## clear of him.
func _on_touched(body: Node3D) -> void:
	if invulnerable > 0.6 and not open:
		return
	super(body)


func _on_hit() -> void:
	_stars.visible = false
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
