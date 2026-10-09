class_name PiratePolly
extends Boss
## Polly, the parrot captain of Pirate Cove. She flies round her mast flinging
## cannonballs at the deck (each one's landing ring shows as it's thrown, a
## squawk first), then glides down to a spot marked on the deck to reload.
## While she reloads she's open: jump on her. Three hits; she throws more
## at a time, and reloads quicker, after each.

enum State { PERCH, FLY, DESCEND, RELOAD, FLEE, RISE }

## Seconds on her perch before the fight starts.
const PERCH_TIME := 2.0
## Seconds between volleys, and volleys before she lands, by hits taken.
const VOLLEY_GAP := [1.7, 1.4, 1.15]
const VOLLEYS := 3
## Seconds of warning before a volley, and a shell's time in the air.
const WIND_UP := 0.45
const FLIGHT := 1.3
const SHELL_RADIUS := 1.1
## Seconds gliding down, reloading (open) by hits taken, and rising.
const DESCEND_TIME := 1.3
const RELOAD_TIME := [3.0, 2.6, 2.2]
const RISE_TIME := 0.8
## After a hit she flaps off this far along the deck, this quickly, before
## rising: out from under the hero as they bounce.
const FLEE := 3.5
const FLEE_TIME := 0.35

var state := State.PERCH
## The middle of her circle in the air, its size, and her height there.
var center := Vector3.ZERO
var circle := Vector2(4.5, 5.0)
var fly_height := 4.5
## Where she can land (level coordinates), and the deck's bounds for aiming.
var spots: Array[Vector3] = []
var deck := AABB(Vector3(-5, 0, -9.5), Vector3(10, 0, 12.5))
## Shells in the air.
var shells: Array[PirateShell] = []
## Where she's landing, while she glides down or reloads.
var landing := Vector3.ZERO

var _t := 0.0
var _angle := 0.0
var _volleys := 0
var _volley_t := 0.0
var _winding := false
var _from := Vector3.ZERO
var _last_spot := -1
var _told := false
var _flee_to := Vector3.ZERO
var _rig: RigCharacter
var _marker: MeshInstance3D
var _marker_mat: StandardMaterial3D


func _ready() -> void:
	super()
	boss_name = "Polly"
	_rig = RigCharacter.create(Kit.scene("animal-parrot"), 1.0)
	add_child(_rig)
	_rig.play("idle")
	# Lower than her crest, so one jump clears her.
	make_body(Vector3(1.9, 1.3, 1.8))
	_marker_mat = StandardMaterial3D.new()
	_marker_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	_marker_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_marker_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_marker = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.25
	torus.outer_radius = 1.45
	torus.rings = 28
	torus.ring_segments = 4
	_marker.mesh = torus
	_marker.material_override = _marker_mat
	_marker.scale = Vector3(1, 0.3, 1)
	_marker.top_level = true
	_marker.visible = false
	add_child(_marker)


func think(delta: float) -> void:
	_t += delta
	shells = shells.filter(is_instance_valid)
	match state:
		State.PERCH:
			_face(hero().global_position)
			if not _told and time >= 0.5:
				_told = true
				level.say("Polly lands to reload. Jump on her then!")
			if time >= PERCH_TIME:
				_start_flying()
		State.FLY:
			_fly(delta)
		State.DESCEND:
			var u := clampf(_t / DESCEND_TIME, 0.0, 1.0)
			var e := u * u * (3.0 - 2.0 * u)
			position = _from.lerp(landing, e) + Vector3.UP * sin(u * PI) * 0.8
			_face(landing)
			_marker_mat.albedo_color.a = 0.5 + 0.4 * absf(sin(_t * 8.0))
			if u >= 1.0:
				position = landing
				state = State.RELOAD
				_t = 0.0
				open = true
				_rig.play("eat")
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", -4.0, 0.05)
		State.RELOAD:
			_face(hero().global_position)
			_marker_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.45 + 0.4 * absf(sin(_t * 6.0)))
			if _t >= RELOAD_TIME[_hits()]:
				_take_off()
		State.FLEE:
			var u := clampf(_t / FLEE_TIME, 0.0, 1.0)
			position = _from.lerp(_flee_to, 1.0 - (1.0 - u) * (1.0 - u))
			if u >= 1.0:
				state = State.RISE
				_t = 0.0
				_from = position
		State.RISE:
			var u := clampf(_t / RISE_TIME, 0.0, 1.0)
			var to := _circle_point(_angle)
			position = _from.lerp(to, u * u * (3.0 - 2.0 * u))
			if u >= 1.0:
				_start_flying()


