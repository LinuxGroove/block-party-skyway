extends RefCounted
## Sky Castle's tests, run by tests/run_tests.gd: the island's stars, the
## Siege Tower, and the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"ramparts":
			return _ramparts()
		"drawbridge":
			return _drawbridge()
		"spire":
			return _spire()
		"siege":
			return _siege()
	return []


## The island: Rufus's banners, the Rampart Rush, the top of the keep, the
## star on a cloud, Thud's catapult, the gem behind the banner, the course
## doors and falling off; then the Siege Tower.
func run() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("castle", "adventure")
	await t._ticks(10)
	var isle := play.level as CastleIsle
	var h := play.hero
	play.autopilot = t._hands_off
	t.check(h.is_on_floor(), "the hero lands on Sky Castle")
	# Captain Mane at the barbican has something to say.
	h.place(Vector3(-1.8, CastleIsle.WARD + 0.05, -3.6), Vector3.LEFT)
	await t._ticks(6)
	var mane := isle.nearest_talker()
	t.check(mane is Islander and (mane as Islander).islander_name == "Captain Mane", "Captain Mane guards the barbican")
	if mane:
		mane.talk()
		t.check(play.speech_open(), "Captain Mane talks")
		while play.speech_open():
			play._next_line()
	await t._until(func(): return not h.is_locked(), 2.0)
	await _banners(play)
	await _rush(play)
	await _keep(play)
	await _clouds(play)
	await _catapult(play)
	await _banner_gem(play)
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
	for id in Worlds.star_ids("castle"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("castle"):
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


# --- The island ----------------------------------------------------------------

## Rufus asks for his three banners back up: touch each pole (on the west
## tower, the gate tower and the east tower) and he gives a star.
func _banners(play: Play) -> void:
	var isle := play.level as CastleIsle
	var h := play.hero
	h.place(isle.rufus.global_position + Vector3(1.0, 0.1, 0.6))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.rufus, "Rufus is there to talk to")
	isle.rufus.talk()
	t.check(play.speech_open(), "Rufus asks for his banners")
	while play.speech_open():
		play._next_line()
	await t._until(func(): return not h.is_locked(), 2.0)
	for pole in isle.poles:
		# Up on the tower beside the pole, then walk into it.
		h.place(pole.global_position + Vector3(1.1, 0.1, 0), Vector3.LEFT)
		await t._ticks(4)
		await t._drive(h, 40, func(inp, _i): inp.move = Vector3.LEFT * 0.5)
		t.check(pole.is_raised, "touching a pole raises its banner")
		await t._ticks(30)
	t.check(isle.banners_up == 3, "all three banners fly")
	t.check(await t._until(func(): return play.speech_open(), 2.0), "Rufus thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	var star := t._find_star(isle, "castle/banners")
	t.check(star != null, "Rufus gives a star")
	if star:
		await t._until(func(): return not h.is_locked(), 2.0)
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("castle/banners"), 2.0), "the banners' star is found")
	await t._until(func(): return not h.is_locked(), 3.0)


## The Rampart Rush: step on the button, grab the eight silver coins.
func _rush(play: Play) -> void:
	var isle := play.level as CastleIsle
	var h := play.hero
	h.place(isle.silver.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.silver.time_left > 0.0, 1.0), "the button starts the Rampart Rush")
	for p in isle.silver.coins.duplicate():
		if is_instance_valid(p):
			h.place(p.global_position - Vector3.UP * 0.2)
			await t._ticks(6)
	var star := t._find_star(isle, "castle/silver")
	t.check(star != null, "eight silver coins give a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("castle/silver"), 2.0), "the Rampart Rush star is found")
	await t._until(func(): return not h.is_locked(), 3.0)


## The top of the keep: kick up between the keep and its turret, and once
## above the keep, steer onto it for its star.
func _keep(play: Play) -> void:
	var isle := play.level as CastleIsle
	var h := play.hero
	var pilot := CoursePilot.new([
		{"to": Vector3(1.8, CastleIsle.WARD, -33.5), "walk": true},
		{"wall": true, "toward": Vector3.FORWARD, "top": isle.keep_top + 0.6, "off": Vector3.FORWARD,
			"until": func(_p): return h.is_on_floor() and h.global_position.y > isle.keep_top - 0.2},
		{"to": Vector3(0, isle.keep_top, -37.5), "until": func(_p): return Progress.has_star("castle/keep")},
	])
	h.place(Vector3(3.6, CastleIsle.WARD + 0.05, -33.5), Vector3.LEFT)
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return pilot.done, 25.0), "wall kicks reach the top of the keep (stuck at leg %d, %s)" % [pilot.leg, h.global_position])
	t.check(Progress.has_star("castle/keep"), "the keep's star is found")
	play.autopilot = t._hands_off
	await t._until(func(): return not h.is_locked(), 3.0)


