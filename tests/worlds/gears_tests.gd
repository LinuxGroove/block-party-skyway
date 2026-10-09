extends RefCounted
## Gear Works' tests, run by tests/run_tests.gd: the island's stars, The Big
## Press, and the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"belt_rush":
			return _belt_rush()
		"piston_climb":
			return _piston_climb()
		"fan_tower":
			return _fan_tower()
		"crusher_row":
			return _crusher_row()
	return []


## Gear Works: Bolt's cogs (the shuttle, the fan and the crusher lift), the
## shift switch, the crane tower, belt seven's secret ledge, catching
## Scamp, both island gems, the boss door, then The Big Press.
func run() -> void:
	t._fast(true)
	Progress.wipe()
	# The way here: Snack Valley's boss is beaten.
	Progress.add_star(str(Worlds.boss_def("snack").star))
	var play := t._make_play("gears", "adventure")
	await t._ticks(10)
	var isle := play.level as GearsIsle
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Gear Works")
	var door: BossDoor = isle.find_children("*", "BossDoor", true, false)[0]
	t.check(not door.is_open(), "the boss door is shut at first")
	await _bolts_cogs(play, isle)
	await _shift_switch(play, isle)
	await _crane_tower(play, isle)
	await _belt_seven(play, isle)
	await _catch_scamp(play, isle)
	await _gems(play, isle)
	t.check(door.is_open(), "five stars open the boss door")
	# The boss door leads to The Big Press.
	h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == door, "the boss door can be used")
	var left := 0
	for id in Worlds.star_ids("gears"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("gears"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(isle.secrets_left() == left, "secrets left counts what's still hidden (%d)" % isle.secrets_left())
	# Falling off costs a heart and comes back at the last flag.
	play.hearts = Play.MAX_HEARTS
	h.place(Vector3(0, -20, 40))
	await t._ticks(3)
	t.check(h.global_position.y > -2.0 and play.hearts == Play.MAX_HEARTS - 1, "falling off costs a heart and comes back")
	t._fast(false)
	await t._free(play)
	await _big_press()


## Waits for the hero to be free (after a star's little celebration).
func _free_hands(play: Play) -> void:
	play.autopilot = t._hands_off
	await t._until(func(): return not play.hero.is_locked() and not play.speech_open(), 4.0)


func _collect_star(play: Play, id: String) -> bool:
	var star := t._find_star(play.level, id)
	if star == null:
		return false
	play.hero.place(star.global_position - Vector3.UP * 0.4)
	return await t._until(func(): return Progress.has_star(id), 2.0)


# --- Bolt's cogs -------------------------------------------------------------

static func _shuttle(play: Play) -> MovingPlatform:
	for n in play.level.find_children("*", "MovingPlatform", true, false):
		if absf((n as MovingPlatform)._start.z + 6.0) < 0.1:
			return n
	return null


static func _shuttle_at(play: Play, ahead: float) -> Vector3:
	var p := _shuttle(play)
	return p._start + p.offset_at(p._t + ahead)


func _bolts_cogs(play: Play, isle: GearsIsle) -> void:
	var h := play.hero
	h.place(isle.bolt.global_position + Vector3(0.6, 0.1, 1.0))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.bolt, "Bolt is there to talk to")
	isle.bolt.talk()
	t.check(play.speech_open(), "Bolt explains about his cogs")
	while play.speech_open():
		play._next_line()
	# The first cog rides the shuttle: wait at the edge, jump aboard.
	var c0 := isle.cogs[0]
	h.place(Vector3(-27, -0.95, -6), Vector3.LEFT)
	var ok: bool = await t._pilot(play, [
		{"to": Vector3(-27.6, -1, -6), "when": func(p): return _shuttle_at(p, 0.5).x > -30.2 and _shuttle_at(p, 0.0).x < _shuttle_at(p, 0.5).x},
		{"to": Vector3(-27.6, -1, -6), "jump": "jump", "aim": func(p, s): return _shuttle_at(p, s)},
		{"to": func(p): return _shuttle_at(p, 0.0), "until": func(_p): return c0.is_home},
	], 15.0)
	t.check(ok and c0.is_home, "jumping onto the shuttle wins back the first cog (at %s)" % h.global_position)
	# The second floats over the big fan in the crane yard.
	var c1 := isle.cogs[1]
	h.place(Vector3(24, 0.05, 4.5), Vector3.FORWARD)
	ok = await t._pilot(play, [
		{"to": Vector3(24, 0, 2), "walk": true, "until": func(_p): return c1.is_home},
	], 10.0)
	t.check(ok and c1.is_home, "the fan lifts the hero to the second cog (at %s)" % h.global_position)
	h.place(Vector3(20, 0.05, 2), Vector3.FORWARD)
	await t._ticks(30)
	# The third is on the boiler house roof: ride the crusher up.
	var c2 := isle.cogs[2]
	var crusher: Crusher = isle.find_children("*", "Crusher", true, false)[0]
	h.place(Vector3(-14.5, -0.95, -8), Vector3.LEFT)
	ok = await t._pilot(play, [
		{"to": Vector3(-15.0, -1, -8), "when": func(_p): return fposmod(crusher._t, crusher.cycle()) < 0.3},
		{"to": Vector3(-15.0, -1, -8), "jump": "jump", "aim": Vector3(-16.8, 0, -8)},
		{"to": Vector3(-16.8, 0, -8), "walk": true, "until": func(_p): return crusher.offset_at(crusher._t) >= crusher.lift - 0.01},
		{"to": Vector3(-20, 3, -8), "until": func(_p): return c2.is_home},
	], 15.0)
	t.check(ok and c2.is_home, "riding the crusher up wins back the third cog (at %s)" % h.global_position)
	play.autopilot = t._hands_off
	t.check(await t._until(func(): return isle.cogs_home == 3, 3.0), "all three cogs go home")
	t.check(play.speech_open(), "Bolt thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	t.check(await _collect_star(play, "gears/cogs"), "Bolt's star is found")
	await _free_hands(play)


# --- The shift switch --------------------------------------------------------

func _shift_switch(play: Play, isle: GearsIsle) -> void:
	var h := play.hero
	var sw := isle.shift_switch
	h.place(Vector3(-14.5, -0.95, 8), Vector3.LEFT)
	await t._ticks(4)
	var ok: bool = await t._pilot(play, [
		{"to": Vector3(-16, -1, 8)},
		{"to": Vector3(-17.0, -1, 8), "jump": "jump", "aim": Vector3(-18.7, 0.2, 8)},
		{"to": Vector3(-19.0, 0.2, 8), "jump": "jump", "aim": Vector3(-21.0, 1.4, 8)},
		{"to": Vector3(-21.5, 1.4, 8), "jump": "jump", "aim": Vector3(-23.5, 2.6, 8)},
		{"to": Vector3(-24.0, 2.6, 8), "jump": "jump", "aim": Vector3(-26.0, 3.8, 8.2)},
		{"to": Vector3(-26.0, 3.8, 7.4), "jump": "jump", "aim": Vector3(-26.0, 5.0, 5.6)},
		{"to": Vector3(-26.0, 5.0, 5.0), "jump": "jump", "aim": Vector3(-26.0, 6.2, 2.6)},
	], 15.0)
	t.check(ok, "the pilot climbs the shift switch's steps (at %s)" % h.global_position)
	t.check(sw.time_left > 0.0 or sw.held, "with time to spare (%.1f s)" % sw.time_left)
	t.check(await t._until(func(): return Progress.has_star("gears/switch"), 2.0), "the shift switch's star is found")
	t.check(sw.held, "the steps stay out once the star is won")
	await _free_hands(play)
	# Without the switch, the steps aren't there.
	var fresh := GearsTimedBridge.new()
	t.check(fresh.time_left == 0.0 and not fresh.is_running(), "a timed bridge starts folded away")
	fresh.free()


# --- The crane tower ---------------------------------------------------------

func _crane_tower(play: Play, isle: GearsIsle) -> void:
	var h := play.hero
	var piston: GearsPiston = isle.find_children("*", "GearsPiston", true, false)[0]
	h.place(Vector3(20, 0.05, 1.0), Vector3.FORWARD)
	await t._ticks(4)
	var ok: bool = await t._pilot(play, [
		{"to": Vector3(20, 0, -0.2), "jump": "high", "aim": Vector3(20, 2.5, -2)},
		{"to": Vector3(20.4, 2.5, -2), "when": func(_p): return fposmod(piston._t, piston.cycle()) < 0.2},
		{"to": Vector3(22, 2.5, -2), "walk": true, "until": func(_p): return piston.offset_at(piston._t) >= piston.lift - 0.01},
		{"to": Vector3(22.5, 6.0, -2.6), "jump": "jump", "aim": Vector3(22.5, 6.0, -5.0)},
		{"to": Vector3(22.5, 6.0, -7.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 12.3, "off": Vector3.RIGHT,
			"until": func(_p): return Progress.has_star("gears/crane")},
	], 25.0)
	t.check(ok and Progress.has_star("gears/crane"), "the crane tower can be climbed for its star (at %s)" % h.global_position)
	await _free_hands(play)


# --- Belt seven --------------------------------------------------------------

func _belt_seven(play: Play, _isle: GearsIsle) -> void:
	var h := play.hero
	h.place(Vector3(10.5, 0.05, 18.0), Vector3.BACK)
	await t._ticks(4)
	var ok: bool = await t._pilot(play, [
		{"to": Vector3(10.5, 0, 21.0), "walk": true},
		{"to": Vector3(10.5, 0, 26.0), "walk": true, "until": func(_p): return h.is_on_floor() and h.global_position.y < -4.0},
		{"to": Vector3(10.5, -4.5, 27.3), "walk": true, "until": func(_p): return Progress.has_star("gears/belt")},
	], 15.0)
	t.check(ok and Progress.has_star("gears/belt"), "belt seven carries the hero off the edge to a secret star (at %s)" % h.global_position)
	await _free_hands(play)
	ok = await t._pilot(play, [
		{"to": Vector3(13.5, -4.5, 25.6), "walk": true, "until": func(_p): return h.global_position.y > 1.0},
		{"to": Vector3(13.5, 0, 22.0), "until": func(_p): return h.is_on_floor() and h.global_position.y > -0.1},
	], 15.0)
	t.check(ok, "the fan blows the hero back up to the dock (at %s)" % h.global_position)


# --- Scamp -------------------------------------------------------------------

## Runs straight at Scamp every tick.
func _chase(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if play.speech_open():
		play._next_line()
		return
	var isle := play.level as GearsIsle
	var to := isle.scamp.global_position - h.global_position
	to.y = 0.0
	if to.length() > 0.05:
		h.input.move = to.normalized()
	h.input.run = true


func _catch_scamp(play: Play, isle: GearsIsle) -> void:
	var h := play.hero
	h.place(Vector3(0, 0.05, 1), Vector3.FORWARD)
	await t._ticks(4)
	var start := isle.scamp.global_position
	play.autopilot = _chase
	await t._ticks(60)
	t.check(isle.scamp.global_position.distance_to(start) > 1.0, "Scamp runs off when the hero comes near")
	t.check(await t._until(func(): return isle.scamp.is_caught, 25.0), "running catches Scamp (at %s, Scamp at %s)" % [h.global_position, isle.scamp.global_position])
	await t._until(func(): return t._find_star(isle, "gears/scamp") != null, 5.0)
	play.autopilot = t._hands_off
	t.check(await _collect_star(play, "gears/scamp"), "Scamp's star is found")
	await _free_hands(play)


# --- The island's gems -------------------------------------------------------

func _gems(play: Play, isle: GearsIsle) -> void:
	var h := play.hero
	# The strong crate behind the boxes: a ground pound breaks it.
	var crate: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "gem:gears/gem_crate":
			crate = b
	t.check(crate != null, "the strong crate is behind the hall")
	if crate:
		var at := crate.global_position
		h.place(at + Vector3.UP * 3.0)
		await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		t.check(not is_instance_valid(crate), "a ground pound breaks the strong crate")
		h.place(at + Vector3.UP * 0.1)
		t.check(await t._until(func(): return Progress.has_gem("gears/gem_crate"), 2.0), "the crate's gem is found")
	# The old pipe off the belt works.
	h.place(Vector3(-27, -0.95, -1.5), Vector3.LEFT)
	await t._ticks(4)
	var ok: bool = await t._pilot(play, [
		{"to": Vector3(-35.5, -1, -1.5), "walk": true, "until": func(_p): return Progress.has_gem("gears/gem_pipe")},
	], 10.0)
	t.check(ok, "walking the old pipe finds its gem (at %s)" % h.global_position)
	await _free_hands(play)


# --- The Big Press -----------------------------------------------------------

## What the arena said, and how often the hero was hurt.
var _said: Array[String] = []
var _hurts := 0


func _heard(text: String) -> void:
	_said.append(text)


func _hurt_taken() -> void:
	_hurts += 1


## The Big Press: off the edge is back to the flag, standing still under it
## gets you squashed, it says what to do, and the hero beats it by jumping
## its ring and pounding it while it's stuck, three times. Its star drops in
## the middle.
func _big_press() -> void:
	t._fast(true)
	var play := t._make_play("big_press", "adventure")
	await t._ticks(5)
	var arena := play.level as GearsPressArena
	var press := arena.press
	var h := play.hero
	t.check(press != null and press.health == 3, "The Big Press waits in its arena")
	arena.message.connect(_heard)
	h.hurt_taken.connect(_hurt_taken)
	# Off the edge: back at the flag by the entrance.
	h.place(Vector3(0, 0.5, 14.5))
	await t._until(func(): return h.global_position.y < -2.0, 3.0)
	var back: bool = await t._until(func(): return h.is_on_floor() and h.global_position.y > -0.5, 4.0)
	t.check(back and h.global_position.distance_to(Vector3(-1, 0, 10)) < 2.5, "falling off the arena comes back at its flag (%s)" % h.global_position)
	# Standing still: it follows, holds, and slams down on the hero.
	play.hearts = Play.MAX_HEARTS
	h.place(Vector3(0, 0, 4), Vector3.FORWARD)
	play.autopilot = t._hands_off
	_hurts = 0
	t.check(await t._until(func(): return _hurts > 0, 12.0), "standing still under the press gets you squashed")
	t.check(_said.size() > 0 and "pound" in _said[0], "the press says what to do (%s)" % [_said])
	# The fight.
	play.hearts = Play.MAX_HEARTS
	_hurts = 0
	play.autopilot = _press_pilot
	var won: bool = await t._until(func(): return press.beaten, 150.0)
	t.check(won, "the hero beats The Big Press (%d hits left, %s)" % [press.health, GearsBigPress.Phase.keys()[press.phase]])
	t.check(_hurts <= 1, "dodging its slams and jumping its rings (%d hurts)" % _hurts)
	t.check(await t._until(func(): return Progress.has_star("gears/boss"), 6.0), "The Big Press's star drops in the middle and is found")
	play.autopilot = t._hands_off
	t._fast(false)
	await t._free(play)


## Drives the hero round the arena in a ring while the press aims and
## slams, jumps its ring of force, and when it's stuck runs in, jumps on top
## and ground pounds it. Once it's beaten, goes to the middle for the star.
func _press_pilot(play: Play) -> void:
	var h := play.hero
	var press := (play.level as GearsPressArena).press
	var at := h.global_position
	var d := Vector2(at.x, at.z).length()
	var out := Vector3(at.x, 0, at.z) / maxf(d, 0.01)
	h.input.clear()
	h.input.run = true
	h.input.jump_held = true
	var ground := h.is_on_floor()
	if press.beaten:
		h.input.move = -out if d > 0.3 else Vector3.ZERO
		return
	var ring := press.ring_radius
	var ring_coming := ring >= 0.0 and ring < d + 0.3
	if press.is_stuck() and press.open and not ring_coming:
		var rel := at - press.global_position
		if not ground and absf(rel.x) < 1.9 and absf(rel.z) < 1.9 and h.velocity.y < 1.5 and not h.is_pounding():
			h.input.crouch = true
			h.input.crouch_pressed = true
			return
		h.input.move = -out if d > 0.3 else Vector3.ZERO
		if ground and d < 3.7:
			h.input.jump = true
		return
	# Run round in a ring, six and a half metres out.
	var tangent := Vector3(-out.z, 0, out.x)
	h.input.move = (tangent + out * clampf((6.5 - d) * 0.6, -1.0, 1.0)).normalized()
	if ring_coming and ground and d - ring < 1.2:
		h.input.jump = true


# --- Courses -----------------------------------------------------------------

## Belt Rush's crushers, nearest first.
static func _crusher(play: Play, i: int) -> Crusher:
	var list := play.level.find_children("*", "Crusher", true, false)
	list.sort_custom(func(a, b): return a.position.z > b.position.z)
	return list[i]


## Seconds into a crusher's beat.
static func _beat(c: Crusher) -> float:
	return fposmod(c._t, c.cycle())


## The pilot's way through Belt Rush: jump the gaps between the up belts,
## run up the middle of the side-belt deck, dash along the express belt as
## the first crusher lifts, then hop east over the cross belts.
func _belt_rush() -> Array:
	return [
		{"to": Vector3(0, 0, -10.4), "jump": "jump", "aim": Vector3(0, 0, -15.2)},
		{"to": Vector3(0, 0, -18.4), "jump": "jump", "aim": Vector3(0, 0, -23.2)},
		{"to": Vector3(0, 0, -26.4), "jump": "jump", "aim": Vector3(0, 0, -31.2)},
		{"to": Vector3(0, 0, -45.5)},
		{"to": Vector3(0, 0, -50.4), "when": func(p): return absf(_beat(_crusher(p, 0)) - 0.95) < 0.1},
		{"to": Vector3(0, 0, -62.5)},
		{"to": Vector3(4.4, 0, -64), "jump": "jump", "aim": Vector3(8, 0, -64)},
		{"to": Vector3(8.6, 0, -64), "jump": "jump", "aim": Vector3(12, 0, -64)},
		{"to": Vector3(12.6, 0, -64), "jump": "jump", "aim": Vector3(16, 0, -64)},
		{"to": Vector3(16.6, 0, -64), "jump": "jump", "aim": Vector3(20, 0, -64)},
		{"to": Vector3(20.6, 0, -64), "jump": "jump", "aim": Vector3(24.5, 0, -64)},
		{"to": Vector3(28, 0, -64)},
	]


static func _climb(play: Play) -> GearsPistonClimb:
	return play.level as GearsPistonClimb


## Seconds into a piston's beat.
static func _pbeat(p: GearsPiston) -> float:
	return fposmod(p._t, p.cycle())


## Where hop piston i's head will be in `ahead` seconds.
static func _hop_at(play: Play, i: int, ahead: float) -> Vector3:
	return _climb(play).hops[i].top_at(ahead)


## The pilot's way up Piston Climb: ride the first lift, dash under both
## crushers, ride the second lift, kick up between the stacks, then hop the
## pistons west, waiting for each one to come down within reach and for the
## last to rise level with the finish.
func _piston_climb() -> Array:
	return [
		{"to": Vector3(0, 0, -3.4), "when": func(p): return _pbeat(_climb(p).lifts[0]) < 0.2},
		{"to": Vector3(0, 0, -5), "walk": true, "until": func(p): return _climb(p).lifts[0].offset_at(_climb(p).lifts[0]._t) >= 3.49},
		{"to": Vector3(0, 3.5, -7.4), "when": func(p): return absf(_beat(_climb(p).crushers[0]) - 1.25) < 0.08},
		{"to": Vector3(0, 3.5, -14.4), "when": func(p): return _pbeat(_climb(p).lifts[1]) < 0.2},
		{"to": Vector3(0, 3.5, -16), "walk": true, "until": func(p): return _climb(p).lifts[1].offset_at(_climb(p).lifts[1]._t) >= 3.49},
		{"to": Vector3(0, 7, -18)},
		{"to": Vector3(0.5, 7, -27.8), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 13.3, "off": Vector3.RIGHT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 12.9},
		{"to": Vector3(-3.4, 13, -34), "when": func(p): return _hop_at(p, 0, 0.55).y < 13.8},
		{"to": Vector3(-3.4, 13, -34), "jump": "jump", "aim": func(p, s): return _hop_at(p, 0, s)},
		{"to": func(p): return _hop_at(p, 0, 0.0) + Vector3(-0.5, 0, 0), "when": func(p): return _hop_at(p, 1, 0.55).y < p.hero.global_position.y + 0.8},
		{"to": func(p): return _hop_at(p, 0, 0.0) + Vector3(-0.5, 0, 0), "jump": "jump", "aim": func(p, s): return _hop_at(p, 1, s)},
		{"to": func(p): return _hop_at(p, 1, 0.0) + Vector3(-0.5, 0, 0), "when": func(p): return _hop_at(p, 2, 0.55).y < p.hero.global_position.y + 0.8},
		{"to": func(p): return _hop_at(p, 1, 0.0) + Vector3(-0.5, 0, 0), "jump": "jump", "aim": func(p, s): return _hop_at(p, 2, s)},
		{"to": func(p): return _hop_at(p, 2, 0.0) + Vector3(-0.5, 0, 0), "when": func(p): return _hop_at(p, 2, 0.0).y > 14.6},
		{"to": func(p): return _hop_at(p, 2, 0.0) + Vector3(-0.5, 0, 0), "jump": "jump", "aim": Vector3(-16.6, 15, -34)},
		{"to": Vector3(-20, 15, -34)},
	]


## How far round Fan Tower's spinner has turned past the last arm (0 to
## 180 degrees: two arms).
static func _sweep(play: Play) -> float:
	var s := (play.level as GearsFanTower).spinner
	return fposmod(s._arm.rotation_degrees.y, 180.0)


## The pilot's way up Fan Tower: float up the first fan, dash past the
## spinner just after an arm, jump the catwalk's gaps leaning into the gust,
## float up the second fan, run the falling platforms, and float up the
## last fan to the flag.
func _fan_tower() -> Array:
	return [
		{"to": Vector3(0, 0, -6.6), "walk": true, "until": func(p): return p.hero.global_position.y > 6.5},
		{"to": Vector3(0, 5, -10.5), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 4.9},
		{"to": Vector3(1.8, 5, -12.3), "when": func(p): return absf(_sweep(p) - 130.0) < 8.0},
		{"to": Vector3(1.8, 5, -20.4)},
		{"to": Vector3(0, 5, -21.6)},
		{"to": Vector3(0, 5, -25.4), "jump": "jump", "aim": Vector3(0, 5, -29.5)},
		{"to": Vector3(0, 5, -31.4), "jump": "jump", "aim": Vector3(0, 5, -35.5)},
		{"to": Vector3(0, 5, -39.5)},
		{"to": Vector3(0, 5, -42.8), "walk": true, "until": func(p): return p.hero.global_position.y > 9.5},
		{"to": Vector3(0, 10.5, -47.5), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 10.4},
		{"to": Vector3(-0.5, 10.5, -50)},
		{"to": Vector3(-3.4, 10.5, -50), "jump": "jump", "aim": Vector3(-6.0, 10.5, -50)},
		{"to": Vector3(-6.4, 10.5, -50), "jump": "jump", "aim": Vector3(-9.5, 10.5, -50)},
		{"to": Vector3(-9.9, 10.5, -50), "jump": "jump", "aim": Vector3(-13.0, 10.5, -50)},
		{"to": Vector3(-13.4, 10.5, -50), "jump": "jump", "aim": Vector3(-16.5, 10.5, -50)},
		{"to": Vector3(-17.5, 10.5, -50), "walk": true, "until": func(p): return p.hero.global_position.y > 15.5},
		{"to": Vector3(-22.5, 17, -50), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 16.9},
		{"to": Vector3(-27.5, 17, -50)},
	]


static func _row(play: Play) -> GearsCrusherRow:
	return play.level as GearsCrusherRow


## The pilot's way through Crusher Row: dash the corridor as its first
## crusher lifts, step on the bridge's button and hop the steps, weave the
## rows (south, north, south) as the beat comes round, then ride the lift.
func _crusher_row() -> Array:
	return [
		{"to": Vector3(0, 0, -4.0), "when": func(p): return absf(_beat(_row(p).corridor[0]) - 1.0) < 0.06},
		{"to": Vector3(0, 0, -24.0)},
		{"to": Vector3(2.0, 0, -25.6)},
		{"to": Vector3(0, 0, -31.4), "jump": "jump", "aim": Vector3(0, 0, -34.4)},
		{"to": Vector3(0, 0, -34.6), "jump": "jump", "aim": Vector3(0, 0, -38.2)},
		{"to": Vector3(0, 0, -38.6), "jump": "jump", "aim": Vector3(0, 0, -42.2)},
		{"to": Vector3(0, 0, -42.6), "jump": "jump", "aim": Vector3(0, 0, -45.6)},
		{"to": Vector3(-3.5, 0, -46), "when": func(p): return absf(_beat(_row(p).rows[0][0]) - 0.96) < 0.06},
		{"to": Vector3(-9.5, 0, -46)},
		{"to": Vector3(-11.8, 0, -48)},
		{"to": Vector3(-14.5, 0, -48)},
		{"to": Vector3(-16.8, 0, -46)},
		{"to": Vector3(-19.8, 0, -47), "when": func(p): return _beat(_row(p).lift) < 0.15},
		{"to": Vector3(-21.4, 0, -47), "jump": "jump", "aim": Vector3(-23.6, 1.0, -47)},
		{"to": Vector3(-23.7, 1, -47), "until": func(p): return _beat(_row(p).lift) > 2.65 and _beat(_row(p).lift) < 3.6},
		{"to": Vector3(-24.1, 4, -47), "jump": "jump", "aim": Vector3(-27.5, 3.5, -47)},
		{"to": Vector3(-30, 3.5, -47)},
	]
