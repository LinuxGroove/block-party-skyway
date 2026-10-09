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
	return []


## Sunny Isles: Pebble's chicks, the silver rush (which brings the Skyway
## to Lookout Islet), the ledge under the cliff, the old tower, the crabs'
## crate, the course door and falling off.
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
	# The course door leads into Saw Mill Sprint.
	var door: CourseDoor = null
	for d in isle.find_children("*", "CourseDoor", true, false):
		if (d as CourseDoor).course_id == "sawmill":
			door = d
	await t._until(func(): return not h.is_locked(), 3.0)
	h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == door, "the course door can be used")
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
