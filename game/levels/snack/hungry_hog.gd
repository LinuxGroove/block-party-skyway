class_name HungryHog
extends Boss
## The Hungry Hog, Snack Valley's boss: a huge hog in a pen ringed with
## giant cakes. He trots to the middle and sniffs the air (nose down), then
## turns to the hero and a stripe on the ground shows the line he'll charge
## along, from him to the cake behind the hero. He thunders down it, smashes
## into the cake and gets stuck: that's the moment to jump on his back (or
## ground pound him, or dive into him). Three hits, and each time he sniffs
## quicker and charges faster.
##
## While he's stuck, bumping into his side doesn't hurt; at any other time
## touching him does.

enum State { INTRO, TROT, SNIFF, AIM, CHARGE, STUCK, BACK_OUT }

## Charge speed, the seconds the line shows before he goes, and the seconds
## he's stuck, for 3, 2 and 1 hearts left.
const CHARGE_SPEED := [15.0, 12.5, 10.0]
const AIM_TIME := [0.7, 0.85, 1.05]
const STUCK_TIME := [2.0, 2.4, 2.8]
const SNIFF_TIME := 1.1
const TROT_SPEED := 4.5
const MODEL_SCALE := 1.35

var state := State.INTRO
var state_time := 0.0
## The cakes he can charge into: [centre (feet), radius].
var cakes: Array = []
## Where he trots back to between charges.
var home := Vector3.ZERO
## The charge: which way, and where it ends (at a cake).
var charge_dir := Vector3.FORWARD
var charge_end := Vector3.ZERO
var charge_cake := -1
var facing := Vector3.BACK

var rig: RigCharacter
var _line: MeshInstance3D
var _line_mat: StandardMaterial3D
var _said_stuck := false


func _ready() -> void:
	super()
	max_health = 3
	health = 3
	make_body(Vector3(1.8, 1.45, 1.8))
	rig = RigCharacter.create(Kit.scene("animal-hog"), MODEL_SCALE)
	add_child(rig)
	_line = MeshInstance3D.new()
	_line.top_level = true
	_line_mat = StandardMaterial3D.new()
	_line_mat.albedo_color = Color(1.0, 0.25, 0.35, 0.5)
	_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line.material_override = _line_mat
	add_child(_line)
	_line.visible = false
	home = position


func _level_index() -> int:
	return clampi(max_health - health, 0, 2)


func think(delta: float) -> void:
	state_time += delta
	match state:
		State.INTRO:
			rig.play("idle")
			if state_time > 1.2:
				level.say("SNORT! I'll charge you flat... unless I get stuck in a cake first!")
				_go(State.SNIFF)
		State.TROT:
			var to := home - position
			to.y = 0.0
			if to.length() < 0.2:
				_go(State.SNIFF)
			else:
				_face(to, delta, 8.0)
				position += to.normalized() * minf(TROT_SPEED * delta, to.length())
				rig.play("walk")
		State.SNIFF:
			rig.play("eat")
			_face(_to_hero(), delta, 3.0)
			if state_time > SNIFF_TIME:
				_aim()
				_go(State.AIM)
		State.AIM:
			_face(charge_dir, delta, 10.0)
			rig.play("idle")
			_line_mat.albedo_color.a = 0.35 + 0.3 * absf(sin(state_time * 12.0))
			if state_time > AIM_TIME[_level_index()]:
				_go(State.CHARGE)
				rig.play("run", 0.1, 1.8)
		State.CHARGE:
			var left := charge_end - position
			left.y = 0.0
			var step: float = CHARGE_SPEED[_level_index()] * delta
			if left.length() <= step:
				position = Vector3(charge_end.x, position.y, charge_end.z)
				_smash()
			else:
				position += charge_dir * step
		State.STUCK:
			rig.play("gesture-negative")
			rig.rotation.z = sin(state_time * 14.0) * 0.06
			if state_time > STUCK_TIME[_level_index()]:
				open = false
				rig.rotation.z = 0.0
				_go(State.BACK_OUT)
		State.BACK_OUT:
			rig.play("walk", 0.1, -1.0)
			position -= charge_dir * 2.5 * delta
			if state_time > 0.6:
				_go(State.TROT)


func _go(s: State) -> void:
	state = s
	state_time = 0.0
	_line.visible = s == State.AIM


func _to_hero() -> Vector3:
	var h := hero()
	if h == null:
		return facing
	var to := h.global_position - global_position
	to.y = 0.0
	return to if to.length() > 0.05 else facing


## Turns towards `dir`, `rate` radians a second.
func _face(dir: Vector3, delta: float, rate: float) -> void:
	var want := Vector3(dir.x, 0, dir.z)
	if want.length() < 0.01:
		return
	want = want.normalized()
	var angle := facing.signed_angle_to(want, Vector3.UP)
	facing = facing.rotated(Vector3.UP, clampf(angle, -rate * delta, rate * delta)).normalized()
	rig.rotation.y = atan2(facing.x, facing.z)


## Picks the cake behind the hero and lays the line to it.
func _aim() -> void:
	var to_hero := _to_hero().normalized()
	var best := -1
	var best_dot := -2.0
	for i in cakes.size():
		var c: Vector3 = cakes[i][0]
		var to := c - position
		to.y = 0.0
		var d := to.normalized().dot(to_hero)
		if d > best_dot:
			best_dot = d
			best = i
	charge_cake = best
	var centre: Vector3 = cakes[best][0]
	var radius: float = cakes[best][1]
	var flat := centre - position
	flat.y = 0.0
	charge_dir = flat.normalized()
	# Stop with his snout in the cake and his back end out.
	charge_end = position + charge_dir * maxf(flat.length() - radius - 0.4, 0.5)
	var length := (charge_end - position).length() + 1.0
	var strip := BoxMesh.new()
	strip.size = Vector3(1.7, 0.04, length)
	_line.mesh = strip
	var mid := (position + charge_end) / 2.0 + charge_dir * 0.5
	_line.global_transform = Transform3D(Basis(Vector3.UP, atan2(charge_dir.x, charge_dir.z)), Vector3(mid.x, global_position.y + 0.03, mid.z))


func _smash() -> void:
	open = true
	_go(State.STUCK)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", 0.0, 0.05)
	var arena := level as HogPen
	if arena and charge_cake >= 0:
		arena.wobble_cake(charge_cake)
	if not _said_stuck:
		_said_stuck = true
		level.say("He's stuck in the cake! Jump on his back!")


func _on_touched(body: Node3D) -> void:
	# Stuck in a cake, he's harmless from the side.
	if state == State.STUCK and open and not beaten and body == level.hero:
		var h := level.hero
		var above := _above <= 3 and h.velocity.y < 1.0
		if invulnerable <= 0.0 and (h.is_pounding() or h.is_diving() or above):
			super(body)
		return
	super(body)


func _on_hit() -> void:
	rig.rotation.z = 0.0
	rig.play_once("gesture-negative", 0.1, 1.5)
	_go(State.BACK_OUT)
	state_time = -0.4


## For tests and the HUD: true while the charge line is showing.
func is_aiming() -> bool:
	return state == State.AIM


func is_stuck() -> bool:
	return state == State.STUCK and open