## Hits taken so far.
func _hits() -> int:
	return clampi(max_health - health, 0, 2)


func _circle_point(a: float) -> Vector3:
	return center + Vector3(cos(a) * circle.x, fly_height, sin(a) * circle.y)


func _start_flying() -> void:
	state = State.FLY
	_t = 0.0
	_volleys = 0
	_volley_t = 0.0
	_winding = false
	_rig.play("run", 0.15, 1.6)


func _fly(delta: float) -> void:
	_angle += delta * (0.55 + 0.15 * _hits())
	var to := _circle_point(_angle)
	position = position.lerp(to, minf(delta * 3.0, 1.0))
	_face(global_position + Vector3(-sin(_angle) * circle.x, 0, cos(_angle) * circle.y))
	_volley_t += delta
	var gap: float = VOLLEY_GAP[_hits()]
	if not _winding and _volley_t >= gap - WIND_UP:
		# The warning: a squawk and a flap up.
		_winding = true
		_rig.play_once("gesture-negative", 0.1, 1.5)
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/error_004.ogg", -6.0, 0.15)
	if _volley_t >= gap:
		_volley_t = 0.0
		_winding = false
		_volley()
		_volleys += 1
		if _volleys >= VOLLEYS:
			_descend()


## Throws a volley: one shell where the hero stands, more round about them
## after each hit.
func _volley() -> void:
	var h := hero()
	if h == null:
		return
	var at := Vector3(h.global_position.x, h.last_floor_y, h.global_position.z) - level.global_position
	var targets: Array[Vector3] = [at]
	var spin := _angle
	for i in _hits() * 2:
		var a := spin + TAU * i / maxf(_hits() * 2, 1)
		targets.append(at + Vector3(cos(a), 0, sin(a)) * 2.8)
	for to in targets:
		to.x = clampf(to.x, deck.position.x, deck.end.x)
		to.z = clampf(to.z, deck.position.z, deck.end.z)
		var s := PirateShell.make(position + Vector3.UP * 0.8, FLIGHT, SHELL_RADIUS)
		s.height = 3.0
		level.add(s, to)
		shells.append(s)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -2.0, 0.1)


## Picks a spot to land: not the last one, and not right on the hero.
func _descend() -> void:
	var h := hero().global_position - level.global_position
	var best := -1
	var best_d := -1.0
	for i in spots.size():
		if i == _last_spot:
			continue
		var d := Vector2(spots[i].x - h.x, spots[i].z - h.z).length()
		# The nearest spot at least 3.5 m away, so she's worth chasing.
		var score := -absf(d - 5.0) if d >= 3.5 else -100.0 + d
		if best < 0 or score > best_d:
			best = i
			best_d = score
	_last_spot = best
	landing = spots[best]
	_from = position
	state = State.DESCEND
	_t = 0.0
	_marker.global_position = level.global_position + landing + Vector3.UP * 0.08
	_marker_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
	_marker.visible = true
	_rig.play("run", 0.15, 1.0)


func _take_off() -> void:
	open = false
	state = State.RISE
	_t = 0.0
	_from = position
	# Up to the nearest point of her circle.
	_angle = atan2((position.z - center.z) / circle.y, (position.x - center.x) / circle.x)
	_marker.visible = false
	_rig.play("run", 0.15, 1.6)


func _on_hit() -> void:
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/error_004.ogg", 0.0, 0.1)
	_take_off()
	# Out along the deck, away from the middle, then up.
	var out := position - center
	out.y = 0.0
	out = out.normalized() if out.length() > 0.1 else Vector3.RIGHT
	_flee_to = position + out * FLEE + Vector3.UP * 1.0
	_angle = atan2(out.z, out.x)
	state = State.FLEE


## No touching while she flaps off after a hit: the hero is still bouncing
## up off her.
func _on_touched(body: Node3D) -> void:
	if state == State.FLEE:
		return
	super(body)


func _on_beaten() -> void:
	open = false
	_marker.visible = false
	for s in shells:
		if is_instance_valid(s):
			s.queue_free()
	super()


## Turns her to look at `at` (level or world, flat).
func _face(at: Vector3) -> void:
	var d := at - global_position
	d.y = 0.0
	if d.length() > 0.05:
		_rig.rotation.y = lerp_angle(_rig.rotation.y, atan2(d.x, d.z), 0.15)
