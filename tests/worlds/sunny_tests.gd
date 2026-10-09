extends RefCounted
## Sunny Isles' tests, run by tests/run_tests.gd: the island's stars and
## the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"sawmill":
			return _sawmill()
		"crabshore":
			return _crabshore()
		"windmill":
			return _windmill()
		"treetop":
			return _treetop()
	return []


## Sunny Isles: Pebble's chicks, the silver rush (which brings the Skyway
## to Lookout Islet), the ledge under the cliff, the old tower, the crabs'
## crate, the course doors and falling off.
func run() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("sunny", "adventure")
	await t._ticks(10)
	var isle := play.level as SunnyIsle
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Sunny Isles")
	t.check(not isle.bridge.shown, "the Skyway is hidden at first")
	t.check(play.hud.visible, "the HUD shows")
	# Pebble's chicks: touch each one and it hops home.
	h.place(isle.pebble.global_position + Vector3(1.0, 0.1, 0))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.pebble, "Pebble is there to talk to")
	isle.pebble.talk()
	t.check(play.speech_open(), "Pebble explains about her chicks")
	while play.speech_open():
		play._next_line()
	for c in isle.chicks:
		h.place(c.global_position + Vector3.UP * 0.1)
		await t._until(func(): return c.is_home, 2.0)
	t.check(await t._until(func(): return isle.chicks_home == 3, 3.0), "all three chicks go home")
	t.check(play.speech_open(), "Pebble thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	var star := t._find_star(isle, "sunny/chicks")
	t.check(star != null, "Pebble gives a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("sunny/chicks"), 2.0), "the chicks' star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# Silver rush: step on the button, grab the eight coins.
	h.place(isle.silver.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.silver.time_left > 0.0, 1.0), "the button starts the silver rush")
	for p in isle.silver.coins.duplicate():
		if is_instance_valid(p):
			h.place(p.global_position - Vector3.UP * 0.2)
			await t._ticks(6)
	star = t._find_star(isle, "sunny/silver")
	t.check(star != null, "eight silver coins give a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("sunny/silver"), 2.0), "the silver star is found")
	t.check(isle.bridge.shown, "two stars bring the Skyway back")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The secret ledge: walk off the north cliff, then the spring goes back up.
	var pilot := CoursePilot.new([
		{"to": Vector3(4.5, 2, -21.0), "walk": true},
		{"to": Vector3(4.5, -1.5, -24.6), "walk": true, "until": func(_p): return Progress.has_star("sunny/ledge")},
		{"to": Vector3(2.7, -1.5, -23.6), "walk": true, "until": func(_p): return h.velocity.y > 10.0},
		{"to": Vector3(2.7, 2, -20.5), "until": func(_p): return h.is_on_floor() and h.global_position.y > 1.9},
	])
	h.place(Vector3(4.5, 2.05, -19.0), Vector3.FORWARD)
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return pilot.done, 20.0), "the ledge under the cliff has a star, and a spring back up (stuck at leg %d, %s)" % [pilot.leg, h.global_position])
	t.check(Progress.has_star("sunny/ledge"), "the ledge star is found")
	# The old tower: kick up between the tower and the wall beside it.
	pilot = CoursePilot.new([
		{"to": Vector3(15.5, 0, -3.0), "walk": true},
		{"to": Vector3(15.5, 0, -5.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 7.3, "off": Vector3.LEFT,
			"until": func(_p): return Progress.has_star("sunny/tower")},
	])
	h.place(Vector3(15.5, 0.05, -1.5), Vector3.FORWARD)
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return pilot.done, 20.0), "the tower can be climbed for its star (at %s)" % h.global_position)
	play.autopilot = t._hands_off
	await t._until(func(): return not h.is_locked(), 3.0)
	# Lookout Islet, across the Skyway: walk over, pound the strong crate.
	pilot = CoursePilot.new([
		{"to": Vector3(12.5, 0, 8.6)},
		{"to": Vector3(23.5, 0, 8.6)},
	])
	h.place(Vector3(9, 0.05, 8.6), Vector3.RIGHT)
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return pilot.done, 15.0), "the Skyway reaches Lookout Islet (at %s)" % h.global_position)
	play.autopilot = t._hands_off
	var crate: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "star:sunny/crates":
			crate = b
	t.check(crate != null, "Lookout Islet has the strong crate")
	if crate:
		var crate_at := crate.global_position
		h.place(crate_at + Vector3.UP * 3.0)
		await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		t.check(not is_instance_valid(crate), "a ground pound breaks the strong crate")
		t.check(await t._until(func(): return Progress.has_star("sunny/crates"), 3.0), "the crate's star is found")
	# Each course door can be used from in front of it.
	await t._until(func(): return not h.is_locked(), 3.0)
	for d in isle.find_children("*", "CourseDoor", true, false):
		var door := d as CourseDoor
		if door is BossDoor:
			continue
		h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
		await t._ticks(6)
		t.check(h.is_on_floor() and isle.nearest_talker() == door, "the door to %s can be used" % door.course_id)
	var left := 0
	for id in Worlds.star_ids("sunny"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("sunny"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(isle.secrets_left() == left, "secrets left counts what's still hidden (%d)" % isle.secrets_left())
	# Falling off costs a heart and comes back at the last flag.
	play.hearts = Play.MAX_HEARTS
	var hearts := play.hearts
	h.place(Vector3(0, -20, 40))
	await t._ticks(3)
	t.check(h.global_position.y > -2.0 and play.hearts == hearts - 1, "falling off costs a heart and comes back")
	t._fast(false)
	await t._free(play)
	await _boss()


# --- Captain Pinch -----------------------------------------------------------

## The rock the fight's stand-in player is luring Captain Pinch into, and
## which way it steps aside from the rush he's locked on to (0 for none).
var _rock := -1
var _dodge := 0.0


## Captain Pinch: his door on the beach stays shut until five Sunny stars
## are found, and the hero can beat him by luring him into the rocks and
## jumping on him while he's dizzy (driven by _fight()), for his star.
func _boss() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("sunny", "adventure")
	await t._ticks(6)
	var door: BossDoor = null
	for d in play.level.find_children("*", "BossDoor", true, false):
		door = d
	t.check(door != null and not door.is_open(), "Captain Pinch's door is shut at first")
	if door:
		play.hero.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
		await t._ticks(6)
		t.check(play.level.nearest_talker() == door, "Captain Pinch's door is on the beach, and can be tried")
		door.talk()
		t.check(not play._leaving, "the shut door doesn't let you in")
	await t._free(play)
	for id in ["sunny/sawmill", "sunny/crabshore", "sunny/windmill", "sunny/treetop"]:
		Progress.add_star(id)
	play = t._make_play("sunny", "adventure")
	await t._ticks(6)
	for d in play.level.find_children("*", "BossDoor", true, false):
		door = d
	t.check(not door.is_open(), "four stars aren't enough")
	await t._free(play)
	Progress.add_star("sunny/tower")
	play = t._make_play("sunny", "adventure")
	await t._ticks(6)
	for d in play.level.find_children("*", "BossDoor", true, false):
		door = d
	t.check(door.is_open() and door.talk_text() == "Face Captain Pinch", "five stars open Captain Pinch's door")
	await t._free(play)
	# The fight.
	play = t._make_play("pinch", "adventure")
	await t._ticks(6)
	var arena := play.level as SunnyPinchArena
	var pinch := arena.boss as SunnyPinch
	t.check(play.hero.is_on_floor(), "the hero lands on Captain Pinch's sand bar")
	t.check(pinch != null and pinch.health == 3, "Captain Pinch has three hearts")
	var hits := [0]
	pinch.health_changed.connect(func(_h, _m): hits[0] += 1)
	var dizzy := [false]
	_rock = -1
	play.autopilot = _fight
	t.check(await t._until(func():
		if pinch.act == SunnyPinch.Act.SCUTTLE or pinch.act == SunnyPinch.Act.CHARGE:
			# A rush is only ever a hit while he's dizzy.
			dizzy[0] = dizzy[0] or pinch.open
		return pinch.beaten, 120.0), "the hero beats Captain Pinch (%d hits, health %d)" % [hits[0], pinch.health])
	t.check(not dizzy[0], "he's only open to a hit while dizzy")
	t.check(pinch.dizzy_count >= 3, "he goes dizzy charging into the rocks (%d times)" % pinch.dizzy_count)
	play.autopilot = t._hands_off
	var star := t._find_star(arena, "sunny/boss")
	t.check(star != null, "beating him drops his star")
	if star:
		await t._until(func(): return not play.hero.is_locked(), 3.0)
		play.hero.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("sunny/boss"), 2.0), "Captain Pinch's star is found")
	t.check(Worlds.is_open("frosty"), "beating Captain Pinch opens Frosty Peaks")
	# Knocked into the sea, the hero comes back by the way in.
	var hearts := play.hearts
	play.hero.place(Vector3(0, 0.5, 16))
	await t._until(func(): return play.hero.global_position.z < 12.0, 3.0)
	t.check(play.hero.global_position.distance_to(arena.spawn) < 3.0, "falling in the sea comes back at the arena's flag")
	t._fast(false)
	await t._free(play)


