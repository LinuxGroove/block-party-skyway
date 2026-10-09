extends RefCounted
## Drives the hero along a list of legs, for tests: a stand-in player that
## runs, jumps at set points and steers in the air to land on a spot, so a
## test can finish a course or climb to a star without anyone at the pad.
##
## A leg is a Dictionary:
##   "to":   where to run (a Vector3, or a Callable(play) -> Vector3)
##   "jump": "", "jump", "long", "high" or "double", pressed on arriving
##   "aim":  where to land (a Vector3, or a Callable(play, seconds) -> Vector3
##           given the seconds left in the air, for moving platforms)
##   "when": a Callable(play) -> bool to wait for before going ("to" is then
##           approached slowly and stopped at)
##   "walk": true to walk instead of run
##   "until": a Callable(play) -> bool that ends the leg instead of arriving
##   "wall": true to kick up between two walls until "until" holds

const ARRIVE := 0.35

var legs: Array = []
var leg := 0
var done := false
## Ticks the current leg has run, to give up on a stuck leg.
var leg_ticks := 0
var log_legs := false

var _airborne := false
var _air_ticks := 0
var _jumped := false
var _doubled := false
var _crouch_ticks := 0


func _init(p_legs: Array = []) -> void:
	legs = p_legs


## Fills the hero's input for this tick. Pass as Play.autopilot.
func drive(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if done or leg >= legs.size() or play.run_state != Play.Run.RUNNING:
		done = done or leg >= legs.size()
		return
	if play.speech_open():
		play._next_line()
		return
	if h.is_locked():
		return
	leg_ticks += 1
	var l: Dictionary = legs[leg]
	h.input.jump_held = true
	if l.get("wall", false):
		_wall_climb(play, l)
		return
	if _jumped:
		_fly(play, l)
		return
	var to := _point(l.get("to", h.global_position), play)
	var flat := Vector3(to.x - h.global_position.x, 0, to.z - h.global_position.z)
	var top := Hero.WALK_SPEED if l.get("walk", false) else Hero.RUN_SPEED
	h.input.run = not l.get("walk", false)
	if l.has("until") and not l.has("jump") and (l.until as Callable).call(play):
		_next()
		return
	var waits: bool = l.has("when") or l.get("stop", false)
	if flat.length() > ARRIVE:
		var want := top
		if waits:
			# Arrive at a stop: slow down so the hero halts on the spot.
			want = minf(top, sqrt(2.0 * Hero.GROUND_DECEL * maxf(flat.length() - 0.1, 0.0)))
		h.input.move = flat.normalized() * clampf(want / top, 0.0, 1.0)
		if l.get("jump", "") == "high" and flat.length() < 1.2:
			h.input.crouch = true
		return
	if l.has("when") and not (l.when as Callable).call(play):
		return
	match str(l.get("jump", "")):
		"":
			if not l.has("until"):
				_next()
		"long":
			# Crouch and jump on the same tick, at speed.
			h.input.move = flat.normalized() if flat.length() > 0.05 else h.facing
			h.input.crouch = true
			h.input.jump = true
			_take_off()
		"high":
			h.input.crouch = true
			_crouch_ticks += 1
			if h.horizontal_speed() < 4.0 and _crouch_ticks > 2:
				h.input.jump = true
				_take_off()
		_:
			h.input.move = flat.normalized() if flat.length() > 0.05 else Vector3.ZERO
			h.input.jump = true
			_take_off()


func _take_off() -> void:
	_jumped = true
	_airborne = false
	_air_ticks = 0
	_doubled = false
	_crouch_ticks = 0


## In the air: steer so the hero comes down on the aim point.
func _fly(play: Play, l: Dictionary) -> void:
	var h := play.hero
	var on_floor := h.is_on_floor() and h.state in [Hero.State.GROUND, Hero.State.SLIDE]
	_air_ticks += 1
	if not on_floor:
		_airborne = true
	elif _airborne or _air_ticks > 20:
		_next()
		return
	var kind := str(l.get("jump", "jump"))
	var aim_raw = l.get("aim", l.get("to"))
	var t_land := _time_to_land(h, kind, _aim_y(aim_raw, play))
	var aim: Vector3 = aim_raw.call(play, t_land) if aim_raw is Callable else aim_raw
	if kind == "double" and not _doubled and h.velocity.y < 3.0 and _airborne:
		h.input.jump = true
		_doubled = true
	var flat := Vector3(aim.x - h.global_position.x, 0, aim.z - h.global_position.z)
	var desired := flat / maxf(t_land, 0.05)
	if kind == "double" and not _doubled:
		desired = flat.normalized() * Hero.RUN_SPEED
	var top := maxf(Hero.RUN_SPEED, h.horizontal_speed())
	if kind == "long":
		top = maxf(top, Hero.LONG_JUMP_FORWARD)
	h.input.run = true
	h.input.move = desired / top
	if h.input.move.length() > 1.0:
		h.input.move = h.input.move.normalized()


## Kicks between two walls (a chimney) until `until` holds: jump at the first
## wall, then jump again each time the climb slows on a wall.
func _wall_climb(play: Play, l: Dictionary) -> void:
	var h := play.hero
	if (l.until as Callable).call(play):
		_next()
		return
	var toward: Vector3 = l.get("toward", Vector3.RIGHT)
	match h.state:
		Hero.State.GROUND:
			h.input.move = toward
			if leg_ticks % 20 == 1:
				h.input.jump = true
		Hero.State.AIR:
			# Push at a wall until on it, then let the kicks do the work.
			h.input.move = toward if h.jump_kind != "wall" else Vector3.ZERO
			if h.global_position.y > float(l.get("top", 999.0)):
				h.input.move = l.get("off", Vector3.ZERO)
		Hero.State.WALL:
			if h.velocity.y < 2.0:
				h.input.jump = true


func _next() -> void:
	if log_legs:
		print("  leg %d done in %d ticks" % [leg, leg_ticks])
	leg += 1
	leg_ticks = 0
	_jumped = false
	_airborne = false
	_doubled = false
	_crouch_ticks = 0
	done = leg >= legs.size()


func _point(p, play: Play) -> Vector3:
	return p.call(play) if p is Callable else p


func _aim_y(aim, play: Play) -> float:
	if aim is Callable:
		return (aim.call(play, 0.6) as Vector3).y
	return (aim as Vector3).y


## Seconds until the hero falls back to height `y`, from the jump's gravity.
static func _time_to_land(h: Hero, kind: String, y: float) -> float:
	var g_up := (Hero.LONG_JUMP_GRAVITY if kind == "long" else Hero.GRAVITY) * h.gravity_scale
	var g_down := (Hero.LONG_JUMP_GRAVITY if kind == "long" else Hero.FALL_GRAVITY) * h.gravity_scale
	var vy := h.velocity.y
	var t := 0.0
	var apex := h.global_position.y
	var v0 := 0.0
	if vy > 0.0:
		t = vy / g_up
		apex += vy * vy / (2.0 * g_up)
	else:
		v0 = -vy
	var drop := apex - y
	if drop <= 0.0:
		return maxf(t, 0.05)
	return t + (-v0 + sqrt(v0 * v0 + 2.0 * g_down * drop)) / g_down
