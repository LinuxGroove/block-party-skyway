extends RefCounted
## Pirate Cove's tests, run by tests/run_tests.gd: the island's stars, Polly
## and the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"dockdash":
			return _dockdash()
		"cannoncove":
			return _cannoncove()
		"wreckclimb":
			return _wreckclimb()
		"riggingrun":
			return _riggingrun()
	return []


## Pirate Cove: the island's stars, then Polly.
func run() -> void:
	await _island()
	await _boss()


# --- The island -----------------------------------------------------------------

## Who the hero is running after, for _chase().
var _quarry: Node3D


## Runs straight at `_quarry`, for catching Rascal.
func _chase(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if play.speech_open() or h.is_locked():
		return
	var to := _quarry.global_position - h.global_position
	to.y = 0.0
	h.input.move = to.normalized() if to.length() > 0.05 else Vector3.ZERO
	h.input.run = true


static func _boss_door(isle: Island) -> BossDoor:
	var doors := isle.find_children("*", "BossDoor", true, false)
	return null if doors.is_empty() else doors[0] as BossDoor


static func _isle_barrel(play: Play, i: int) -> PirateBarrel:
	return (play.level as PirateCove).barrels[i]


static func _isle_boat(play: Play, i: int) -> PirateBoat:
	return (play.level as PirateCove).boats[i]


## Lets the pilot run `legs` from `from`; true once it's done.
func _run_legs(play: Play, from: Vector3, face: Vector3, legs: Array, seconds: float) -> CoursePilot:
	var pilot := CoursePilot.new(legs)
	play.hero.place(from, face)
	play.autopilot = pilot.drive
	await t._until(func(): return pilot.done, seconds)
	play.autopilot = t._hands_off
	return pilot


## Picks up a star that's appeared, standing on it.
func _collect(play: Play, id: String) -> bool:
	var star := t._find_star(play.level, id)
	if star == null:
		return false
	await t._until(func(): return not play.hero.is_locked(), 3.0)
	play.hero.place(star.global_position - Vector3.UP * 0.4)
	var ok: bool = await t._until(func(): return Progress.has_star(id), 2.0)
	await t._until(func(): return not play.hero.is_locked(), 3.0)
	return ok


## The island: Polly's door shut, Rascal, the silver rush, the lookout,
## Skull Rock, Banjo's treasure, the gem in the ship's barrel, the door
## open at five stars, and falling in the sea.
func _island() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("pirate", "adventure")
	await t._ticks(10)
	var isle := play.level as PirateCove
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Pirate Cove")
	var door := _boss_door(isle)
	t.check(door != null and not door.is_open(), "Polly's door is shut at first")

	# Rascal: Kip asks, and the hero runs the fox down.
	h.place(isle.kip.global_position + Vector3(0.6, 0.1, -0.9))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.kip, "Kip is there to talk to")
	isle.kip.talk()
	t.check(play.speech_open(), "Kip tells of the fox")
	while play.speech_open():
		play._next_line()
	_quarry = isle.rascal
	play.autopilot = _chase
	t.check(await t._until(func(): return isle.rascal.is_caught, 25.0), "running after Rascal catches him (fox at %s)" % isle.rascal.global_position)
	play.autopilot = t._hands_off
	t.check(await t._until(func(): return play.speech_open(), 2.0), "Rascal gives up")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	t.check(await _collect(play, "pirate/rascal"), "Rascal hands over Kip's star")

	# The silver rush, run on foot from the button.
	h.place(isle.silver.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.silver.time_left > 0.0, 1.0), "the button starts the silver rush")
	var pilot := CoursePilot.new(_silver_legs())
	play.autopilot = pilot.drive
	var rushed := await t._until(func(): return isle.silver.got >= PirateCove.SILVER_SPOTS.size() or not isle.silver.is_running(), PirateCove.SILVER_TIME + 2.0)
	play.autopilot = t._hands_off
	t.check(rushed and isle.silver.got == PirateCove.SILVER_SPOTS.size(), "all eight silver coins can be run down in time (%d, %.1f s left, leg %d at %s)" % [isle.silver.got, isle.silver.time_left, pilot.leg, h.global_position])
	t.check(await _collect(play, "pirate/silver"), "the silver coins give a star")

	# The lookout: barrels, ledges round the tower, and over the battlements.
	pilot = await _run_legs(play, PirateCove.TOWER + Vector3(-2.6, 0.05, 4.0), Vector3.FORWARD, _lookout_legs(), 20.0)
	t.check(Progress.has_star("pirate/lookout"), "the lookout can be climbed for its star (leg %d at %s)" % [pilot.leg, h.global_position])

	# Skull Rock, over the bobbing barrels behind the big rock.
	pilot = await _run_legs(play, Vector3(-11.5, 0.05, 11.4), Vector3.LEFT, _skull_legs(), 25.0)
	t.check(Progress.has_star("pirate/skull"), "the barrels lead to Skull Rock's star (leg %d at %s)" % [pilot.leg, h.global_position])

	# Banjo's treasure: out to the sandbar on a rowing boat, then pound the X.
	h.place(isle.banjo.global_position + Vector3(0.8, 0.1, -0.8))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.banjo, "Banjo is there to talk to")
	isle.banjo.talk()
	t.check(play.speech_open() and isle.talked_banjo, "Banjo tells of his treasure")
	while play.speech_open():
		play._next_line()
	pilot = await _run_legs(play, Vector3(10, 0.05, 12.5), Vector3.BACK, _sandbar_legs(), 25.0)
	t.check(pilot.done, "a rowing boat carries the hero to the sandbar (leg %d at %s)" % [pilot.leg, h.global_position])
	_hop = Vector3.ZERO
	_pound_at = 14
	await t._drive(h, 60, _jump_and_pound)
	t.check(isle.dig.is_dug, "a ground pound on the X digs up the chest")
	t.check(await t._until(func(): return t._find_star(isle, "pirate/treasure") != null, 2.0), "the chest holds a star")
	t.check(await _collect(play, "pirate/treasure"), "Banjo's treasure star is found")

	# The gem in a barrel on the moored ship's deck: climb aboard, pound it.
	pilot = await _run_legs(play, Vector3(-18, 0.05, 1.25), Vector3.LEFT, _ship_legs(), 15.0)
	t.check(pilot.done, "the hero climbs aboard the moored ship (leg %d at %s)" % [pilot.leg, h.global_position])
	_hop = Vector3.BACK
	_pound_at = 20
	await t._drive(h, 60, _jump_and_pound)
	pilot = CoursePilot.new([{"to": Vector3(-31.0, 2.28, 5.0), "until": func(_p): return Progress.has_gem("pirate/gem_barrel")}])
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return Progress.has_gem("pirate/gem_barrel"), 3.0), "a barrel on deck hides a gem (at %s)" % h.global_position)
	play.autopilot = t._hands_off

	# The gem on the wreck's stern deck.
	pilot = await _run_legs(play, Vector3(3.1, 0.05, -25.0), Vector3.FORWARD, _wreck_legs(), 15.0)
	t.check(Progress.has_gem("pirate/gem_wreck"), "the wreck's stern deck has a gem (leg %d at %s)" % [pilot.leg, h.global_position])

	# Five stars open Polly's door.
	t.check(isle.world_stars() == 5, "the island has five stars (%d)" % isle.world_stars())
	t.check(door != null and door.is_open(), "five stars open Polly's door")
	var left := 0
	for id in Worlds.star_ids("pirate"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("pirate"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(isle.secrets_left() == left, "secrets left counts what's still hidden (%d)" % isle.secrets_left())

	# Falling in the sea costs a heart and comes back at the last flag.
	await t._until(func(): return not h.is_locked(), 3.0)
	play.hearts = Play.MAX_HEARTS
	h.place(Vector3(-20, 0.5, -15))
	t.check(await t._until(func(): return play.hearts == Play.MAX_HEARTS - 1, 3.0), "falling in the sea costs a heart")
	await t._ticks(10)
	t.check(h.global_position.y > -0.1 and h.global_position.distance_to(Vector3(-20, 0, -15)) > 3.0, "and comes back at the last flag (%s)" % h.global_position)
	t._fast(false)
	await t._free(play)


## The silver rush on foot: along the dock to the fort, round by the tower,
## back over the dune and up the sandbar, across the beach to the ship's
## dock, and out along the pier.
static func _silver_legs() -> Array:
	return [
		{"to": Vector3(24, 0, 1.25)},
		{"to": Vector3(28.5, 1, 1.25)},
		{"to": Vector3(35, 1, 0)},
		{"to": Vector3(43, 1, -9)},
		{"to": Vector3(30, 1, 1.25)},
		{"to": Vector3(14, 0, 1.25)},
		{"to": Vector3(8, 0, -4.3), "jump": "jump", "aim": Vector3(8, 0.5, -7.6)},
		{"to": Vector3(1, 0, -9.6)},
		{"to": Vector3(1.2, 0, -13.5)},
		{"to": Vector3(0, 0, -10.6)},
		{"to": Vector3(-10, 0, -8)},
		{"to": Vector3(-13.5, 0, 1.25)},
		{"to": Vector3(-22, 0, 1.25)},
		{"to": Vector3(-13, 0, 1.25)},
		{"to": Vector3(10.5, 0, 6.5)},
		{"to": Vector3(10, 0, 11.5)},
		{"to": Vector3(10, 0, 16)},
	]


## Up the lookout: onto the barrels, then a double jump to each ledge (the
## north one gives way) and over the battlements.
static func _lookout_legs() -> Array:
	var t := PirateCove.TOWER
	var top := PirateCove.TOWER_TOP
	return [
		{"to": t + Vector3(-2.6, 0, 2.7), "jump": "jump", "aim": t + Vector3(-2.6, 1.2, 1.0)},
		{"to": t + Vector3(-2.6, 1.2, 0.8), "jump": "double", "aim": t + Vector3(-2.3, 2.6, -1.4)},
		{"to": t + Vector3(-2.2, 2.6, -1.6), "jump": "double", "aim": t + PirateCove.FALLING_LEDGE},
		{"to": t + PirateCove.FALLING_LEDGE + Vector3(0.3, 0, 0.2), "jump": "double", "aim": t + Vector3(2.3, 6.6, 1.2)},
		{"to": t + Vector3(2.4, 6.6, 1.9), "jump": "double", "aim": t + Vector3(-1.0, 8.5, 2.6)},
		{"to": t + Vector3(-1.0, 8.5, 2.3), "jump": "jump", "aim": t + Vector3(-0.2, top, 0.0),
			"until": func(_p): return Progress.has_star("pirate/lookout")},
	]


## Out to Skull Rock: from the beach behind the big rock over the five
## bobbing barrels, onto the rock beside it, and up to the top.
static func _skull_legs() -> Array:
	var legs := [
		{"to": Vector3(-13.6, 0, 11.7), "jump": "jump", "aim": func(p, s): return _isle_barrel(p, 0).top_at(s)},
	]
	for i in range(1, PirateCove.BARREL_SPOTS.size()):
		legs.append({"to": func(p): return _isle_barrel(p, i - 1).top_at(), "jump": "jump", "aim": func(p, s): return _isle_barrel(p, i).top_at(s)})
	legs.append({"to": func(p): return _isle_barrel(p, 4).top_at(), "jump": "jump", "aim": Vector3(-28.2, 0, 26.0)})
	legs.append({"to": Vector3(-28.8, 0, 28.4), "jump": "jump", "aim": Vector3(-28.8, 1.0, 31.2)})
	legs.append({"to": Vector3(-28.8, 1.0, 31.2), "jump": "double", "aim": Vector3(-31.2, 3.3, 30.5),
		"until": func(_p): return Progress.has_star("pirate/skull")})
	return legs


## Down the pier, onto a rowing boat when it comes in, a ride out, and a
## hop to the sandbar, then to the X.
static func _sandbar_legs() -> Array:
	return [
		{"to": Vector3(10.4, 0, 16.6), "when": func(p): return _isle_boat(p, 1).seat_at(0.6).x < 11.2},
		{"to": Vector3(10.4, 0, 16.9), "jump": "jump", "aim": func(p, s): return _isle_boat(p, 1).seat_at(s)},
		{"to": func(p): return _isle_boat(p, 1).seat_at(), "until": func(p): return _isle_boat(p, 1).seat_at(0.5).x > 17.0},
		{"to": func(p): return _isle_boat(p, 1).seat_at() + Vector3(0.5, 0, 0), "jump": "jump", "aim": Vector3(20.6, 0, 19)},
		{"to": Vector3(25, 0, 20), "when": func(_p): return true},
	]


## From the ship's dock onto the barrel, over the rail to the deck, up to
## the stern deck, and to the barrel with the gem in it.
static func _ship_legs() -> Array:
	return [
		{"to": Vector3(-24.2, 0, 1.25), "jump": "jump", "aim": Vector3(-25.6, 1.1, 1.25)},
		{"to": Vector3(-25.5, 1.1, 1.25), "jump": "double", "aim": Vector3(-29.3, 1.34, 2.0)},
		{"to": Vector3(-30.4, 1.34, 1.7), "when": func(_p): return true},
		{"to": Vector3(-30.4, 1.34, 2.2), "jump": "jump", "aim": Vector3(-30.6, 2.28, 4.0)},
		{"to": Vector3(-31.0, 2.28, 3.6), "when": func(_p): return true},
	]


## Onto the wreck by the crate and the barrel at the gap in her rail, round
## the hatch, and up her stairs to the stern deck.
static func _wreck_legs() -> Array:
	return [
		{"to": Vector3(3.1, 0, -26.6), "jump": "jump", "aim": Vector3(3.1, 0.7, -28.2)},
		{"to": Vector3(2.9, 0.7, -28.2), "jump": "jump", "aim": Vector3(1.6, 1.1, -28.6)},
		{"to": Vector3(1.5, 1.1, -28.7), "jump": "jump", "aim": Vector3(1.4, 1.94, -30.9)},
		{"to": Vector3(-0.4, 1.94, -31.6)},
		{"to": Vector3(-0.4, 1.94, -34.3), "when": func(_p): return true},
		{"to": Vector3(-0.9, 1.94, -34.3), "jump": "double", "aim": Vector3(-3.6, 3.9, -34.1),
			"until": func(_p): return Progress.has_gem("pirate/gem_wreck")},
	]


## Jumps and ground pounds `_pound_at` ticks later, moving toward `_hop`
## till then (onto a barrel beside the hero, or straight down on the X).
var _hop := Vector3.ZERO
var _pound_at := 14


func _jump_and_pound(inp: HeroInput, i: int) -> void:
	inp.jump = i == 0
	inp.jump_held = i < 8
	inp.move = _hop if i < _pound_at else Vector3.ZERO
	inp.crouch_pressed = i == _pound_at


# --- Polly ---------------------------------------------------------------------

## Legs for dodging in the fight: laps round the mainmast while Polly
## throws, so her cannonballs land behind.
static func _dodge() -> Array:
	var corners := [Vector3(-2.2, 0, 1.0), Vector3(2.2, 0, 1.0), Vector3(2.2, 0, -2.6), Vector3(-2.2, 0, -2.6)]
	var legs := []
	for i in 80:
		legs.append({"to": corners[i % 4]})
	return legs


## A spot `d` metres from Polly on the hero's side.
static func _from_polly(polly: PiratePolly, h: Hero, d: float) -> Vector3:
	var away := h.global_position - polly.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.1 else Vector3.BACK
	return polly.global_position + away * d


static func _flat_dist(a: Node3D, b: Node3D) -> float:
	return Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()


## Legs for a stomp, as a player would: back off if too close, then run at
## her and jump from three metres, to come down on her back.
static func _stomp(polly: PiratePolly, h: Hero) -> Array:
	return [
		{"to": func(_p): return _from_polly(polly, h, 4.6), "until": func(_p): return _flat_dist(polly, h) >= 4.2},
		{"to": func(_p): return _from_polly(polly, h, 3.0), "jump": "jump", "aim": func(_p, _s): return polly.global_position + Vector3.UP * 1.3},
	]


## Polly's ship: she throws cannonballs with warning rings, lands to reload,
## and three jumps on her while she's reloading beat her, the way a player
## would: dodging about the deck, then running at her and jumping.
func _boss() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("polly", "adventure")
	await t._ticks(10)
	var arena := play.level as PiratePollyShip
	var polly := arena.polly
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Polly's deck")
	t.check(polly.health == 3 and not polly.open, "Polly starts with three hearts, out of reach")
	t.check(await t._until(func(): return polly.state == PiratePolly.State.FLY, 4.0), "Polly takes off")
	# The pilot is kept in a variable: autopilot's Callable doesn't keep it.
	var pilot := CoursePilot.new(_dodge())
	play.autopilot = pilot.drive
	t.check(await t._until(func(): return not polly.shells.is_empty(), 4.0), "she throws cannonballs")
	if not polly.shells.is_empty():
		t.check(polly.shells[0].time_left() > 1.0, "each one's ring shows where it lands, well before")
		t.check(not polly.open, "she can't be hit while she's flying")
	var landings := 0
	var hits := 0
	while landings < 6 and not polly.beaten:
		pilot = CoursePilot.new(_dodge())
		play.autopilot = pilot.drive
		if not await t._until(func(): return polly.open, 20.0):
			break
		landings += 1
		var before := polly.health
		pilot = CoursePilot.new(_stomp(polly, h))
		play.autopilot = pilot.drive
		if await t._until(func(): return polly.health < before, 4.0):
			hits += 1
		await t._until(func(): return not polly.open, 4.0)
	t.check(landings >= 3, "Polly lands to reload again and again (%d)" % landings)
	t.check(hits == 3, "a jump on her while she reloads is a hit (%d hits in %d landings)" % [hits, landings])
	play.autopilot = t._hands_off
	t.check(polly.beaten, "three hits beat Polly")
	await t._ticks(4)
	var star := t._find_star(arena, "pirate/boss")
	t.check(star != null, "beating Polly gives a star")
	if star:
		await t._until(func(): return not h.is_locked(), 3.0)
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("pirate/boss"), 2.0), "Polly's star is found")
	t._fast(false)
	await t._free(play)