## The star on a cloud: from the west tower's top, jump from cloud to cloud.
func _clouds(play: Play) -> void:
	var isle := play.level as CastleIsle
	var h := play.hero
	var c: Array = []
	for i in CastleIsle.CLOUDS.size():
		c.append(CastleIsle.CLOUDS[i][0])
	var pilot := CoursePilot.new([
		{"to": Vector3(-17.2, isle.tower_top, -37.6), "jump": "jump", "aim": c[0]},
		{"to": (c[0] as Vector3) + Vector3(0.6, 0, -1.0), "jump": "jump", "aim": c[1]},
		{"to": (c[1] as Vector3) + Vector3(0.8, 0, -0.8), "jump": "jump", "aim": c[2],
			"until": func(_p): return Progress.has_star("castle/cloud")},
		{"to": c[2], "until": func(_p): return Progress.has_star("castle/cloud")},
	])
	h.place(Vector3(-16.5, isle.tower_top + 0.05, -36.0), Vector3.FORWARD)
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return pilot.done, 20.0), "the clouds lead to the star (stuck at leg %d, %s)" % [pilot.leg, h.global_position])
	t.check(Progress.has_star("castle/cloud"), "the cloud's star is found")
	play.autopilot = t._hands_off
	await t._until(func(): return not h.is_locked(), 3.0)


## Thud's catapult on the bastion: ground pound it and it breaks.
func _catapult(play: Play) -> void:
	var isle := play.level as CastleIsle
	var h := play.hero
	t.check(t._find_star(isle, "castle/catapult") == null, "the catapult's star isn't there while it throws")
	h.place(isle.catapult.global_position + Vector3.UP * 3.0)
	await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
	t.check(isle.catapult.is_wrecked, "a ground pound wrecks the catapult")
	var star := t._find_star(isle, "castle/catapult")
	t.check(star != null, "the wrecked catapult leaves a star")
	if star:
		await t._until(func(): return not h.is_locked(), 2.0)
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("castle/catapult"), 2.0), "the catapult's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)


## The gem in the hollow behind the west tower's banner.
func _banner_gem(play: Play) -> void:
	var h := play.hero
	var pilot := CoursePilot.new([
		{"to": Vector3(-16.5, CastleIsle.WARD, -33.5), "walk": true},
		{"to": Vector3(-16.5, CastleIsle.WARD, -35.9), "walk": true, "until": func(_p): return Progress.has_gem("castle/gem_banner")},
	])
	h.place(Vector3(-13.5, CastleIsle.WARD + 0.05, -31.0), Vector3.LEFT)
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return pilot.done, 10.0), "the gem behind the banner can be reached (stuck at leg %d, %s)" % [pilot.leg, h.global_position])
	t.check(Progress.has_gem("castle/gem_banner"), "the banner's gem is found")
	play.autopilot = t._hands_off


# --- The Siege Tower -----------------------------------------------------------