## A stand-in player for the fight: wait between Captain Pinch and a rock,
## step aside once he's locked on to a rush, and while he's dizzy jump on
## him with a ground pound.
func _fight(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if play.speech_open():
		play._next_line()
		return
	var arena := play.level as SunnyPinchArena
	var pinch := arena.boss as SunnyPinch
	if h.is_locked() or pinch.beaten:
		return
	h.input.run = true
	h.input.jump_held = true
	var to := pinch.global_position - h.global_position
	to.y = 0.0
	if pinch.act == SunnyPinch.Act.DIZZY:
		if not h.is_on_floor():
			# Over him, then pound.
			h.input.move = to.normalized() * minf(1.0, to.length())
			if to.length() < 1.0 and h.global_position.y > pinch.global_position.y + 1.6:
				h.input.crouch_pressed = true
		elif to.length() < 2.0:
			h.input.move = -to.normalized()
		else:
			h.input.move = to.normalized()
			h.input.jump = to.length() < 3.4
		return
	if not h.is_on_floor():
		return
	if pinch.locked():
		# Out of his way, if he's coming this way: the side the hero is
		# already on, or else the side nearer the middle.
		var side := pinch.dir.cross(Vector3.UP).normalized()
		var rel := h.global_position - pinch.global_position
		rel.y = 0.0
		var lat := rel.dot(side)
		if _dodge == 0.0:
			_dodge = signf(lat) if absf(lat) > 0.3 else (1.0 if side.dot(-h.global_position) >= 0.0 else -1.0)
		if rel.dot(pinch.dir) > -1.0 and lat * _dodge < 2.8:
			h.input.move = side * _dodge
		return
	_dodge = 0.0
	# Between him and the rock furthest from him.
	if _rock < 0 or pinch.global_position.distance_to(arena.rock_spots[_rock]) < 6.0:
		var best := 0.0
		for i in arena.rock_spots.size():
			var d := pinch.global_position.distance_to(arena.rock_spots[i])
			if d > best:
				best = d
				_rock = i
	var rock: Vector3 = arena.rock_spots[_rock]
	var lure := rock + (pinch.global_position - rock).normalized() * 3.2
	lure.y = h.global_position.y
	var go := lure - h.global_position
	if go.length() > 0.3:
		h.input.move = go.normalized() * clampf(go.length() / 1.5, 0.3, 1.0)


# --- Saw Mill Sprint ---------------------------------------------------------

## The sliding platforms, nearest the start first.
static func _platforms(play: Play) -> Array:
	var list := play.level.find_children("*", "MovingPlatform", true, false)
	list.sort_custom(func(a, b): return a.position.z > b.position.z)
	return list


static func _plat_at(play: Play, i: int, ahead: float) -> Vector3:
	var p: MovingPlatform = _platforms(play)[i]
	return p._start + p.offset_at(p._t + ahead)


## The pilot's way through Saw Mill Sprint: hop the stones, jump each saw
## and the spikes, ride the platforms, double jump the shelf, long jump the
## gap and the conveyor, and run to the flag.
func _sawmill() -> Array:
	return [
		{"to": Vector3(0, 0, -5.6), "jump": "jump", "aim": Vector3(0, 0.5, -8.7)},
		{"to": Vector3(-0.5, 0.5, -9.6), "jump": "jump", "aim": Vector3(-1, 1, -12.7)},
		{"to": Vector3(-0.6, 1, -13.6), "jump": "jump", "aim": Vector3(1, 1.5, -16.7)},
		{"to": Vector3(1, 1.5, -17.6), "jump": "jump", "aim": Vector3(0.5, 1.5, -21.2)},
		{"to": Vector3(0, 1.5, -22.5), "jump": "jump", "aim": Vector3(0, 1.5, -26.0)},
		{"to": Vector3(0, 1.5, -26.4), "jump": "jump", "aim": Vector3(0, 1.5, -29.8)},
		{"to": Vector3(0, 1.5, -30.2), "jump": "jump", "aim": Vector3(0, 1.5, -32.8)},
		{"to": Vector3(0, 1.5, -32.9), "when": func(p): return absf(_plat_at(p, 0, 0.8).x) < 1.2},
		{"to": Vector3(0, 1.5, -33.7), "jump": "jump", "aim": func(p, s): return _plat_at(p, 0, s) + Vector3(0, 0, 0.8)},
		{"to": func(p): return Vector3(_plat_at(p, 0, 0).x, 1.5, -38.0), "jump": "jump", "aim": func(p, s): return _plat_at(p, 1, s) + Vector3(0, 0, 0.6)},
		{"to": func(p): return Vector3(_plat_at(p, 1, 0).x, 1.5, -42.6), "jump": "jump", "aim": Vector3(1.5, 1.5, -47.6)},
		{"to": Vector3(-0.8, 1.5, -48.3), "jump": "double", "aim": Vector3(-6.5, 4.0, -48.5)},
		{"to": Vector3(-11.2, 4.0, -48.5), "jump": "long", "aim": Vector3(-21.8, 3.0, -48.5)},
		{"to": Vector3(-23.0, 3.0, -48.5), "jump": "long", "aim": Vector3(-33.0, 3.0, -48.5)},
		{"to": Vector3(-40.0, 3.0, -48.5)},
	]


# --- Crab Shore Dash ---------------------------------------------------------

## Where a named moving platform of the course will be `ahead` seconds from
## now.
static func _mp_at(play: Play, platform: String, ahead: float) -> Vector3:
	var p := play.level.get_node(platform) as MovingPlatform
	return p._start + p.offset_at(p._t + ahead)


## How far through its cycle a named moving platform is, 0 to 1.
static func _mp_phase(play: Play, platform: String) -> float:
	var p := play.level.get_node(platform) as MovingPlatform
	return fposmod(p._t, p.period) / p.period


## The pilot's way through Crab Shore Dash: jump each crab lane, hop on the
## ferry and off at the far shore, hop the sinking rafts while they're up,
## jump the dune's crab and long jump to the finish island.
func _crabshore() -> Array:
	var legs := []
	for z in SunnyCrabShore.CRAB_LANES:
		legs.append({"to": Vector3(0, 0, z + 2.2), "jump": "jump", "aim": Vector3(0, 0, z - 2.2)})
	legs.append_array([
		{"to": Vector3(0, 0, -27.3), "when": func(p): return _mp_at(p, "Ferry", 0.0).z > -30.5,
			"jump": "jump", "aim": func(p, s): return _mp_at(p, "Ferry", s)},
		{"to": func(p): return _mp_at(p, "Ferry", 0.0) + Vector3(0, 0, -0.9), "when": func(p): return _mp_at(p, "Ferry", 0.0).z < -36.6,
			"jump": "jump", "aim": Vector3(0, 0, -41.5)},
		{"to": Vector3(0, 0, -44.4), "when": func(p): return _mp_phase(p, "Tide1") > 0.9,
			"jump": "jump", "aim": func(p, s): return _mp_at(p, "Tide1", s)},
		{"to": func(p): return _mp_at(p, "Tide1", 0.0) + Vector3(0, 0, -0.6), "jump": "jump", "aim": func(p, s): return _mp_at(p, "Tide2", s)},
		{"to": func(p): return _mp_at(p, "Tide2", 0.0) + Vector3(0, 0, -0.6), "jump": "jump", "aim": func(p, s): return _mp_at(p, "Tide3", s)},
		{"to": func(p): return _mp_at(p, "Tide3", 0.0) + Vector3(0, 0, -0.6), "jump": "jump", "aim": Vector3(0, 0, -59.8)},
		{"to": Vector3(4.5, 0, -62)},
		{"to": Vector3(SunnyCrabShore.DUNE_CRAB_X - 2.2, 1.0, -62), "jump": "jump", "aim": Vector3(SunnyCrabShore.DUNE_CRAB_X + 2.2, 1.0, -62)},
		{"to": Vector3(14.5, 1.0, -62), "jump": "long", "aim": Vector3(24.5, 0.5, -62)},
		{"to": Vector3(28.5, 0.5, -62)},
	])
	return legs


# --- Windmill Hills ----------------------------------------------------------

## Which way a named spinner's bar points, in degrees from 0 to 360 (0 is
## south, +z; 90 is east).
static func _bar_angle(play: Play, bar: String) -> float:
	var s := play.level.get_node(bar) as Spinner
	return fposmod(s._arm.rotation_degrees.y, 360.0)


## The pilot's way through Windmill Hills: let the first bar pass, spring up
## the cliff, jump the bees, let the second bar pass, jump the stream and
## high jump up to the windmill.
func _windmill() -> Array:
	var legs := [
		{"to": Vector3(0, 1.0, -11.0), "when": func(p): var a := _bar_angle(p, "Bar1"); return a > 318.0 and a < 350.0},
		{"to": Vector3(0, 1.0, -20.6), "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(0, 4.5, -23.6), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 4.4},
	]
	for z in SunnyWindmillHills.BEE_LANES:
		legs.append({"to": Vector3(0, 4.5, z + 2.2), "jump": "jump", "aim": Vector3(0, 4.5, z - 2.2)})
	legs.append_array([
		{"to": Vector3(-9.2, 4.5, -35), "when": func(p): var a := _bar_angle(p, "Bar2"); return a > 110.0 and a < 136.0},
		{"to": Vector3(-22.6, 2.5, -35)},
		{"to": Vector3(-25.4, 2.5, -35), "jump": "jump", "aim": Vector3(-29.8, 2.5, -35)},
		{"to": Vector3(-31.4, 2.5, -35), "jump": "high", "aim": Vector3(-34.6, 5.0, -35)},
		{"to": Vector3(-40.5, 5.0, -35)},
	])
	return legs


# --- Treetop Hop -------------------------------------------------------------

## The pilot's way through Treetop Hop: run the plank bridge before it
## drops, jump the caterpillar, high jump up the branch, hop up the falling
## stair, jump the bee and long jump down to the flag.
func _treetop() -> Array:
	var cat_z := SunnyTreetopHop.CATERPILLAR_Z
	var stair: Array = SunnyTreetopHop.STAIR
	var bee_x := SunnyTreetopHop.BEE_X
	var legs := [
		{"to": Vector3(0, 4.0, cat_z + 2.2), "jump": "jump", "aim": Vector3(0, 4.0, cat_z - 2.2)},
		{"to": Vector3(0, 4.0, -21.6), "jump": "high", "aim": Vector3(0, 6.8, -25.0)},
		{"to": Vector3(0.4, 6.8, -27.5)},
		{"to": Vector3(2.3, 6.8, -27.5), "jump": "jump", "aim": stair[0]},
	]
	for i in stair.size():
		var next: Vector3 = stair[i + 1] if i + 1 < stair.size() else Vector3(16.8, 10.0, -27.5)
		legs.append({"to": stair[i] + Vector3(0.7, 0, 0), "jump": "jump", "aim": next})
	legs.append_array([
		{"to": Vector3(bee_x - 2.2, 10.0, -27.5), "jump": "jump", "aim": Vector3(bee_x + 2.2, 10.0, -27.5)},
	])
	# The branches: hop on to each when it'll be in line on landing.
	var from := func(_p): return Vector3(24.2, 10.0, -27.5)
	for i in SunnyTreetopHop.BRANCHES:
		var target := "Branch%d" % (i + 1)
		legs.append({"to": from, "when": _lined_up.bind(target), "jump": "jump", "aim": _branch_aim.bind(target)})
		from = _branch_edge.bind(target)
	legs.append({"to": from, "when": func(p): return absf(p.hero.global_position.z + 27.5) < 0.8, "jump": "jump", "aim": Vector3(39.6, 10.0, -27.5)})
	var cat_x := SunnyTreetopHop.CATERPILLAR2_X
	legs.append_array([
		{"to": Vector3(cat_x - 2.2, 10.0, -27.5), "jump": "jump", "aim": Vector3(cat_x + 2.2, 10.0, -27.5)},
		{"to": Vector3(45.3, 10.0, -27.5), "jump": "long", "aim": Vector3(54.5, 8.0, -27.5)},
		{"to": Vector3(58.5, 8.0, -27.5)},
	])
	return legs


## True when a branch will be in line with the hero by the time a jump
## lands on it.
static func _lined_up(play: Play, branch: String) -> bool:
	return absf(_mp_at(play, branch, 0.6).z - play.hero.global_position.z) < 0.5


static func _branch_aim(play: Play, seconds: float, branch: String) -> Vector3:
	return _mp_at(play, branch, seconds)


## The east edge of a branch, where the hero waits for the next one.
static func _branch_edge(play: Play, branch: String) -> Vector3:
	return _mp_at(play, branch, 0.0) + Vector3(0.6, 0, 0)