# --- Dock Dash ----------------------------------------------------------------

static func _boat(play: Play, i: int) -> PirateBoat:
	return (play.level as PirateDockDash).boats[i]


static func _barrel(play: Play, i: int) -> PirateBarrel:
	return (play.level as PirateDockDash).barrels[i]


## The pilot's way through Dock Dash: hop the missing planks, run the
## wharf between the crabs, skip over the falling planks, ride the boats
## when they line up, hop the barrels, jump the crab and the gaps in the
## boardwalk, and run to the flag.
func _dockdash() -> Array:
	var legs := [
		{"to": Vector3(0, 0, -7.6), "jump": "jump", "aim": Vector3(0, 0, -10.6)},
		{"to": Vector3(0, 0, -11.6), "jump": "jump", "aim": Vector3(0, 0, -14.6)},
		{"to": Vector3(0, 0, -15.6), "jump": "jump", "aim": Vector3(0, 0, -20.0)},
		{"to": Vector3(0, 0, -26.1), "jump": "jump", "aim": Vector3(0, 0, -28.2)},
		{"to": Vector3(0, 0, -28.7), "jump": "jump", "aim": Vector3(0, 0, -31.2)},
		{"to": Vector3(0, 0, -31.7), "jump": "jump", "aim": Vector3(0, 0, -34.2)},
		{"to": Vector3(0, 0, -34.7), "jump": "jump", "aim": Vector3(0, 0, -37.8)},
		{"to": Vector3(0, 0, -40.3), "when": func(p): return absf(_boat(p, 0).seat_at(0.75).x) < 0.8},
		{"to": Vector3(0, 0, -40.8), "jump": "jump", "aim": func(p, s): return _boat(p, 0).seat_at(s)},
		{"to": func(p): return _boat(p, 0).seat_at() + Vector3(0, 0, -0.5), "jump": "jump", "aim": func(p, s): return _boat(p, 1).seat_at(s)},
		{"to": func(p): return _boat(p, 1).seat_at() + Vector3(0, 0, -0.5), "jump": "jump", "aim": Vector3(0, 0, -53.5)},
		{"to": Vector3(-0.9, 0, -55.6), "jump": "jump", "aim": func(p, s): return _barrel(p, 0).top_at(s)},
	]
	for i in range(1, 4):
		legs.append({"to": func(p): return _barrel(p, i - 1).top_at(), "jump": "jump", "aim": func(p, s): return _barrel(p, i).top_at(s)})
	legs.append({"to": func(p): return _barrel(p, 3).top_at(), "jump": "jump", "aim": Vector3(-16.3, 0, -56)})
	legs.append({"to": Vector3(-16.9, 0, -56), "jump": "jump", "aim": Vector3(-21.8, 0, -56)})
	legs.append({"to": Vector3(-23.6, 0, -56), "jump": "jump", "aim": Vector3(-26.8, 0, -56)})
	legs.append({"to": Vector3(-28.6, 0, -56), "jump": "jump", "aim": Vector3(-31.8, 0, -56)})
	legs.append({"to": Vector3(-37.6, 0, -56)})
	return legs