## The Siege Tower: its door on the island stays shut until five Sky Castle
## stars are found, and the hero can beat it by running over its gangway
## while it reloads and ground pounding its deck (driven by _fight()), for
## its star. Falling off the wall comes back at the arena's flag.
func _boss() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("castle", "adventure")
	await t._ticks(6)
	var door := _boss_door(play)
	t.check(door != null and not door.is_open(), "the Siege Tower's door is shut at first")
	if door:
		play.hero.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
		await t._ticks(6)
		t.check(play.level.nearest_talker() == door, "the Siege Tower's door can be tried")
		door.talk()
		t.check(not play._leaving, "the shut door doesn't let you in")
	await t._free(play)
	for id in ["castle/ramparts", "castle/drawbridge", "castle/spire", "castle/siege"]:
		Progress.add_star(id)
	play = t._make_play("castle", "adventure")
	await t._ticks(6)
	door = _boss_door(play)
	t.check(door != null and not door.is_open(), "four stars aren't enough")
	await t._free(play)
	Progress.add_star("castle/keep")
	play = t._make_play("castle", "adventure")
	await t._ticks(6)
	door = _boss_door(play)
	t.check(door != null and door.is_open() and door.talk_text() == "Face The Siege Tower", "five stars open the Siege Tower's door")
	await t._free(play)
	# The fight.
	play = t._make_play("siege_tower", "adventure")
	await t._ticks(6)
	var arena := play.level as CastleSiegeArena
	var tower := arena.tower
	t.check(play.hero.is_on_floor(), "the hero lands on the castle wall")
	t.check(tower != null and tower.health == 3, "the Siege Tower has three hearts")
	var hits := [0]
	tower.health_changed.connect(func(_h, _m): hits[0] += 1)
	var early := [false]
	play.autopilot = _fight
	t.check(await t._until(func():
		# It's only ever open with its gangway down on the wall.
		early[0] = early[0] or (tower.open and tower.act != CastleSiegeTower.Act.OPEN)
		return tower.beaten, 150.0), "the hero beats the Siege Tower (%d hits, health %d)" % [hits[0], tower.health])
	t.check(not early[0], "it's only open while its gangway is down")
	t.check(tower.open_count >= 3, "it stops to reload with its gangway down (%d times)" % tower.open_count)
	play.autopilot = t._hands_off
	var star := t._find_star(arena, "castle/boss")
	t.check(star != null, "beating it drops its star")
	if star:
		await t._until(func(): return not play.hero.is_locked() and play.hero.is_on_floor(), 4.0)
		t.check(play.hero.global_position.z > CastleSiegeArena.EDGE_Z and play.hero.global_position.y > -0.5, "the last hit throws the hero back onto the wall")
		play.hero.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("castle/boss"), 2.0), "the Siege Tower's star is found")
	t.check(Worlds.is_open("station"), "beating the Siege Tower opens Star Station")
	# Over the edge onto the road, the hero comes back at the flag.
	await t._until(func(): return not play.hero.is_locked(), 3.0)
	play.hero.place(Vector3(0, 0.5, CastleSiegeArena.EDGE_Z - 1.5))
	await t._until(func(): return play.hero.global_position.z > 0.0, 3.0)
	t.check(play.hero.global_position.distance_to(arena.spawn) < 3.5, "falling off the wall comes back at the arena's flag")
	t._fast(false)
	await t._free(play)


static func _boss_door(play: Play) -> BossDoor:
	for d in play.level.find_children("*", "BossDoor", true, false):
		return d as BossDoor
	return null


