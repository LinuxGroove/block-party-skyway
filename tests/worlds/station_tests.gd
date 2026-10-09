extends RefCounted
## Star Station's tests, run by tests/run_tests.gd: the island's stars,
## King Thud, and the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner

var _thud: StationKingThud
var _attack := 0
var _comet: StationRunaway


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"moonhop":
			return _moonhop()
		"laserhall":
			return _laserhall()
		"ventclimb":
			return _ventclimb()
		"orbitring":
			return _orbitring()
	return []


## Star Station: King Thud's door shut at first, Sprocket's fuses, the
## Star Dust Rush, the comms mast, the hidden hangar, catching Comet, the
## strong crate's gem, the moon long jump to the far asteroid, the door
## opening with five stars; then King Thud.
func run() -> void:
	await _island()
	await _boss()


func _island() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("station", "adventure")
	await t._ticks(10)
	var isle := play.level as StationIsle
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Star Station")
	t.check(isle.title == "Star Station" and play.hud.visible, "the HUD shows")
	# King Thud's door is shut to start with.
	var door := isle.boss_door
	t.check(not door.is_open(), "King Thud's door is shut at first")
	h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == door, "King Thud's door can be tried")
	door.talk()
	t.check(not play._leaving, "a shut door doesn't open")
	# Sprocket's fuses: touch each one and it zips home.
	h.place(isle.sprocket.global_position + Vector3(0, 0.1, 1.0))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.sprocket, "Sprocket is there to talk to")
	isle.sprocket.talk()
	t.check(play.speech_open(), "Sprocket explains about his fuses")
	while play.speech_open():
		play._next_line()
	for f in isle.fuses:
		h.place(f.global_position + Vector3.UP * 0.1)
		await t._until(func(): return f.is_home, 3.0)
	t.check(await t._until(func(): return isle.fuses_home == 3, 4.0), "all three fuses go home")
	t.check(play.speech_open(), "Sprocket thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	await _take_star(play, "station/fuses", "the fuses' star is found")
	# The Star Dust Rush: step on the button, grab the eight coins.
	h.place(isle.dust.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.dust.time_left > 0.0, 1.0), "the button starts the Star Dust Rush")
	for p in isle.dust.coins.duplicate():
		if is_instance_valid(p):
			h.place(p.global_position - Vector3.UP * 0.2)
			await t._ticks(6)
	await _take_star(play, "station/dust", "eight silver coins give a star")
	# The comms mast: ride the vent to the balcony, then kick up the gap.
	h.place(Vector3(20, 0.05, -2.5), Vector3.FORWARD)
	t.check(await t._pilot(play, [
		{"to": Vector3(20, 0, -3.6), "walk": true},
		{"to": Vector3(20, 0, -6), "walk": true, "until": func(_p): return h.global_position.y > 4.2},
		{"to": Vector3(23.5, 5.5, -6), "until": func(_p): return h.is_on_floor() and h.global_position.y > 5.3},
		{"to": Vector3(25.5, 5.5, -6.2), "walk": true},
		{"to": Vector3(25.5, 5.5, -8.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 10.3, "off": Vector3.LEFT,
			"until": func(_p): return Progress.has_star("station/mast")},
	], 30.0), "the vent and the wall kicks reach the top of the mast")
	t.check(Progress.has_star("station/mast"), "the mast's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The hidden hangar: drop down the hatch behind the cargo, find the star,
	# and ride the vent back up.
	h.place(Vector3(13.2, 0.05, 11), Vector3.LEFT)
	await t._ticks(4)
	t.check(await t._pilot(play, [
		{"to": Vector3(11, 0, 11), "walk": true, "until": func(_p): return h.global_position.y < -6.5 and h.is_on_floor()},
		{"to": Vector3(6, -7, 10.5), "walk": true, "until": func(_p): return Progress.has_star("station/hangar")},
	], 15.0), "the hatch drops into the hangar, and its star is there")
	await t._until(func(): return not h.is_locked(), 3.0)
	t.check(await t._pilot(play, [
		{"to": Vector3(13, -7, 17), "walk": true, "until": func(_p): return h.global_position.y > 0.6},
		{"to": Vector3(10, 0, 15), "until": func(_p): return h.is_on_floor() and h.global_position.y > -0.1},
	], 15.0), "the vent blows the hero back up to the deck")
	# Comet: run after her and corner her.
	_comet = isle.comet
	h.place(Vector3(-15, 0.05, 18), Vector3.LEFT)
	await t._ticks(4)
	play.autopilot = _chase
	t.check(await t._until(func(): return _comet.is_caught, 25.0), "running catches Comet (she's at %s)" % _comet.global_position)
	play.autopilot = t._hands_off
	await t._until(func(): return play.speech_open(), 2.0)
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	await _take_star(play, "station/comet", "Comet gives a star")
	t.check(door.is_open(), "five stars open King Thud's door")
	# The strong crate by King Thud's door: a ground pound lets out a gem.
	var crate: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "gem:station/gem_crate":
			crate = b
	t.check(crate != null, "a strong crate stands by King Thud's door")
	if crate:
		h.place(crate.global_position + Vector3.UP * 3.0)
		await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		t.check(not is_instance_valid(crate), "a ground pound breaks the strong crate")
		t.check(await t._until(func(): return Progress.has_gem("station/gem_crate"), 3.0), "the crate's gem is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# Moon gravity: a long jump from the moon deck reaches the far asteroid.
	h.place(Vector3(-20, -0.95, -4), Vector3.LEFT)
	await t._ticks(4)
	t.check(h.gravity_scale < 0.6, "the moon deck has moon gravity (%.2f)" % h.gravity_scale)
	t.check(await t._pilot(play, [
		{"to": Vector3(-33.2, -1, -4), "jump": "long", "aim": Vector3(-46.5, 0.5, -4)},
		{"to": Vector3(-46.5, 0.5, -4), "walk": true, "until": func(_p): return Progress.has_gem("station/gem_asteroid")},
	], 15.0), "a moon long jump reaches the far asteroid's gem")
	h.place(Vector3(0, 0.05, 10), Vector3.FORWARD)
	await t._ticks(6)
	t.check(is_equal_approx(h.gravity_scale, 1.0), "gravity is normal off the moon deck")
	var left := 0
	for id in Worlds.star_ids("station"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("station"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(isle.secrets_left() == left, "secrets left counts what's still hidden (%d)" % isle.secrets_left())
	t._fast(false)
	await t._free(play)


## Collects a star a level just handed out (walks the hero into it).
func _take_star(play: Play, id: String, what: String) -> void:
	var star := t._find_star(play.level, id)
	t.check(star != null, what)
	if star:
		play.hero.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star(id), 2.0), "%s is collected" % id)
	await t._until(func(): return not play.hero.is_locked(), 3.0)


## Runs at Comet.
func _chase(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if h.is_locked():
		return
	var to := _comet.global_position - h.global_position
	to.y = 0.0
	h.input.move = to.normalized() if to.length() > 0.05 else Vector3.ZERO
	h.input.run = true


# --- King Thud ---------------------------------------------------------------

## King Thud: the hero keeps moving round the deck, out of his way, and
## when he's dizzy after a slam runs in, double jumps on top and pounds.
func _boss() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("king_thud", "adventure")
	await t._ticks(10)
	var arena := play.level as ThudThrone
	_thud = arena.boss as StationKingThud
	t.check(_thud != null and _thud.health == 3, "King Thud waits in his throne room")
	var hurts := [0]
	arena.hurt.connect(func(_f): hurts[0] += 1)
	var shown := [false]
	arena.message.connect(func(_m): shown[0] = true)
	_attack = 0
	play.autopilot = _fight
	var beaten := await t._until(func(): return _thud.beaten, 120.0)
	t.check(shown[0], "King Thud says what to do")
	t.check(beaten, "stomping King Thud's lid three times beats him (health %d)" % _thud.health)
	print("  King Thud: beaten with %d hits taken" % hurts[0])
	play.autopilot = t._hands_off
	await t._ticks(30)
	var star := t._find_star(arena, "station/boss")
	t.check(star != null, "King Thud drops his star")
	if star:
		var h := play.hero
		h.place(Vector3(star.global_position.x, 0.05, star.global_position.z + 3.0), Vector3.FORWARD)
		t.check(await t._pilot(play, [{"to": star.global_position, "walk": true, "until": func(_p): return Progress.has_star("station/boss")}], 6.0), "walking into the star collects it")
	# Falling off the deck comes back at the flag.
	await t._until(func(): return not play.hero.is_locked() or play._leaving, 3.0)
	t._fast(false)
	await t._free(play)
	Progress.wipe()


## The fight, one tick at a time: circle the deck away from King Thud and
## his shadow; when he's dizzy, run in, double jump onto him and pound.
func _fight(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if play.speech_open():
		play._next_line()
		return
	if h.is_locked() or _thud.beaten:
		return
	h.input.jump_held = true
	var me := Vector3(h.global_position.x, 0, h.global_position.z)
	var him := Vector3(_thud.global_position.x, 0, _thud.global_position.z)
	var to_him := him - me
	if _thud.is_dazed() and _thud.invulnerable <= 0.0 and _thud.step_time < StationKingThud.DIZZY[_thud.rage] - 0.3:
		h.input.run = true
		match _attack:
			0:
				# Line up a few metres out, then jump at him.
				if to_him.length() > 3.4:
					h.input.move = to_him.normalized()
				elif h.is_on_floor():
					h.input.move = to_him.normalized()
					h.input.jump = true
					_attack = 1
				else:
					h.input.move = to_him.normalized()
			1:
				h.input.move = to_him.normalized() * clampf(to_him.length() / 1.5, 0.0, 1.0)
				if h.velocity.y < 2.0 and h.can_double and not h.is_on_floor():
					h.input.jump = true
				var top := _thud.global_position.y + StationKingThud.SIZE.y
				if to_him.length() < 0.8 and h.global_position.y > top + 0.25:
					h.input.crouch_pressed = true
					_attack = 2
				elif h.is_on_floor() and h.global_position.y < top - 0.5 and h.velocity.y <= 0.0:
					_attack = 0
			2:
				if h.is_on_floor() or h.state == Hero.State.AIR and h.velocity.y > 5.0:
					_attack = 0
		return
	_attack = 0
	# Keep moving round the deck, away from him (or from his shadow).
	var danger := Vector3(_thud.target.x, 0, _thud.target.z) if _thud.is_slamming() else him
	var center := Vector3(0, 0, -1)
	var out := me - center
	var r := out.length()
	var tangent := Vector3(-out.z, 0, out.x).normalized() if r > 0.1 else Vector3.RIGHT
	var want := tangent + out.normalized() * clampf((6.0 - r) * 0.5, -1.0, 1.0)
	var away := me - danger
	if away.length() < 5.0:
		want += away.normalized() * (5.0 - away.length()) * 0.8
	h.input.move = want.normalized()
	h.input.run = true


# --- Courses -----------------------------------------------------------------

## A course's moving platforms, nearest the start first.
static func _movers(play: Play) -> Array:
	var list := play.level.find_children("*", "MovingPlatform", true, false)
	list.sort_custom(func(a, b): return a.position.z > b.position.z or (a.position.z == b.position.z and a.position.x > b.position.x))
	return list


## Where moving platform `i` will be `ahead` seconds from now.
static func _mover_at(play: Play, i: int, ahead: float) -> Vector3:
	var p: MovingPlatform = _movers(play)[i]
	return p._start + p.offset_at(p._t + ahead)


## Moon Hop: hop the craters and the falling rocks, double jump the wall,
## long jump the gap, float over the spinner and ride the lifts west.
func _moonhop() -> Array:
	return [
		{"to": Vector3(0, 0, -3.5), "jump": "jump", "aim": Vector3(0, 0.5, -10.6)},
		{"to": Vector3(0.6, 0.5, -11.5), "jump": "jump", "aim": Vector3(2.8, 1.5, -17.6)},
		{"to": Vector3(2.4, 1.5, -19.4), "jump": "jump", "aim": Vector3(-1, 3.0, -25.6)},
		{"to": Vector3(-1, 3.0, -27.5), "jump": "jump", "aim": Vector3(-1, 3.0, -32.3)},
		{"to": Vector3(-1, 3.0, -33.0), "jump": "jump", "aim": Vector3(-1, 3.0, -36.8)},
		{"to": Vector3(-1, 3.0, -37.5), "jump": "jump", "aim": Vector3(-1, 3.0, -41.3)},
		{"to": Vector3(-1, 3.0, -42.0), "jump": "jump", "aim": Vector3(0, 3.0, -47.0)},
		{"to": Vector3(0, 3.0, -47.5), "jump": "double", "aim": Vector3(0, 7.5, -55.0)},
		{"to": Vector3(0.5, 7.5, -59.5), "jump": "long", "aim": Vector3(1.5, 6.0, -75.0)},
		{"to": Vector3(2.0, 6.0, -77.2), "jump": "jump", "aim": Vector3(2.0, 6.0, -84.5)},
		{"to": Vector3(-3.4, 6.0, -86), "jump": "jump", "aim": func(p, s): return _mover_at(p, 0, s)},
		{"to": func(p): return _mover_at(p, 0, 0.0) + Vector3(-0.6, 0, 0), "jump": "jump", "aim": func(p, s): return _mover_at(p, 1, s)},
		{"to": func(p): return _mover_at(p, 1, 0.0) + Vector3(-0.6, 0, 0), "jump": "jump", "aim": func(p, s): return _mover_at(p, 2, s)},
		{"to": func(p): return _mover_at(p, 2, 0.0) + Vector3(-0.6, 0, 0), "jump": "jump", "aim": Vector3(-26.5, 6.0, -86)},
		{"to": Vector3(-30.0, 6.0, -86)},
	]


## Things of a class in a course, along the way: by x, then north first.
static func _along(play: Play, cls: String) -> Array:
	var list := play.level.find_children("*", cls, true, false)
	list.sort_custom(func(a, b): return a.position.x < b.position.x - 0.1 or (absf(a.position.x - b.position.x) <= 0.1 and a.position.z > b.position.z))
	return list


static func _gate(play: Play, i: int) -> StationLaserGate:
	return _along(play, "StationLaserGate")[i]


## True if crusher `i` stays up (out of the way) from `from` to `to`
## seconds from now.
static func _crusher_up(play: Play, i: int, from: float, to: float) -> bool:
	var c: Crusher = _along(play, "Crusher")[i]
	var s := from
	while s <= to:
		if c.offset_at(c._t + s) < 1.2:
			return false
		s += 0.05
	return true


## Laser Hall: run the gates' wave, jump the turrets' bolts, wait for the
## crushers, round the corner, run the next gates and long jump the spikes.
func _laserhall() -> Array:
	return [
		{"to": Vector3(0.5, 0, -5.6), "when": func(p): return not _gate(p, 0).is_on() and _gate(p, 0).time_to_on() > 1.3},
		{"to": Vector3(0.5, 0, -19.5)},
		{"to": Vector3(0.5, 0, -20.8), "jump": "jump", "aim": Vector3(0.5, 0, -25.0)},
		{"to": Vector3(0.5, 0, -25.2), "jump": "jump", "aim": Vector3(0.5, 0, -29.4)},
		{"to": Vector3(0.5, 0, -30.6), "when": func(p): return _crusher_up(p, 0, 0.15, 0.85) and _crusher_up(p, 1, 0.55, 1.35)},
		{"to": Vector3(0.0, 0, -43.0)},
		{"to": Vector3(6.2, 0, -43), "when": func(p): return not _gate(p, 3).is_on() and _gate(p, 3).time_to_on() > 1.1},
		{"to": Vector3(18.3, 0, -43), "jump": "long", "aim": Vector3(26.5, 0, -43)},
		{"to": Vector3(37.5, 0, -43)},
	]


## Vent Climb: ride the vent, the shuttle and the second vent, kick up
## between the walls, and hop the falling platforms west.
func _ventclimb() -> Array:
	return [
		{"to": Vector3(0, 0, -5.6), "stop": true},
		{"to": Vector3(0, 0, -8.4), "walk": true, "until": func(p): return p.hero.global_position.y > 6.3},
		{"to": Vector3(0, 6, -12.5), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 5.8},
		{"to": Vector3(0, 6, -15.4), "when": func(p): return _mover_at(p, 0, 0.6).z > -18.4},
		{"to": Vector3(0, 6, -15.6), "jump": "jump", "aim": func(p, s): return _mover_at(p, 0, s)},
		{"to": func(p): return _mover_at(p, 0, 0.0), "until": func(p): return _mover_at(p, 0, 0.0).z < -21.6},
		{"to": func(p): return _mover_at(p, 0, 0.0) + Vector3(0, 0, -0.7), "jump": "jump", "aim": Vector3(0, 6, -25.6)},
		{"to": Vector3(0, 6, -27.6), "stop": true},
		{"to": Vector3(0, 6, -30.4), "walk": true, "until": func(p): return p.hero.global_position.y > 11.3},
		{"to": Vector3(0, 11, -34), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 10.8},
		{"to": Vector3(0.5, 11, -37.6), "walk": true},
		{"to": Vector3(0.5, 11, -40), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 16.3, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 15.9},
		{"to": Vector3(-3, 16, -44)},
		{"to": Vector3(-6.6, 16, -44), "jump": "jump", "aim": Vector3(-9.5, 16, -44)},
		{"to": Vector3(-10.0, 16, -44), "jump": "jump", "aim": Vector3(-13.5, 16, -44)},
		{"to": Vector3(-14.0, 16, -44), "jump": "jump", "aim": Vector3(-17.5, 16, -44)},
		{"to": Vector3(-18.0, 16, -44), "jump": "jump", "aim": Vector3(-20.5, 16, -44)},
		{"to": Vector3(-24, 16, -44)},
	]


## Orbit Ring's platforms circling the hub at `hub`.
static func _orbiters(play: Play, hub: Vector3) -> Array:
	var list := []
	for o in play.level.find_children("*", "StationOrbiter", true, false):
		if (o as StationOrbiter)._center.distance_to(hub) < 0.1:
			list.append(o)
	return list


## Where the hub's platform nearest `spot` in `ahead` seconds will be then.
static func _orbit_at(play: Play, hub: Vector3, spot: Vector3, ahead: float) -> Vector3:
	var best := Vector3.INF
	for o in _orbiters(play, hub):
		var at: Vector3 = (o as StationOrbiter).ahead(ahead)
		if at.distance_to(spot) < best.distance_to(spot):
			best = at
	return best


## True if one of the hub's platforms will be within `near` of `spot` in
## `ahead` seconds.
static func _orbit_due(play: Play, hub: Vector3, spot: Vector3, ahead: float, near := 0.4) -> bool:
	return _orbit_at(play, hub, spot, ahead).distance_to(spot) < near


## Where the hub's platform the hero is riding is now.
static func _riding(play: Play, hub: Vector3) -> Vector3:
	return _orbit_at(play, hub, play.hero.global_position, 0.0)


## Orbit Ring: ride the ring across, jump the turret's bolts, ride the wheel
## up and jump off at the top, cross the gears where they meet, and hop the
## falling platforms to the flag.
func _orbitring() -> Array:
	var ring := OrbitRing.RING
	var wheel := OrbitRing.WHEEL
	var gear_a := OrbitRing.GEAR_A
	var gear_b := OrbitRing.GEAR_B
	var ring_on := ring + Vector3(0, 0, 4)
	var wheel_on := wheel + Vector3(0, -3.5, 0)
	var a_on := gear_a + Vector3(0, 0, 4)
	var b_on := gear_b + Vector3(0, 0, 4)
	return [
		{"to": Vector3(0, 0, -3.6), "when": func(p): return _orbit_due(p, ring, ring_on, 0.62, 0.6)},
		{"to": Vector3(0, 0, -3.6), "jump": "jump", "aim": func(p, s): return _orbit_at(p, ring, ring_on, s)},
		{"to": func(p): return _riding(p, ring) + Vector3(0, 0, -1.1),
			"until": func(p): return _riding(p, ring).z < ring.z - 3.8 and _riding(p, ring).x > -0.7},
		{"to": func(p): return _riding(p, ring) + Vector3(0, 0, -1.1), "jump": "jump", "aim": Vector3(0, 1, -19.4)},
		{"to": Vector3(0, 1, -19.7), "jump": "jump", "aim": Vector3(0, 1, -22.8)},
		{"to": Vector3(0, 1, -23.6), "when": func(p): return _orbit_due(p, wheel, wheel_on, 0.62, 0.5)},
		{"to": Vector3(0, 1, -23.6), "jump": "jump", "aim": func(p, s): return _orbit_at(p, wheel, wheel_on, s)},
		{"to": func(p): return _riding(p, wheel) + Vector3(0, 0, -0.7),
			"until": func(p): return _riding(p, wheel).y > wheel.y + 3.3 and _riding(p, wheel).x < 0.6},
		{"to": func(p): return _riding(p, wheel) + Vector3(0, 0, -0.7), "jump": "jump", "aim": Vector3(0, 7.5, -30.2)},
		{"to": Vector3(0, 7.5, -35.6), "when": func(p): return _orbit_due(p, gear_a, a_on, 0.5, 0.5)},
		{"to": Vector3(0, 7.5, -35.6), "jump": "jump", "aim": func(p, s): return _orbit_at(p, gear_a, a_on, s)},
		{"to": func(p): return _riding(p, gear_a) + Vector3(0, 0, -0.7),
			"until": func(p): return _riding(p, gear_a).z < gear_a.z - 3.8 and _riding(p, gear_a).x > -0.5},
		{"to": func(p): return _riding(p, gear_a) + Vector3(0, 0, -0.7), "jump": "jump",
			"aim": func(p, s): return _orbit_at(p, gear_b, b_on, s)},
		{"to": func(p): return _riding(p, gear_b) + Vector3(0, 0, -0.7),
			"until": func(p): return _riding(p, gear_b).z < gear_b.z - 3.8 and _riding(p, gear_b).x < 0.5},
		{"to": func(p): return _riding(p, gear_b) + Vector3(0, 0, -0.7), "jump": "jump", "aim": Vector3(0, 8.5, -59.0)},
		{"to": Vector3(0, 8.5, -59.4), "jump": "jump", "aim": Vector3(0, 8.5, -62.5)},
		{"to": Vector3(0, 8.5, -62.8), "jump": "jump", "aim": Vector3(0, 8.5, -66.2)},
		{"to": Vector3(0, 8.5, -69)},
	]