# --- Cannon Cove --------------------------------------------------------------

static func _cove(play: Play) -> PirateCannonCove:
	return play.level as PirateCannonCove


## True in the quiet spell after `cannon`'s shot has gone by.
static func _quiet(cannon: PirateCannon, from: float, to: float) -> bool:
	return cannon.since_shot() >= from and cannon.since_shot() <= to


## The pilot's way through Cannon Cove: wait for each gangway cannon's
## shot, double jump aboard the moored ship and off its far side, then wait
## for the broadside's first shot and run straight up the pier behind the
## wave, then hop the rafts without stopping, so the shells land behind.
func _cannoncove() -> Array:
	var legs := [
		{"to": Vector3(0, 0, -5.0), "when": func(p): return _quiet(_cove(p).gangway_cannons[0], 0.35, 1.3)},
		{"to": Vector3(0, 0, -10.0), "when": func(p): return _quiet(_cove(p).gangway_cannons[1], 0.35, 1.3)},
		{"to": Vector3(1.5, 0, -15.5)},
		{"to": Vector3(1.5, 0, -17.2), "jump": "double", "aim": Vector3(1.5, PirateCannonCove.DECK, -22.2)},
		{"to": Vector3(1.0, PirateCannonCove.DECK, -23.4), "jump": "jump", "aim": Vector3(0.3, 0, -29.0)},
		{"to": Vector3(0, 0, -29.0), "when": func(p): return _quiet(_cove(p).wave[0], 0.4, 0.6)},
		{"to": Vector3(0, 0, -56.8)},
	]
	for x in PirateCannonCove.RAFT_X:
		legs.append({"to": Vector3(x + 3.15, 0, PirateCannonCove.LANE_Z), "jump": "jump", "aim": Vector3(x - 0.15, 0, PirateCannonCove.LANE_Z)})
	legs.append({"to": Vector3(-27.1, 0, PirateCannonCove.LANE_Z), "jump": "jump", "aim": Vector3(-30.2, 0, PirateCannonCove.LANE_Z)})
	legs.append({"to": Vector3(-33.6, 0, PirateCannonCove.LANE_Z)})
	return legs