## A stand-in player for the fight: while the tower rolls, wait on the wall
## by the gap it's heading for and step out of every red ring; once its
## gangway is down, run up it, jump and ground pound the deck.
func _fight(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if play.speech_open():
		play._next_line()
		return
	var arena := play.level as CastleSiegeArena
	var tower := arena.tower
	if h.is_locked() or tower.beaten:
		return
	h.input.run = true
	h.input.jump_held = true
	var p := h.global_position
	if not h.is_on_floor():
		# Over the deck: pound once the jump tops out.
		if tower.open and p.z < -6.2 and h.velocity.y < 1.5 and not h.is_pounding():
			h.input.crouch_pressed = true
		return
	if tower.open:
		var x := tower.position.x
		if p.y > CastleSiegeTower.DECK_Y - 0.3 and p.z < -6.4:
			h.input.jump = true
			h.input.move = Vector3.FORWARD * 0.3
		elif absf(p.x - x) > 0.4 and p.z > CastleSiegeArena.EDGE_Z + 0.6:
			h.input.move = _toward(p, Vector3(x, 0, CastleSiegeArena.EDGE_Z + 1.4))
		else:
			h.input.move = _toward(p, Vector3(x, 0, -7.0))
		return
	# Wait by the gap it's rolling to, out of the way of the stones.
	var wait := Vector3(tower.next_stop(), 0, CastleSiegeArena.EDGE_Z + 2.6)
	var away := Vector3.ZERO
	for n in arena.find_children("*", "CastleShot", true, false):
		var shot := n as CastleShot
		var d := p - shot.target
		d.y = 0.0
		if d.length() < CastleShot.RING_RADIUS + 1.2:
			away += d.normalized() / maxf(d.length(), 0.3) if d.length() > 0.05 else Vector3.RIGHT
	if away.length() > 0.01:
		h.input.move = away.normalized()
		return
	if p.distance_to(wait) > 0.4:
		h.input.move = _toward(p, wait)


static func _toward(from: Vector3, to: Vector3) -> Vector3:
	var d := to - from
	d.y = 0.0
	return d.normalized() * clampf(d.length() / 1.2, 0.3, 1.0)


# --- Rampart Run ---------------------------------------------------------------

## True while the flail's arm is over the wall's west half and will stay
## there long enough to run past it on the east side.
static func _flail_clear(play: Play) -> bool:
	var run := play.level as CastleRampartRun
	var a := fposmod(run.flail._arm.rotation_degrees.y, 360.0)
	return a > 170.0 and a < 255.0


## The same for the last flail, which turns the other way.
static func _last_flail_clear(play: Play) -> bool:
	var run := play.level as CastleRampartRun
	var a := fposmod(run.last_flail._arm.rotation_degrees.y, 360.0)
	return a > 280.0 and a < 355.0


## True when the last bolt has crossed the bastion and the next is a while off.
static func _bolt_gap(play: Play) -> bool:
	var run := play.level as CastleRampartRun
	return run.ballista._t > 0.5 and run.ballista._t < 2.0


## The pilot's way along the walls: up the stairs, jump the gap, pass the
## flail on its far side, long jump the broken stretch, cross the bastion
## between bolts, run over the crumbling stones and past the last flail to
## the flag.
func _ramparts() -> Array:
	var w := CastleRampartRun.WALK
	return [
		{"to": Vector3(0, 0, -1.0)},
		{"to": Vector3(0, w, -7.0)},
		{"to": Vector3(0, w, -17.3), "jump": "jump", "aim": Vector3(0.3, w, -21.6)},
		{"to": Vector3(0.75, w, -21.8), "when": _flail_clear},
		{"to": Vector3(0.75, w, -29.0)},
		{"to": Vector3(-1.5, w, -33.0)},
		{"to": Vector3(-5.4, w, -33.0), "jump": "long", "aim": Vector3(-13.5, w, -33.0)},
		{"to": Vector3(-17.0, w, -34.0)},
		{"to": Vector3(-18.0, w, -44.2), "when": _bolt_gap},
		{"to": Vector3(-18.0, w, -52.5)},
		{"to": Vector3(-17.25, w, -62.8), "when": _last_flail_clear},
		{"to": Vector3(-17.25, w, -70.0)},
		{"to": Vector3(-18.0, w, -75.5)},
	]


# --- Drawbridge Dash -------------------------------------------------------------

## A test for "when": drawbridge `i` of the course is down for long enough
## to cross.
static func _bridge_down(i: int, seconds: float) -> Callable:
	return func(play: Play) -> bool:
		return ((play.level as CastleDrawbridgeDash).bridges[i] as CastleDrawbridge).is_down_for(seconds)


static func _gate_open(i: int) -> Callable:
	return func(play: Play) -> bool:
		return ((play.level as CastleDrawbridgeDash).gates[i] as CastlePortcullis).is_open_for(0.6)


## The pilot's way from gate to gate: wait at each bridge for it to come
## down, dash under each portcullis while it's up, and catch the wave.
func _drawbridge() -> Array:
	var cz := CastleDrawbridgeDash.CAUSEWAY_Z
	var wx := CastleDrawbridgeDash.WAVE_X
	return [
		{"to": Vector3(0, 0, -2.6), "when": _bridge_down(0, 1.3)},
		{"to": Vector3(0, 0, -14.4), "when": _bridge_down(1, 1.3)},
		{"to": Vector3(1.0, 0, -24.5)},
		{"to": Vector3(6.5, 0, cz)},
		{"to": Vector3(12.5, 0, cz), "when": _gate_open(0)},
		{"to": Vector3(19.5, 0, cz), "when": _gate_open(1)},
		{"to": Vector3(28.6, 0, cz)},
		{"to": Vector3(wx, 0, -28.6), "when": _bridge_down(2, 1.1)},
		{"to": Vector3(wx, 0, -35.6), "when": _bridge_down(3, 1.1)},
		{"to": Vector3(wx, 0, -42.6), "when": _bridge_down(4, 1.1)},
		{"to": Vector3(wx, 0, -53.0)},
	]


# --- Spire Climb -------------------------------------------------------------------

## True while the flail on the second terrace points well away from the
## way past it, and will for long enough to run by.
static func _spire_flail_clear(play: Play) -> bool:
	var a := fposmod((play.level as CastleSpireClimb).flail._arm.rotation_degrees.y, 360.0)
	return a > 140.0 and a < 300.0


## True when the last bolt has crossed the third terrace and the next is a
## while off.
static func _spire_bolt_gap(play: Play) -> bool:
	var b := (play.level as CastleSpireClimb).ballista
	return b._t > 0.45 and b._t < b.period - 0.6

## The pilot's way up: the stairs, kicks up the first chimney, a jump to the
## next terrace, up the crumbling stones, the spring, the second chimney and
## a last jump to the flag.
func _spire() -> Array:
	var c := CastleSpireClimb
	var steps: Array = CastleSpireClimb.STEPS
	return [
		{"to": Vector3(0, 0, -0.6)},
		{"to": Vector3(0, c.T1, -6.5)},
		{"to": Vector3(0, c.T1, -10.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": c.T2 + 0.9, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > c.T2 - 0.1},
		{"to": Vector3(-1.6, c.T2, -9.1)},
		{"to": Vector3(-1.6, c.T2, -10.6), "jump": "jump", "aim": Vector3(-1.0, c.T2, -15.0)},
		{"to": Vector3(0.8, c.T2, -15.6), "when": _spire_flail_clear},
		{"to": Vector3(0.8, c.T2, -21.4), "jump": "jump", "aim": steps[0]},
		{"to": steps[0] + Vector3(0, 0, -0.8), "jump": "jump", "aim": steps[1]},
		{"to": steps[1] + Vector3(0, 0, -0.8), "jump": "jump", "aim": steps[2]},
		{"to": steps[2] + Vector3(0, 0, -0.8), "jump": "jump", "aim": Vector3(0.5, c.T3, -33.5)},
		{"to": Vector3(0, c.T3, -34.2), "when": _spire_bolt_gap},
		{"to": Vector3(0, c.T3, -37.4)},
		{"to": Vector3(0, c.T3, -38.2), "walk": true, "until": func(p): return p.hero.velocity.y > 12.0},
		{"to": Vector3(0, c.T4, -43.0), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > c.T4 - 0.1},
		{"to": Vector3(0, c.T4, -46.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": c.T5 + 0.9, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > c.T5 - 0.1},
		{"to": Vector3(-1.6, c.T5, -45.1)},
		{"to": Vector3(-1.6, c.T5, -46.6), "jump": "jump", "aim": Vector3(-1.0, c.T5, -51.0)},
		{"to": Vector3(0, c.T5, -53.0)},
	]


# --- Siege Gauntlet ----------------------------------------------------------------

## True if no bolt from `b` crosses the hero's line between `from` and `to`
## seconds from now, a bolt taking `fly` seconds from firing to cross it.
static func _lane_clear(b: CastleBallista, fly: float, from: float, to: float) -> bool:
	for k in range(-1, 3):
		var cross := (b.period - b._t) + k * b.period + fly
		if cross > from - 0.15 and cross < to + 0.15:
			return false
	return true


## True when a run from the mouth of the alley passes each ram's lane while
## that ram is rolled back (the lanes are about 0.55 s apart at a run).
static func _rams_back(play: Play) -> bool:
	var rams := (play.level as CastleSiegeGauntlet).rams
	for i in rams.size():
		if not rams[i].is_back_for(0.45, 0.15 + 0.555 * i):
			return false
	return true


static func _bolts_clear(play: Play) -> bool:
	var b := (play.level as CastleSiegeGauntlet).ballistae
	var fly := (5.5 - 1.1 * b[0].model_scale) / b[0].speed
	return _lane_clear(b[0], fly, 0.3, 0.6) and _lane_clear(b[1], fly, 0.85, 1.15)


## True when no trebuchet stone lands on the walk's spots as a run from the
## top of the stairs passes each of them.
static func _stones_clear(play: Play) -> bool:
	var tb := (play.level as CastleSiegeGauntlet).trebuchet
	var n := tb.spots.size()
	var passing := [[0.27, 0.67], [0.93, 1.33], [1.56, 1.96]]
	for k in range(-2, 4):
		var lands := (tb.period - tb._t) + k * tb.period + tb.flight
		var spot := posmod(tb._next_spot + k, n)
		var w: Array = passing[spot]
		if lands > float(w[0]) - 0.12 and lands < float(w[1]) + 0.12:
			return false
	return true


## The pilot's way through the camp: straight up the field (the stones land
## behind) over the trench, through the alley when the rams line up, across
## the causeway between bolts, up onto the wall and along it between the
## trebuchet's stones to the flag.
func _siege() -> Array:
	var w := CastleSiegeGauntlet.WALK
	return [
		{"to": Vector3(0, 0, -15.6), "jump": "jump", "aim": Vector3(0, 0, -21.5)},
		{"to": Vector3(0, 0, -30.0)},
		{"to": Vector3(0, 0, -33.0), "when": _rams_back},
		{"to": Vector3(0, 0, -49.0)},
		{"to": Vector3(0, 0, -52.6), "when": _bolts_clear},
		{"to": Vector3(0, 0, -67.0)},
		{"to": Vector3(0, w, -73.6), "when": _stones_clear},
		{"to": Vector3(0, w, -92.5)},
	]
