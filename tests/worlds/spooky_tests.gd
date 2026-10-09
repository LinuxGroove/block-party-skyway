extends RefCounted
## Spooky Hollow's tests, run by tests/run_tests.gd: the island's stars,
## the Night Keeper, and the course pilot's way through each course
## (legs(), see tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"crypt_creep":
			return _crypt_creep()
		"ghost_bridge":
			return _ghost_bridge()
		"pumpkin_patch":
			return _pumpkin_patch()
		"haunted_tower":
			return _haunted_tower()
	return []


## Spooky Hollow's island (Hazel's lanterns, the silver rush, the chapel
## ghosts, the bell tower, the lost grave, both hidden gems, the boss door,
## a course door and falling off), then the Night Keeper.
func run() -> void:
	await _island()
	await _keeper()


func _island() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("spooky", "adventure")
	await t._ticks(10)
	var isle := play.level as SpookyHollow
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Spooky Hollow")
	var doors := isle.find_children("*", "BossDoor", true, false)
	var boss_door: BossDoor = doors[0] if not doors.is_empty() else null
	t.check(boss_door != null and not boss_door.is_open(), "the Night Keeper's door is shut at first")
	if boss_door:
		h.place(boss_door.global_position + boss_door.facing * 1.2 + Vector3.UP * 0.05)
		await t._ticks(4)
		boss_door.talk()
		t.check(not play._leaving, "a shut boss door doesn't open")
		await t._ticks(2)

	# Hazel's lanterns: she asks, then each one lights at a touch.
	h.place(isle.hazel.global_position + Vector3(1.0, 0.1, 0))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.hazel, "Hazel is there to talk to")
	isle.hazel.talk()
	t.check(play.speech_open(), "Hazel asks for the lanterns to be lit")
	while play.speech_open():
		play._next_line()
	# The tomb's lantern: stomp the zombie by it, then jump up onto the tomb.
	var zombie := _nearest_critter(isle, Vector3(6, 1, -16))
	h.place(zombie.global_position + Vector3.UP * 2.0)
	t.check(await t._until(func(): return _beaten(zombie), 2.0), "landing on a zombie beats it")
	await t._until(func(): return h.is_on_floor(), 2.0)
	var climbed := await t._pilot(play, [
		{"to": Vector3(5, 1, -16.4)},
		{"to": Vector3(5, 1, -17.0), "jump": "jump", "aim": Vector3(5, 2.56, -19.7)},
	], 10.0)
	t.check(climbed and isle.lanterns_lit == 1, "a jump reaches the tomb's lantern, and it lights (%d)" % isle.lanterns_lit)
	for l in isle.lanterns:
		if not l.is_lit:
			h.place(l.global_position + Vector3.UP * 0.1)
			await t._until(func(): return l.is_lit, 1.0)
	t.check(isle.lanterns_lit == 4, "all four lanterns light")
	t.check(await t._until(func(): return play.speech_open(), 2.0), "Hazel thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	await _collect(play, SpookyHollow.LANTERN_STAR, "Hazel gives a star for the lanterns")

	# The silver rush: step on the button, then grab the eight coins.
	await t._until(func(): return not h.is_locked(), 3.0)
	h.place(isle.silver.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.silver.time_left > 0.0, 1.0), "the button starts the silver rush")
	for c in isle.silver.coins.duplicate():
		if is_instance_valid(c):
			h.place(c.global_position - Vector3.UP * 0.2)
			await t._ticks(6)
	await _collect(play, "spooky/silver", "eight silver coins give a star")

	# The chapel ghosts: ground pound each one.
	await t._until(func(): return not h.is_locked(), 3.0)
	for g in isle.ghosts:
		var ghost := g
		for tries in 3:
			if _beaten(ghost):
				break
			h.place(_critter_at(ghost, 0.42) + Vector3.UP * 3.0)
			await t._drive(h, 40, func(inp, i): inp.crouch_pressed = i == 1)
		t.check(_beaten(ghost), "a ground pound beats a chapel ghost")
	await t._until(func(): return h.is_on_floor(), 2.0)
	await _collect(play, SpookyHollow.GHOST_STAR, "beating the chapel ghosts gives a star")

	# The bell tower: up the tomb and the ledges, onto the sinking slab, then
	# kick up between the tower and the wall.
	await t._until(func(): return not h.is_locked(), 3.0)
	h.place(Vector3(17, 1.05, -12.0), Vector3.FORWARD)
	await t._ticks(4)
	t.check(await t._pilot(play, _bell_tower_legs(), 25.0), "the bell tower can be climbed for its star")
	t.check(Progress.has_star("spooky/tower"), "the bell tower's star is found")

	# The lost grave: down the ledges below the chapel's cliff.
	await t._until(func(): return not h.is_locked(), 3.0)
	h.place(Vector3(24.0, 0.05, 8.0), Vector3.BACK)
	await t._ticks(4)
	t.check(await t._pilot(play, [
		{"to": Vector3(25.2, 0, 9.4), "jump": "jump", "aim": Vector3(27.0, -1.0, 12.0)},
		{"to": Vector3(27.6, -1.0, 12.6), "jump": "jump", "aim": Vector3(30.0, -2.0, 15.0)},
		{"to": Vector3(30.6, -2.0, 15.6), "jump": "jump", "aim": Vector3(31.2, -3.0, 18.8)},
		{"to": Vector3(33.5, -3.0, 20.0), "until": func(_p): return Progress.has_star("spooky/lost_grave")},
	], 20.0), "the lost grave's ledges can be hopped down")
	t.check(Progress.has_star("spooky/lost_grave"), "the lost grave's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	t.check(boss_door != null and boss_door.is_open(), "five stars open the Night Keeper's door")

	# The hidden gems: a long jump out to the swamp islet, and the strong
	# crate behind the knoll's pine.
	h.place(Vector3(-31, -0.95, -12.0), Vector3.FORWARD)
	await t._ticks(6)
	t.check(await t._pilot(play, [
		{"to": Vector3(-31, -1.0, -17.2), "jump": "long", "aim": Vector3(-31, -0.6, -25.0)},
		{"to": Vector3(-31, -0.6, -25.0), "until": func(_p): return Progress.has_gem("spooky/gem_swamp")},
	], 10.0), "a long jump reaches the swamp islet")
	t.check(Progress.has_gem("spooky/gem_swamp"), "the swamp islet's gem is found")
	var crate: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "gem:spooky/gem_knoll":
			crate = b
	t.check(crate != null, "the knoll has a strong crate")
	if crate:
		h.place(crate.global_position + Vector3.UP * 3.0)
		await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		t.check(not is_instance_valid(crate), "a ground pound breaks the strong crate")
		t.check(await t._until(func(): return Progress.has_gem("spooky/gem_knoll"), 3.0), "the crate's gem is found")

	# A course door, and what's left to find.
	var door: CourseDoor = null
	for d in isle.find_children("*", "CourseDoor", true, false):
		if (d as CourseDoor).course_id == "crypt_creep":
			door = d
	h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == door, "the Crypt Creep door can be used")
	var left := 0
	for id in Worlds.star_ids("spooky"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("spooky"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(isle.secrets_left() == left, "secrets left counts what's still hidden (%d)" % isle.secrets_left())
	# Falling into the swamp costs a heart and comes back at the last flag.
	play.hearts = Play.MAX_HEARTS
	h.place(Vector3(-26, 0.5, -20))
	t.check(await t._until(func(): return play.hearts == Play.MAX_HEARTS - 1, 3.0), "falling in the swamp costs a heart")
	await t._ticks(3)
	t.check(h.global_position.y > -1.2, "and comes back at the last flag")
	t._fast(false)
	await t._free(play)


## The Night Keeper: the hero runs rings round him (the flames miss), steps
## out of the ring when he winds up, and jumps on him each time his shovel
## sticks. Three hits beat him and drop the star.
func _keeper() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("night_keeper", "adventure")
	await t._ticks(10)
	var k := (play.level as SpookyKeeperArena).keeper
	var h := play.hero
	t.check(k != null and not k.open and k.health == 3, "the Night Keeper starts closed, with three hearts")
	var hurts := [0]
	play.level.hurt.connect(func(_f): hurts[0] += 1)
	play.autopilot = _dodge
	t.check(await t._until(func(): return k.phase == SpookyNightKeeper.Phase.THROW, 8.0), "he throws lantern flames")
	var slam_hurts := 0
	var stomp_hurts := 0
	for i in 3:
		play.autopilot = _dodge
		var wound := await t._until(func(): return k.phase == SpookyNightKeeper.Phase.WINDUP, 15.0)
		t.check(wound and k._ring.visible, "he raises his shovel, and a ring shows where it'll land (%d)" % i)
		t.check(not k.open, "he can't be hit while he winds up")
		await t._until(func(): return k.phase == SpookyNightKeeper.Phase.LEAP, 3.0)
		var before: int = hurts[0]
		t.check(await t._until(func(): return k.open, 2.0), "the shovel sticks and he's open (%d)" % i)
		await t._ticks(2)
		slam_hurts += hurts[0] - before
		# Run over and jump on him.
		before = hurts[0]
		play.autopilot = t._hands_off
		var health := k.health
		await t._pilot(play, [
			{"to": func(p): return _beside(k, p.hero, 2.2), "jump": "jump",
				"aim": func(p, _s): return k.global_position if k.health == health else _beside(k, p.hero, 4.0)},
		], 4.0)
		t.check(k.health == health - 1, "jumping on him while his shovel's stuck is a hit (%d of 3)" % (i + 1))
		await t._until(func(): return h.is_on_floor(), 2.0)
		stomp_hurts += hurts[0] - before
		play.hearts = Play.MAX_HEARTS
	t.check(slam_hurts == 0, "stepping out of the ring dodges the slam (%d)" % slam_hurts)
	t.check(stomp_hurts == 0, "the hero bounces off a hit unhurt (%d)" % stomp_hurts)
	t.check(k.beaten, "three hits beat the Night Keeper")
	play.autopilot = t._hands_off
	await t._ticks(30)
	await _collect(play, "spooky/boss", "beating the Night Keeper drops a star")
	t._fast(false)
	await t._free(play)


## The way up the island's bell tower, from the terrace south of it.
static func _bell_tower_legs() -> Array:
	return [
		{"to": Vector3(17, 1, -13.6), "jump": "high", "aim": Vector3(17, 3.5, -16.0)},
		{"to": Vector3(17.6, 3.5, -16.0), "jump": "double", "aim": Vector3(21.0, 6.0, -17.0)},
		{"to": Vector3(21.0, 6.0, -16.4), "walk": true},
		{"to": Vector3(21.0, 6.0, -17.6), "jump": "jump", "aim": Vector3(21.0, 7.0, -21.2)},
		{"to": Vector3(19.4, 7.0, -21.5)},
		{"wall": true, "toward": Vector3.BACK, "top": 12.4, "off": Vector3.BACK,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 11.8},
		{"to": Vector3(18, 12, -19), "walk": true, "until": func(_p): return Progress.has_star("spooky/tower")},
	]


## Runs the hero round the arena in a ring, so flames thrown at where they
## were miss, and a slam aimed at them lands behind.
func _dodge(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	if play.speech_open():
		play._next_line()
		return
	var flat := Vector3(h.global_position.x, 0, h.global_position.z)
	var out := flat.normalized() if flat.length() > 0.1 else Vector3.BACK
	var round_dir := out.cross(Vector3.UP)
	h.input.move = (round_dir + out * clampf((6.5 - flat.length()) * 0.6, -1.0, 1.0)).normalized()
	h.input.run = true


## A spot `gap` from the keeper on the hero's side of him.
static func _beside(k: SpookyNightKeeper, h: Hero, gap: float) -> Vector3:
	var away := Vector3(h.global_position.x - k.global_position.x, 0, h.global_position.z - k.global_position.z)
	if away.length() < 0.1:
		away = -k.facing
	return k.global_position + away.normalized() * gap


## Waits for a star to appear, walks into it, and checks it's found.
func _collect(play: Play, id: String, what: String) -> void:
	await t._until(func(): return t._find_star(play.level, id) != null, 3.0)
	var star := t._find_star(play.level, id)
	t.check(star != null, what)
	if star:
		play.hero.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star(id), 2.0), "%s is found" % id)


static func _beaten(c: Critter) -> bool:
	return not is_instance_valid(c) or c.defeated


## The critter nearest a spot.
static func _nearest_critter(level: Level, at: Vector3) -> Critter:
	var best: Critter = null
	for n in level.find_children("*", "Critter", true, false):
		var c := n as Critter
		if best == null or c.global_position.distance_to(at) < best.global_position.distance_to(at):
			best = c
	return best


## Where a patrolling critter will be `ahead` seconds from now.
static func _critter_at(c: Critter, ahead: float) -> Vector3:
	var u := (1.0 - cos(TAU * (c._t + ahead) / c.period)) / 2.0
	return c._start + c.travel * u


# --- Shared ------------------------------------------------------------------

## True if a crusher stays at least `clear` up for the next `seconds`, so
## the hero can run under it.
static func _stays_up(c: Crusher, seconds: float, clear := 1.05) -> bool:
	var dt := 0.0
	while dt <= seconds:
		if c.offset_at(c._t + dt) < clear:
			return false
		dt += 0.05
	return true


## The spinner's arm heading in degrees, 0 to 360 (0 points south, +z).
static func _arm_angle(s: Spinner) -> float:
	return fposmod(s._arm.rotation_degrees.y, 360.0)


## True if the hero, running in a straight line from `from` to `to` starting
## now, stays clear of the spinner's arms, with `margin` to spare.
static func _spinner_clear(s: Spinner, from: Vector3, to: Vector3, margin := 0.5) -> bool:
	var centre := s.global_position
	var dir := Vector3(to.x - from.x, 0, to.z - from.z)
	var total := dir.length()
	dir = dir.normalized()
	var dt := 0.0
	var gone := 0.0
	while gone < total:
		var run := maxf(dt - 0.05, 0.0)
		gone = 0.5 * Hero.GROUND_ACCEL * run * run if run < 0.21 else 0.76 + Hero.RUN_SPEED * (run - 0.21)
		var at := from + dir * minf(gone, total) - centre
		at.y = 0.0
		for a in s.arms:
			var turn := deg_to_rad(_arm_angle(s) + s.speed * dt) + TAU * a / s.arms
			var along := Vector3(sin(turn), 0, cos(turn))
			var d := at.dot(along)
			if d > -0.3 and d < s.length + 0.8 + margin and (at - along * d).length() < 0.6 + margin:
				return false
		dt += 0.03
	return true


## True if a patrolling critter stays more than `half` from the racing
## line (x = `line`, or z = `line` with `axis` 2) from `from` seconds ahead
## to `seconds` ahead, or is already beaten.
static func _clear_of(c: Critter, seconds: float, half: float, axis := 0, line := 0.0, from := 0.0) -> bool:
	if not is_instance_valid(c) or c.defeated:
		return true
	var dt := from
	while dt <= seconds:
		var u := (1.0 - cos(TAU * (c._t + dt) / c.period)) / 2.0
		if absf(c._start[axis] + c.travel[axis] * u - line) < half:
			return false
		dt += 0.05
	return true


# --- Crypt Creep -------------------------------------------------------------

static func _skeleton(play: Play, i: int) -> Critter:
	return (play.level as SpookyCryptCreep).skeletons[i]


static func _lid(play: Play, i: int) -> SpookyCryptLid:
	return (play.level as SpookyCryptCreep).lids[i]


## The pilot's way through Crypt Creep: hop the stone tops, wait under each
## lid for it to lift and dash through, jump up the first roof, wait for the
## pumpkin arm to swing away, jump to the second roof, and hop the coffins
## east to the flag.
func _crypt_creep() -> Array:
	return [
		{"to": Vector3(-1, 0, -5.6), "jump": "jump", "aim": Vector3(-1, 0, -8.0)},
		{"to": Vector3(-0.6, 0, -9.6), "jump": "jump", "aim": Vector3(1, 0.5, -13.2)},
		{"to": Vector3(0.6, 0.5, -14.6), "jump": "jump", "aim": Vector3(-1, 1.0, -18.2)},
		{"to": Vector3(-0.6, 1.0, -19.6), "jump": "jump", "aim": Vector3(0, 1.0, -22.8)},
		{"to": Vector3(0, 1.0, -23.4), "when": func(p): return _stays_up(_lid(p, 0), 0.75)},
		{"to": Vector3(0, 1.0, -27.75), "when": func(p): return _stays_up(_lid(p, 1), 0.75)},
		{"to": Vector3(0, 1.0, -32.25), "when": func(p): return _stays_up(_lid(p, 2), 0.75)},
		{"to": Vector3(0, 1.0, -39.0), "when": func(p): return _clear_of(_skeleton(p, 0), 0.9, 1.6)},
		{"to": Vector3(0, 1.0, -43.0), "jump": "jump", "aim": Vector3(0, 1.0, -46.0)},
		{"to": Vector3(0, 1.0, -46.0), "when": func(p): return _clear_of(_skeleton(p, 1), 0.7, 1.6)},
		{"to": Vector3(0, 1.0, -48.4), "jump": "jump", "aim": Vector3(0, 2.5, -51.6)},
		{"to": Vector3(0.5, 2.5, -52.6), "when": func(p): return _arm_angle((p.level as SpookyCryptCreep).spinner) > 70.0 and _arm_angle((p.level as SpookyCryptCreep).spinner) < 200.0},
		{"to": Vector3(0.8, 2.5, -55.5), "jump": "jump", "aim": Vector3(1.6, 4.0, -58.9)},
		{"to": Vector3(2.5, 4.0, -60.0), "jump": "jump", "aim": Vector3(4.9, 2.5, -60.0)},
		{"to": Vector3(5.5, 2.5, -60.0), "jump": "jump", "aim": Vector3(7.9, 2.5, -60.0)},
		{"to": Vector3(8.5, 2.5, -60.0), "jump": "jump", "aim": Vector3(10.9, 2.5, -60.0)},
		{"to": Vector3(11.5, 2.5, -60.0), "jump": "jump", "aim": Vector3(14.0, 1.0, -60.0)},
		{"to": Vector3(20.5, 1.0, -60.0)},
	]


# --- Ghost Bridge ------------------------------------------------------------

static func _bridge(play: Play) -> SpookyGhostBridge:
	return play.level as SpookyGhostBridge


## Where the raft will be `ahead` seconds from now.
static func _raft_at(play: Play, ahead: float) -> Vector3:
	var r := _bridge(play).raft
	return r._start + r.offset_at(r._t + ahead)


## The pilot's way across Ghost Bridge: wait for the first ghost to pass,
## run the sinking planks and jump to the islet, wait for the lantern arm
## to swing past, run west between the two ghosts, ride the raft, jump to
## the far bank and slip between the last two ghosts to the flag.
func _ghost_bridge() -> Array:
	return [
		{"to": Vector3(0, 0, -5.5), "when": func(p): return _clear_of(_bridge(p).ghosts[0], 1.1, 1.3)},
		{"to": Vector3(0, 0, -24.9), "jump": "jump", "aim": Vector3(-1.0, 0, -29.0)},
		{"to": Vector3(-1.0, 0, -29.1), "when": func(p): return _arm_angle(_bridge(p).spinner) > 15.0 and _arm_angle(_bridge(p).spinner) < 190.0},
		{"to": Vector3(-4.6, 0, -33.0), "when": func(p): return _clear_of(_bridge(p).ghosts[1], 0.9, 1.1, 2, -33.0, 0.2) and _clear_of(_bridge(p).ghosts[2], 1.6, 1.1, 2, -33.0, 1.0)},
		{"to": Vector3(-16.4, 0, -33.0), "when": func(p): return _raft_at(p, 0.0).x > -18.75},
		{"to": func(p): return _raft_at(p, 0.0) + Vector3(-0.6, 0, 0), "until": func(p): return _raft_at(p, 0.0).x < -24.0},
		{"to": func(p): return _raft_at(p, 0.0) + Vector3(-1.1, 0, 0), "jump": "jump", "aim": Vector3(-29.0, 0.5, -33.0)},
		{"to": Vector3(-29.4, 0.5, -33.0), "when": func(p): return _clear_of(_bridge(p).ghosts[3], 0.7, 1.1, 2, -33.0, 0.1) and _clear_of(_bridge(p).ghosts[4], 1.15, 1.1, 2, -33.0, 0.5)},
		{"to": Vector3(-38.0, 0.5, -33.0)},
	]


# --- Pumpkin Patch -----------------------------------------------------------

static func _patch(play: Play) -> SpookyPumpkinPatch:
	return play.level as SpookyPumpkinPatch


## True if no pumpkin from `r` comes within `half` of x = 0 (the racing
## line) from `from` to `to` seconds ahead, counting pumpkins not yet rolled.
static func _row_clear(r: SpookyPumpkinRoller, from: float, to: float, half := 1.05) -> bool:
	var shots: Array = []
	for p in r.rolled:
		if is_instance_valid(p) and p.monitoring:
			shots.append([p.global_position.x, 0.0, p.velocity.x])
	var t := r.next_shot()
	while t <= to:
		shots.append([r.global_position.x + r.direction.x, t, r.direction.x * r.speed])
		t += r.period
	var dt := from
	while dt <= to:
		for shot in shots:
			if dt >= shot[1] and absf(shot[0] + shot[2] * (dt - shot[1])) < half:
				return false
		dt += 0.05
	return true


## True if each bobbing pumpkin's top stays up while the pilot is on it,
## going now: on pumpkin k from `land` + `hop` * k seconds for `stay`.
static func _bobbers_ok(play: Play, land: float, hop: float, stay: float) -> bool:
	var list := _patch(play).bobbers
	for k in list.size():
		var dt := land + hop * k
		while dt <= land + hop * k + stay:
			if list[k].top_at(dt) < -0.15:
				return false
			dt += 0.05
	return true


## The zombie in the gate, or where it stood once it's beaten.
static func _gatekeeper_at(play: Play) -> Vector3:
	var z := _patch(play).gatekeeper
	return z.global_position if is_instance_valid(z) else Vector3(-24.0, 0.5, -38.0)


static func _bob_top(play: Play, k: int, ahead: float) -> Vector3:
	var b := _patch(play).bobbers[k]
	return Vector3(b._start.x, b.top_at(ahead), b._start.z)


## The pilot's way through Pumpkin Patch: wait for a gap in the rolling
## pumpkins and run up the field, hop the bobbing pumpkins as they rise,
## jump on the zombie in the gate, slip between the vampires and run to the
## flag.
func _pumpkin_patch() -> Array:
	return [
		{"to": Vector3(0, 0, -5.5), "when": func(p): return _row_clear(_patch(p).rollers[0], 0.4, 0.95) and _row_clear(_patch(p).rollers[1], 1.1, 1.65) and _row_clear(_patch(p).rollers[2], 1.8, 2.35)},
		{"to": Vector3(0, 0, -25.5)},
		{"to": Vector3(-2.0, 0, -29.0), "when": func(p): return _bobbers_ok(p, 1.0, 0.85, 0.4)},
		{"to": Vector3(-4.6, 0, -29.0), "jump": "jump", "aim": func(p, s): return _bob_top(p, 0, s)},
		{"to": func(p): return _bob_top(p, 0, 0.0), "jump": "jump", "aim": func(p, s): return _bob_top(p, 1, s)},
		{"to": func(p): return _bob_top(p, 1, 0.0), "jump": "jump", "aim": func(p, s): return _bob_top(p, 2, s)},
		{"to": func(p): return _bob_top(p, 2, 0.0), "jump": "jump", "aim": func(p, s): return _bob_top(p, 3, s)},
		{"to": func(p): return _bob_top(p, 3, 0.0), "jump": "jump", "aim": Vector3(-21.6, 0.5, -29.0)},
		{"to": Vector3(-24.0, 0.5, -33.0)},
		{"to": Vector3(-24.0, 0.5, -35.4), "jump": "jump", "aim": func(p, _s): return _gatekeeper_at(p)},
		{"to": Vector3(-24.0, 0.5, -39.5), "when": func(p): return _clear_of(_patch(p).vampires[0], 0.95, 1.0, 0, -24.0, 0.35) and _clear_of(_patch(p).vampires[1], 1.55, 1.0, 0, -24.0, 1.0)},
		{"to": Vector3(-24.0, 0.5, -52.0)},
	]


# --- Haunted Tower -----------------------------------------------------------

static func _tower(play: Play) -> SpookyHauntedTower:
	return play.level as SpookyHauntedTower


## Where the lift will be `ahead` seconds from now.
static func _lift_at(play: Play, ahead: float) -> Vector3:
	var l := _tower(play).lift
	return l._start + l.offset_at(l._t + ahead)


## Into the draught, then over onto the roof once it has lifted the hero
## high enough.
static func _draught_aim(play: Play, _s: float) -> Vector3:
	if play.hero.global_position.y < SpookyHauntedTower.ROOF + 1.0:
		return Vector3(-6.5, 11.0, -5.0)
	return Vector3(-4.2, SpookyHauntedTower.ROOF, -6.8)


## The pilot's way up the Haunted Tower: jump up the ledges once the ghost
## has drifted by, kick up the chimney, hop the crumbling ledges, ride the
## draught onto the roof, run past the lantern arm and ride the lift up to
## the flag.
func _haunted_tower() -> Array:
	var roof := SpookyHauntedTower.ROOF
	return [
		{"to": Vector3(-3.3, 0, -1.0), "jump": "jump", "aim": Vector3(-3.6, 1.6, -4.9)},
		{"to": Vector3(-4.3, 1.6, -4.7), "when": func(p): return _clear_of(_tower(p).ghost, 1.4, 0.9, 2, -5.0, 0.4)},
		{"to": Vector3(-2.3, 1.6, -5.0), "jump": "jump", "aim": Vector3(0.3, 3.2, -5.0)},
		{"to": Vector3(2.5, 3.2, -5.0), "jump": "jump", "aim": Vector3(5.0, 4.8, -5.0)},
		{"to": Vector3(7.5, 4.8, -5.0)},
		{"to": Vector3(7.5, 4.8, -7.4)},
		{"wall": true, "toward": Vector3.RIGHT, "top": 11.0, "off": Vector3.RIGHT, "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 10.3},
		{"to": Vector3(9.2, 10.5, -6.8)},
		{"to": Vector3(9.4, 10.5, -5.5), "walk": true},
		{"to": Vector3(8.3, 10.5, -5.4), "jump": "jump", "aim": Vector3(5.6, 11.0, -5.0)},
		{"to": Vector3(5.0, 11.0, -5.0), "jump": "jump", "aim": Vector3(2.6, 11.0, -5.0)},
		{"to": Vector3(2.0, 11.0, -5.0), "jump": "jump", "aim": Vector3(-0.4, 11.0, -5.0)},
		{"to": Vector3(-1.0, 11.0, -5.0), "jump": "jump", "aim": Vector3(-3.8, 11.0, -5.0)},
		{"to": Vector3(-4.5, 11.0, -5.0), "jump": "jump", "aim": _draught_aim},
		{"to": Vector3(-4.2, roof, -6.8), "when": func(p): return _spinner_clear(_tower(p).spinner, p.hero.global_position, Vector3(5.0, roof, -7.2))},
		{"to": Vector3(5.0, roof, -7.2), "when": func(p): return _lift_at(p, 0.5).y < roof + 0.1},
		{"to": func(p): return _lift_at(p, 0.0), "until": func(p): return _lift_at(p, 0.0).y > SpookyHauntedTower.BELFRY - 0.15},
		{"to": Vector3(5.0, SpookyHauntedTower.BELFRY, -12.6)},
	]