# --- Shipwreck Climb ----------------------------------------------------------

static func _climb(play: Play) -> PirateWreckClimb:
	return play.level as PirateWreckClimb


static func _lift(play: Play) -> MovingPlatform:
	return _climb(play).lift


## Where the top of the salvage lift will be in `ahead` seconds.
static func _lift_top(play: Play, ahead := 0.0) -> Vector3:
	var lift := _lift(play)
	return lift._start + lift.offset_at(lift._t + ahead)


## True while the spinner's arm is swinging away from the way up the foot.
static func _arm_clear(play: Play) -> bool:
	var a := wrapf(_climb(play).spinner._arm.rotation_degrees.y, -180.0, 180.0)
	return a > -30.0 and a < 40.0


## True while `critter` stays out of the x range from `lo` to `hi` (with a
## little room to spare) for the next `secs` seconds.
static func _clear_of(critter: Critter, lo: float, hi: float, secs := 0.45) -> bool:
	if not is_instance_valid(critter) or critter.defeated:
		return true
	for k in 10:
		var t := critter._t + secs * k / 9.0
		var x := critter._start.x + critter.travel.x * (1.0 - cos(TAU * t / critter.period)) / 2.0
		if x > lo - 0.75 and x < hi + 0.75:
			return false
	return true


## The pilot's way up Shipwreck Climb: up the reef rocks, over the old
## planks, past the swinging cannonballs once they've gone by, kick up the
## chimney, then wait for each parrot to fly off before crossing.
func _wreckclimb() -> Array:
	var foot := PirateWreckClimb.FOOT
	var top := PirateWreckClimb.SUMMIT
	var x := PirateWreckClimb.WALK_X
	return [
		{"to": Vector3(0, 0, -2.6), "jump": "jump", "aim": Vector3(0, 1.5, -6.0)},
		{"to": Vector3(0, 1.5, -7.6), "jump": "jump", "aim": Vector3(0, 3.0, -10.5)},
		{"to": Vector3(0, 3.0, -13.6), "jump": "jump", "aim": Vector3(0, 3.5, -16.5)},
		{"to": Vector3(0, 3.5, -17.0), "jump": "jump", "aim": Vector3(0, 4.0, -19.5)},
		{"to": Vector3(0, 4.0, -20.0), "jump": "jump", "aim": Vector3(-0.5, foot, -22.6)},
		{"to": Vector3(-0.5, foot, -22.6), "when": func(p): return _arm_clear(p)},
		{"to": Vector3(-0.5, foot, -32.0)},
		{"wall": true, "toward": Vector3.RIGHT, "top": PirateWreckClimb.CHIMNEY_TOP + 1.1, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > PirateWreckClimb.CHIMNEY_TOP - 0.1},
		{"to": Vector3(x, top, -34.4), "when": func(p): return _clear_of(_climb(p).parrots[0], x - 1.0, x + 1.0)},
		{"to": Vector3(x, top, -37.25), "when": func(p): return _clear_of(_climb(p).parrots[1], x - 1.0, x + 1.0)},
		{"to": Vector3(x, top, -39.75), "when": func(p): return _clear_of(_climb(p).parrots[2], x - 1.0, x + 1.0)},
		{"to": Vector3(x, top, -48.0), "when": func(p): return _lift(p).position.y < top + 1.2,
			"jump": "jump", "aim": func(p, s): return _lift_top(p, s)},
		{"to": func(p): return _lift_top(p), "until": func(p): return _lift(p).position.y > PirateWreckClimb.TOP - 0.1},
		{"to": Vector3(x, PirateWreckClimb.TOP, -55.5)},
	]


# --- Rigging Run --------------------------------------------------------------

static func _rig(play: Play) -> PirateRiggingRun:
	return play.level as PirateRiggingRun


## Where the top of the cargo crate will be in `ahead` seconds, and how far
## along its swing it is then (0 at the second ship, 1 at the flagship).
static func _crate_top(play: Play, ahead := 0.0) -> Vector3:
	var c := _rig(play).crate
	return c._start + c.offset_at(c._t + ahead)


static func _crate_along(play: Play) -> float:
	var c := _rig(play).crate
	return (1.0 - cos(TAU * c._t / c.period)) / 2.0


## True while the boom on the second ship's maintop is round the far side
## of the mast from the way across it.
static func _boom_clear(play: Play) -> bool:
	var a := fposmod(_rig(play).boom._arm.rotation_degrees.y, 360.0)
	return a > 180.0 and a < 300.0


## The pilot's way through Rigging Run: over to the first foretop, along
## the planks once the parrot has flown by, up to the maintop, over the
## falling plank, into the gust, a double jump to the second maintop when
## the boom is round the far side, onto the cargo crate and off at the
## flagship, past the second parrot and down to the flag.
func _riggingrun() -> Array:
	var al := PirateRiggingRun.ALOFT
	var z1: float = PirateRiggingRun.SHIP_Z[0]
	var z2: float = PirateRiggingRun.SHIP_Z[1]
	var z3: float = PirateRiggingRun.SHIP_Z[2]
	var fore := PirateRiggingRun.FORE
	var main := PirateRiggingRun.MAIN
	var mizzen := PirateRiggingRun.MIZZEN
	return [
		{"to": Vector3(0, al, -5.6), "jump": "jump", "aim": Vector3(0.9, al, z1 + fore - 0.9)},
		{"to": Vector3(0.3, al, z1 + fore - 2.1), "when": func(p): return _clear_of(_rig(p).parrots[0], -1.0, 1.0)},
		{"to": Vector3(0.3, al, z1 + main + 1.9), "jump": "jump", "aim": Vector3(1.0, al + 1.5, z1 + main + 0.6)},
		{"to": Vector3(1.0, al + 1.5, z1 + main - 1.1), "jump": "jump", "aim": Vector3(0.6, al + 1.5, z1 + (main + mizzen) / 2.0)},
		{"to": Vector3(0.6, al + 1.5, z1 + (main + mizzen) / 2.0 - 0.3), "jump": "jump", "aim": Vector3(1.0, al + 1.5, z1 + mizzen + 1.0)},
		{"to": Vector3(1.0, al + 1.5, z1 + mizzen - 1.2), "jump": "jump", "aim": Vector3(1.0, al, z2 + fore + 1.8)},
		{"to": Vector3(1.0, al, z2 + fore - 1.1), "when": func(p): return _boom_clear(p),
			"jump": "double", "aim": Vector3(1.1, al + 2.5, z2 + main + 1.9)},
		{"to": Vector3(1.1, al + 2.5, z2 + main - 2.7), "jump": "jump", "aim": Vector3(1.0, al + 1.5, z2 + mizzen + 0.8)},
		{"to": Vector3(0.6, al + 1.5, z2 + mizzen - 1.2), "when": func(p): return _crate_along(p) < 0.12,
			"jump": "jump", "aim": func(p, s): return _crate_top(p, s)},
		{"to": func(p): return _crate_top(p), "when": func(p): return _crate_along(p) > 0.93,
			"jump": "jump", "aim": Vector3(0.9, al, z3 + fore + 0.5)},
		{"to": Vector3(0.4, al, z3 + fore - 2.1), "when": func(p): return _clear_of(_rig(p).parrots[1], -1.0, 1.0)},
		{"to": Vector3(1.0, al, z3 + main + 0.9)},
		{"to": Vector3(1.0, al, z3 + main - 1.1), "jump": "jump", "aim": Vector3(1.0, PirateRiggingRun.STERN, z3 + mizzen + 0.8)},
	]
