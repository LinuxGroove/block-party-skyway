extends Node
## Headless tests: run with
##   godot --headless --path . tests/run_tests.tscn
## Options after `--`:
##   --games=N           run each course N times in Speedrun (default 1; the
##                       second run races the first one's ghost)
##   --world=frosty      only the data checks and one world's tests
##   --course=sawmill    only one course's pilot runs
##   --only=_test_moves  one test of this file
## Each world's island and boss tests, and the course pilot's legs through
## its courses, live in tests/worlds/<world>_tests.gd. Prints the pilot's
## time on each course, which the medal times are set from. Exits non-zero
## on failure.

const CoursePilot := preload("res://tests/course_pilot.gd")

var failures := 0
var checks := 0
var games := 1


func _ready() -> void:
	var only := ""
	var only_world := ""
	var only_course := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--games="):
			games = maxi(1, arg.substr(8).to_int())
		elif arg.begins_with("--only="):
			only = arg.substr(7)
		elif arg.begins_with("--world="):
			only_world = arg.substr(8)
		elif arg.begins_with("--course="):
			only_course = arg.substr(9)
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGTheme.apply(get_tree().root)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	# Per process, so test runs side by side (in other checkouts) don't share saves.
	var pid := OS.get_process_id()
	Progress.use_path("user://test-progress-%d.cfg" % pid, "user://test-ghosts-%d/" % pid)
	Progress.wipe()
	if only != "":
		await call(only)
	elif only_course != "":
		var w := str(Courses.get_def(only_course).get("world", ""))
		check(w != "", "%s is a course" % only_course)
		if w != "":
			await _test_course(_world_tests(w), only_course)
	elif only_world != "":
		_test_data()
		_test_world_data(only_world)
		await _test_world(only_world)
	else:
		for t in ["_test_data", "_test_medals", "_test_progress", "_test_ghost"]:
			printerr("- ", t)
			call(t)
		for t in ["_test_moves", "_test_wall_climb", "_test_things", "_test_menus", "_test_skyway"]:
			printerr("- ", t)
			await call(t)
		for w in Worlds.built():
			_test_world_data(w)
			await _test_world(w)
	Progress.wipe()
	DirAccess.remove_absolute(Progress.path)
	DirAccess.remove_absolute(Progress.ghost_dir)
	print("\n%d checks, %d failed" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", what)


## Runs the game four times faster, each tick still 1/60 s of game time.
func _fast(on: bool) -> void:
	Engine.time_scale = 4.0 if on else 1.0
	Engine.physics_ticks_per_second = 240 if on else 60


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


## Waits up to `seconds` of game time for `cond` to become true.
func _until(cond: Callable, seconds: float) -> bool:
	var steps := int(seconds * Engine.physics_ticks_per_second / Engine.time_scale)
	for i in steps:
		if cond.call():
			return true
		await get_tree().physics_frame
	return cond.call()


func _make_play(level_id: String, mode: String, arrive := {}) -> Play:
	var play: Play = load(Play.SCENE).instantiate()
	play.level_id = level_id
	play.mode = mode
	play.arrive = arrive
	add_child(play)
	return play


func _free(n: Node) -> void:
	get_tree().paused = false
	n.queue_free()
	await _frames(3)


# --- Data --------------------------------------------------------------------

## The world list hangs together: every world has data, every course a
## level and a world, and level ids are unique.
func _test_data() -> void:
	check(Worlds.ORDER.size() == 9 and Worlds.ORDER[8] == "star", "eight worlds and the Star Road")
	var seen := {}
	for w in Worlds.ORDER:
		var def := Worlds.get_def(w)
		check(not def.is_empty() and str(def.get("name", "")) != "", "%s has data" % w)
		check(w == "star" or (def.has("boss") and def.boss.has("id") and def.boss.has("star")), "%s has a boss" % w)
		for id in (def.get("levels", {}) as Dictionary):
			check(not seen.has(id), "level id %s is used once" % id)
			seen[id] = true
			check(ResourceLoader.exists(str(def.levels[id])), "%s's script exists" % id)
	check(Worlds.built().has("sunny"), "Sunny Isles is built")
	for id in Courses.ids():
		var def := Courses.get_def(id)
		check(Worlds.star_ids(def.world).has(def.star), "%s's star is in its world" % id)
		check(Worlds.gem_ids(def.world).has(def.gem), "%s's gem is in its world" % id)
		check(Worlds.level_path(id) != "", "%s has a level" % id)


## Every star and gem a world lists is in one of its levels (or handed out
## by one), and nothing else is; the island has a door for every course and
## the boss, and gates to the worlds either side. Courses build for
## Speedrun without the Adventure extras.
func _test_world_data(w: String) -> void:
	printerr("- data: ", w)
	var def := Worlds.get_def(w)
	var stars := {}
	var gems := {}
	for id in def.get("given", []):
		stars[id] = true
	var boss: Dictionary = def.boss
	if (def.levels as Dictionary).has(boss.get("id", "")):
		stars[boss.star] = true
	# A course's flag gives its star.
	for c in Courses.of_world(w):
		if (def.levels as Dictionary).has(c):
			stars[Courses.get_def(c).star] = true
	for id in Levels.of_world(w):
		var level := Levels.make(id, "adventure")
		check(level != null, "%s makes a level" % id)
		if level == null:
			continue
		add_child(level)
		level.build()
		check(level.title != "", "%s has a title" % id)
		for n in level.find_children("*", "Pickup", true, false):
			var p := n as Pickup
			if p.kind == "star":
				stars[p.id] = true
			elif p.kind == "gem":
				gems[p.id] = true
		for n in level.find_children("*", "Breakable", true, false):
			var parts := (n as Breakable).contents.split(":")
			if parts[0] == "star":
				stars[parts[1]] = true
			elif parts[0] == "gem":
				gems[parts[1]] = true
		if id == def.island:
			check(level is Island, "%s's island is an Island" % w)
			var doors := {}
			for d in level.find_children("*", "CourseDoor", true, false):
				doors[(d as CourseDoor).course_id] = d
			for c in Courses.of_world(w):
				check(doors.has(c), "%s has a door to %s" % [id, c])
			if (def.levels as Dictionary).has(boss.get("id", "")):
				check(doors.has(boss.id) and doors[boss.id] is BossDoor, "%s has the boss door" % id)
			var gates := {}
			for g in level.find_children("*", "SkywayGate", true, false):
				gates[(g as SkywayGate).to_world] = true
			for step in [-1, 1]:
				var other := Worlds.neighbour(w, step)
				if other != "":
					check(gates.has(other), "%s has a Skyway gate to %s" % [id, other])
		elif Courses.has(id):
			var course := Levels.make(id, "speedrun")
			add_child(course)
			course.build()
			check(course.find_children("*", "Pickup", true, false).is_empty(), "speedrun %s has no pickups" % id)
			check(course.find_children("*", "Checkpoint", true, false).is_empty(), "speedrun %s has no checkpoints" % id)
			check(course.find_children("*", "FinishFlag", true, false).size() == 1, "%s has one finish flag" % id)
			course.free()
		elif id == boss.get("id", ""):
			check(level is BossArena, "%s is a BossArena" % id)
		level.free()
	var want_stars := Worlds.star_ids(w)
	var want_gems := Worlds.gem_ids(w)
	check(stars.size() == want_stars.size(), "%s places %d stars (has %d: %s)" % [w, want_stars.size(), stars.size(), stars.keys()])
	for id in want_stars:
		check(stars.has(id), "star %s is placed" % id)
	check(gems.size() == want_gems.size(), "%s hides %d gems (has %d)" % [w, want_gems.size(), gems.size()])
	for id in want_gems:
		check(gems.has(id), "gem %s is hidden" % id)


func _test_medals() -> void:
	for id in Courses.ids():
		var times: Array = Courses.get_def(id).medals
		check(times.size() == 4, "%s has four medal times" % id)
		for i in range(1, times.size()):
			check(int(times[i]) < int(times[i - 1]), "%s's medals get faster" % id)
		check(Courses.medal_for(id, int(times[0]) + 1) == 0, "slower than bronze is no medal")
		check(Courses.medal_for(id, int(times[0])) == 1, "bronze on the bronze time")
		check(Courses.medal_for(id, int(times[3]) - 1) == 4, "under Patrol's time is Patrol")
		check(Courses.next_medal(id, 0) == [1, int(times[0])], "the first medal to aim for is bronze")
		check(Courses.next_medal(id, int(times[3])).is_empty(), "nothing after Patrol")
	check(Courses.time_text(41230) == "41.23", "times under a minute")
	check(Courses.time_text(75000) == "1:15.00", "times over a minute")
	check(Courses.time_text(5) == "0.00", "a few milliseconds")


func _test_progress() -> void:
	Progress.wipe()
	check(not Progress.has_started(), "a wiped save hasn't started")
	check(Progress.add_star("sunny/tower"), "a new star is new")
	check(not Progress.add_star("sunny/tower"), "the same star again isn't")
	check(Progress.star_count("sunny") == 1 and Progress.star_count() == 1, "star counts")
	check(Progress.add_gem("sunny/gem_far") and not Progress.add_gem("sunny/gem_far"), "gems count once")
	Progress.add_coins(12)
	Progress.find_course("sawmill")
	check(Progress.course_found("sawmill"), "found courses open in Speedrun")
	check(Progress.record_time("sawmill", 40000), "a first time is a best")
	check(not Progress.record_time("sawmill", 41000), "a slower time isn't")
	check(Progress.record_time("sawmill", 39000), "a faster time is")
	Progress.load_progress()
	check(Progress.best_time("sawmill") == 39000 and Progress.coins == 12 and Progress.has_star("sunny/tower"), "progress survives a reload")
	Progress.new_adventure()
	check(not Progress.has_star("sunny/tower") and Progress.coins == 0 and not Progress.course_found("sawmill"), "a new adventure starts from nothing")
	check(Progress.best_time("sawmill") == 39000, "a new adventure keeps best times")
	Progress.wipe()
	check(Progress.best_time("sawmill") == 0, "wipe forgets best times")


func _test_ghost() -> void:
	var g := Ghost.new()
	g.msec = 1234
	g.hero = 2
	for i in 5:
		g.frames.append_array([i * 1.0, 0.5, -i * 2.0, 0.1 * i, 0.0])
		g.clips.append(i % Ghost.CLIPS.size())
	var back := Ghost.from_bytes(g.to_bytes())
	check(back != null, "a ghost survives saving")
	if back:
		check(back.msec == 1234 and back.hero == 2 and back.sample_count() == 5, "a ghost keeps its time, hero and samples")
		var mid: Dictionary = back.sample(0.5 / Ghost.RATE)
		check((mid.position as Vector3).distance_to(Vector3(0.5, 0.5, -1.0)) < 0.001, "ghost samples blend between frames")
		check(is_equal_approx(back.duration(), 4.0 / Ghost.RATE), "ghost duration")
	check(Ghost.from_bytes(PackedByteArray()) == null, "an empty ghost file is no ghost")
	Progress.save_ghost("test", g)
	check(Progress.load_ghost("test") != null, "ghosts are kept on disk")
	Progress.wipe()
	check(Progress.load_ghost("test") == null, "wipe forgets ghosts")


# --- The hero ----------------------------------------------------------------

## A flat test ground with a 2.5 m block, for measuring the moves.
func _make_ground() -> Array:
	var level := Level.new()
	add_child(level)
	level.land(-30, -30, 30, 30, 0, 2)
	level.land(10, -2, 12, 2, 2.5, 3)
	level.finish()
	var h := Hero.new()
	level.hero = h
	level.add_child(h)
	h.place(Vector3(0, 0.05, 0), Vector3.FORWARD)
	await _ticks(6)
	return [level, h]


## Holds `setup`'s input for `n` ticks (setup gets the HeroInput each tick).
func _drive(h: Hero, n: int, setup: Callable) -> void:
	for i in n:
		await get_tree().physics_frame
		h.input.clear()
		setup.call(h.input, i)


## Jumps with `setup` filling the input each tick until landing; returns
## [highest point above the start, flat distance travelled, jump kind].
func _measure(h: Hero, setup: Callable, max_ticks := 240) -> Array:
	var start := h.global_position
	var top := 0.0
	var kind := ""
	var left := false
	for i in max_ticks:
		await get_tree().physics_frame
		h.input.clear()
		setup.call(h.input, i)
		if h.jump_kind != "":
			kind = h.jump_kind
		top = maxf(top, h.global_position.y - start.y)
		if not h.is_on_floor():
			left = true
		elif left and i > 2:
			break
	var flat := Vector2(h.global_position.x - start.x, h.global_position.z - start.z).length()
	return [top, flat, kind]


func _test_moves() -> void:
	_fast(true)
	var made: Array = await _make_ground()
	var level: Level = made[0]
	var h: Hero = made[1]
	check(h.is_on_floor(), "the hero stands on the ground")
	# Running.
	await _drive(h, 60, func(inp, _i): inp.move = Vector3.FORWARD; inp.run = true)
	check(absf(h.horizontal_speed() - Hero.RUN_SPEED) < 0.1, "running tops out at run speed (%.2f)" % h.horizontal_speed())
	await _drive(h, 40, func(inp, _i): pass)
	check(h.horizontal_speed() < 0.1, "letting go stops the hero")
	# Jump, held.
	var r: Array = await _measure(h, func(inp, i): inp.jump = i == 0; inp.jump_held = true)
	check(r[0] > 1.7 and r[0] < 2.0, "a held jump is about 1.8 m high (%.2f)" % r[0])
	await _ticks(10)
	# A tap is a short hop.
	r = await _measure(h, func(inp, i): inp.jump = i == 0; inp.jump_held = i < 2)
	check(r[0] < 1.5, "a tapped jump is a short hop (%.2f)" % r[0])
	await _ticks(10)
	# Double jump at the top of the first.
	r = await _measure(h, func(inp, i): inp.jump = i == 0 or (i == 20); inp.jump_held = true)
	check(r[0] > 3.0 and r[2] == "double", "a double jump climbs over 3 m (%.2f, %s)" % [r[0], r[2]])
	await _ticks(10)
	# High jump: crouch, then jump.
	await _drive(h, 4, func(inp, _i): inp.crouch = true)
	r = await _measure(h, func(inp, i): inp.crouch = i == 0; inp.jump = i == 0; inp.jump_held = true)
	check(r[0] > 3.0 and r[2] == "high", "a high jump climbs over 3 m (%.2f, %s)" % [r[0], r[2]])
	await _ticks(10)
	# Long jump: run, crouch and jump.
	h.place(Vector3(0, 0.05, 20), Vector3.FORWARD)
	await _drive(h, 50, func(inp, _i): inp.move = Vector3.FORWARD; inp.run = true)
	r = await _measure(h, func(inp, i): inp.move = Vector3.FORWARD; inp.run = true; inp.crouch = i == 0; inp.jump = i == 0; inp.jump_held = true)
	check(r[1] > 7.5 and r[2] == "long", "a long jump goes over 7.5 m (%.2f, %s)" % [r[1], r[2]])
	await _ticks(30)
	# Dive from the air, landing in a belly slide.
	h.place(Vector3(0, 0.05, 20), Vector3.FORWARD)
	await _ticks(4)
	var slid := [false]
	await _drive(h, 60, func(inp, i):
		inp.move = Vector3.FORWARD
		inp.jump = i == 0
		inp.jump_held = true
		inp.dive = i == 12
		if h.state == Hero.State.SLIDE:
			slid[0] = true)
	check(slid[0], "a dive lands in a belly slide")
	await _ticks(40)
	# Ground pound.
	var pounds := [0]
	h.pounded.connect(func(_at): pounds[0] += 1)
	await _drive(h, 70, func(inp, i): inp.jump = i == 0; inp.jump_held = true; inp.crouch_pressed = i == 15)
	check(pounds[0] == 1, "crouch in the air pounds the ground")
	await _ticks(20)
	# The 2.5 m block: too high for one jump, fine for a high jump.
	h.place(Vector3(8.6, 0.05, 0), Vector3.RIGHT)
	await _ticks(4)
	await _drive(h, 60, func(inp, i): inp.move = Vector3.RIGHT; inp.jump = i == 0; inp.jump_held = true)
	check(h.global_position.y < 1.0, "one jump doesn't reach a 2.5 m block")
	h.place(Vector3(8.6, 0.05, 0), Vector3.RIGHT)
	await _ticks(4)
	await _drive(h, 4, func(inp, _i): inp.crouch = true)
	await _drive(h, 70, func(inp, i): inp.crouch = i == 0; inp.jump = i == 0; inp.jump_held = true; inp.move = Vector3.RIGHT if i > 8 and not h.is_on_floor() else Vector3.ZERO)
	check(h.global_position.y > 2.4 and h.is_on_floor(), "a high jump gets up a 2.5 m block (%.2f)" % h.global_position.y)
	# Getting hurt knocks the hero back, then they blink for a moment.
	h.place(Vector3(0, 0.05, 0), Vector3.FORWARD)
	await _ticks(4)
	check(h.take_hit(Vector3(0, 0, 1)), "a hit lands")
	check(not h.take_hit(Vector3(0, 0, 1)), "no second hit while blinking")
	await _ticks(10)
	check(h.global_position.z < -0.3, "a hit knocks the hero away")
	_fast(false)
	await _free(level)


## Two walls a square apart: jumping between them climbs to the top.
func _test_wall_climb() -> void:
	_fast(true)
	var level := Level.new()
	add_child(level)
	level.land(-6, -6, 6, 6, 0, 2)
	level.land(-2, -1, 0, 1, 7, 8)
	level.land(1, -1, 2, 1, 6.5, 7)
	level.finish()
	var h := Hero.new()
	level.hero = h
	level.add_child(h)
	h.place(Vector3(0.5, 0.05, 3), Vector3.FORWARD)
	await _ticks(4)
	var fake := FakePlay.new()
	fake.hero = h
	var pilot := CoursePilot.new([
		{"to": Vector3(0.5, 0, 0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 7.3, "off": Vector3.LEFT,
			"until": func(_p): return h.is_on_floor() and h.global_position.y > 6.9},
	])
	var ok := false
	for i in 60 * 10:
		await get_tree().physics_frame
		pilot.drive(fake)
		if pilot.done:
			ok = true
			break
	check(ok, "kicking between two walls climbs to the top (at %s)" % h.global_position)
	check(h.global_position.x < 0.0, "and onto the taller one")
	fake.free()
	_fast(false)
	await _free(level)


## Enough of Play for the pilot to drive a hero on a test ground.
class FakePlay extends Play:
	func _ready() -> void:
		pass


# --- Things in the worlds ----------------------------------------------------

## Ice, low gravity, wind, falling platforms, launchers, critters, spinners,
## crushers, water and a boss, each tried once on a test ground.
func _test_things() -> void:
	_fast(true)
	var made: Array = await _make_ground()
	var level: Level = made[0]
	var h: Hero = made[1]
	var hurts := [0]
	var falls := [0]
	level.hurt.connect(func(_f): hurts[0] += 1)
	level.fell.connect(func(): falls[0] += 1)
	# Ice: let go of the stick at a run and the hero keeps sliding.
	level.ice(-20, 10, -10, 20, 0.3)
	h.place(Vector3(-15, 0.35, 19), Vector3.FORWARD)
	await _ticks(4)
	await _drive(h, 50, func(inp, _i): inp.move = Vector3.FORWARD; inp.run = true)
	check(h.on_ice, "standing on ice is noticed")
	await _drive(h, 20, func(inp, _i): pass)
	check(h.horizontal_speed() > 3.0, "the hero slides on ice (%.2f)" % h.horizontal_speed())
	# Low gravity: the same jump goes much higher.
	h.place(Vector3(0, 0.05, 0), Vector3.FORWARD)
	h.gravity_scale = 0.5
	await _ticks(4)
	var r: Array = await _measure(h, func(inp, i): inp.jump = i == 0; inp.jump_held = true, 400)
	check(r[0] > 3.0, "low gravity jumps higher (%.2f)" % r[0])
	h.gravity_scale = 1.0
	# Wind: an updraft lifts the hero.
	level.add(WindZone.make(Vector3(2, 8, 2), Vector3.UP * 45.0), Vector3(-5, 0, 0))
	h.place(Vector3(-5, 0.05, 0), Vector3.FORWARD)
	await _ticks(60)
	check(h.global_position.y > 2.0, "an updraft lifts the hero (%.2f)" % h.global_position.y)
	h.forces.clear()
	# A falling platform drops after being stood on, and comes back.
	var fp := level.add(FallingPlatform.make(), Vector3(5, 3, 8)) as FallingPlatform
	h.place(Vector3(5, 3.05, 8), Vector3.FORWARD)
	await _ticks(90)
	check(fp.position.y < 2.0, "a falling platform falls when stood on (%.2f)" % fp.position.y)
	fp.queue_free()
	h.place(Vector3(0, 0.05, 0), Vector3.FORWARD)
	await _ticks(30)
	# A launcher's shot hurts.
	hurts[0] = 0
	h.safe_time = 0.0
	level.add(Launcher.make("pirate:cannon", Vector3.BACK, 0.5), Vector3(0, 0, -6))
	await _until(func(): return hurts[0] > 0, 3.0)
	check(hurts[0] > 0, "a cannonball hurts")
	for n in level.find_children("*", "Launcher", true, false):
		n.queue_free()
	await _ticks(60)
	# Critters: land on one and it pops; walk into a chaser and it hurts.
	var c := level.add(Critter.make("animal-bee", Vector3.ZERO), Vector3(15, 0, 15)) as Critter
	h.place(Vector3(15, 2.5, 15), Vector3.FORWARD)
	await _until(func(): return c.defeated, 2.0)
	check(c.defeated, "landing on a critter beats it")
	hurts[0] = 0
	await _ticks(90)
	h.safe_time = 0.0
	var chaser := level.add(Critter.chaser("grave:character-zombie", 6.0, 3.0), Vector3(20, 0, 20)) as Critter
	h.place(Vector3(17, 0.05, 20), Vector3.FORWARD)
	await _until(func(): return hurts[0] > 0, 3.0)
	check(hurts[0] > 0 and not chaser.defeated, "a chaser comes and bites")
	chaser.queue_free()
	await _ticks(90)
	# A spinner's arm hurts.
	hurts[0] = 0
	h.safe_time = 0.0
	level.add(Spinner.make(3, 120.0), Vector3(-15, 0, -15))
	h.place(Vector3(-13, 0.05, -15), Vector3.FORWARD)
	await _until(func(): return hurts[0] > 0, 3.0)
	check(hurts[0] > 0, "a spinner's arm hurts")
	# A crusher sends the hero back; water does too.
	falls[0] = 0
	level.add(Crusher.make(3.0, Vector3(2, 1, 2), 0.5), Vector3(20, 0, -15))
	h.place(Vector3(20, 0.05, -15), Vector3.FORWARD)
	await _until(func(): return falls[0] > 0, 6.0)
	check(falls[0] > 0, "a crusher squashes")
	falls[0] = 0
	level.water(36, -4, 40, 0, -1.0)
	h.place(Vector3(38, 2, -2), Vector3.FORWARD)
	await _until(func(): return falls[0] > 0, 2.0)
	check(falls[0] > 0, "falling in water sends the hero back")
	# A boss: hurts to touch until open, then a stomp is a hit.
	var boss := Boss.new()
	boss.max_health = 2
	level.add(boss, Vector3(0, 0, 10))
	boss.make_body(Vector3(1.6, 1.4, 1.6))
	await _ticks(2)
	hurts[0] = 0
	h.safe_time = 0.0
	h.place(Vector3(0, 0.05, 10.9), Vector3.FORWARD)
	await _until(func(): return hurts[0] > 0, 1.0)
	check(hurts[0] > 0 and boss.health == 2, "a closed boss hurts and takes no hit")
	await _ticks(100)
	boss.open = true
	h.place(Vector3(0, 3, 10), Vector3.FORWARD)
	await _until(func(): return boss.health < 2, 2.0)
	check(boss.health == 1, "landing on an open boss is a hit")
	_fast(false)
	await _free(level)


# --- Menus -------------------------------------------------------------------

func _test_menus() -> void:
	var title: TitleScreen = load("res://game/ui/title.tscn").instantiate()
	add_child(title)
	await _frames(2)
	check(title._col.get_child_count() > 3, "the title menu has buttons")
	title._show_speedrun()
	await _frames(1)
	var locked := 0
	for b in title._col.find_children("*", "Button", true, false):
		if (b as Button).disabled:
			locked += 1
	check(locked == Courses.of_world("sunny").size(), "courses are locked until Adventure finds them (%d)" % locked)
	Progress.find_course("sawmill")
	title._show_speedrun()
	await _frames(1)
	var names := []
	for b in title._col.find_children("*", "Button", true, false):
		names.append((b as Button).text)
	check(names.any(func(t): return str(t).begins_with("Saw Mill Sprint")), "a found course opens in Speedrun")
	title._show_settings()
	await _frames(1)
	title._show_about()
	await _frames(1)
	title._show_main()
	await _frames(1)
	var panel := HowToPanel.new()
	add_child(panel)
	panel.open()
	for i in HowToPanel.pages().size():
		panel._go(1)
	panel.close()
	panel.queue_free()
	title.queue_free()
	await _frames(3)
	Progress.wipe()




# --- Travelling the Skyway ---------------------------------------------------

## The boss door stays shut without enough stars; a world opens once the
## boss before it is beaten, and its gate then leads across.
func _test_skyway() -> void:
	_fast(true)
	Progress.wipe()
	check(Worlds.is_open("sunny") and not Worlds.is_open("frosty"), "only Sunny Isles is open at first")
	var play := _make_play("sunny", "adventure")
	await _ticks(6)
	var isle := play.level as Island
	var doors := isle.find_children("*", "BossDoor", true, false)
	if not doors.is_empty():
		var door := doors[0] as BossDoor
		check(not door.is_open(), "the boss door is shut at first")
		play.hero.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
		await _ticks(4)
		door.talk()
		check(not play._leaving, "a shut boss door doesn't open")
	var gates := isle.find_children("*", "SkywayGate", true, false)
	check(not gates.is_empty(), "Sunny Isles has a Skyway gate")
	if not gates.is_empty():
		var gate := gates[0] as SkywayGate
		check(not gate.is_open(), "the gate on is faded at first")
		Progress.add_star(str(Worlds.boss_def("sunny").star))
		check(Worlds.is_open("frosty"), "beating Captain Pinch opens Frosty Peaks")
		check(gate.is_open() == Worlds.is_built("frosty"), "the gate opens once Frosty Peaks is built and open")
	await _free(play)
	# Arriving through a door or gate puts the hero in front of it.
	play = _make_play("sunny", "adventure", {"door": "sawmill"})
	await _ticks(6)
	var sawmill_door: CourseDoor = null
	for d in play.level.find_children("*", "CourseDoor", true, false):
		if (d as CourseDoor).course_id == "sawmill":
			sawmill_door = d
	check(sawmill_door != null and play.hero.global_position.distance_to(sawmill_door.global_position) < 2.5, "coming out of a course arrives at its door")
	_fast(false)
	await _free(play)
	Progress.wipe()


# --- Worlds ------------------------------------------------------------------

## A world's own tests (tests/worlds/<world>_tests.gd), or null.
func _world_tests(w: String) -> RefCounted:
	var path := "res://tests/worlds/%s_tests.gd" % w
	if not ResourceLoader.exists(path):
		return null
	var wt: RefCounted = load(path).new()
	wt.t = self
	return wt


## A world's island and boss tests, then every course: once in Adventure
## and `games` times in Speedrun.
func _test_world(w: String) -> void:
	var wt := _world_tests(w)
	check(wt != null, "%s has tests" % w)
	if wt == null:
		return
	printerr("- world: ", w)
	Progress.wipe()
	await wt.run()
	for id in Courses.of_world(w):
		await _test_course(wt, id)


## The pilot runs a course in Adventure (for the star, taking no hits) and
## in Speedrun (for gold or better, `games` times).
func _test_course(wt: RefCounted, id: String) -> void:
	printerr("- course: ", id)
	var legs: Array = wt.legs(id) if wt else []
	check(not legs.is_empty(), "%s has pilot legs" % id)
	if legs.is_empty():
		return
	var def := Courses.get_def(id)
	_fast(true)
	Progress.wipe()
	var play := _make_play(id, "adventure")
	await _ticks(6)
	var pilot := CoursePilot.new(wt.legs(id))
	play.autopilot = pilot.drive
	var hurts := [0]
	play.level.hurt.connect(func(_f): hurts[0] += 1)
	var falls := [0]
	play.level.fell.connect(func(): falls[0] += 1)
	var got := await _until(func(): return Progress.has_star(def.star), 120.0)
	check(got, "the pilot reaches %s's flag in Adventure (stuck at leg %d, %s)" % [id, pilot.leg, play.hero.global_position])
	check(hurts[0] == 0, "the pilot's way through %s takes no hits (%d)" % [id, hurts[0]])
	check(falls[0] == 0, "and no falls (%d)" % falls[0])
	_fast(false)
	await _free(play)
	for game in games:
		await _test_speedrun(wt, id, game)


func _test_speedrun(wt: RefCounted, id: String, game: int) -> void:
	_fast(true)
	if game == 0:
		Progress.wipe()
	var play := _make_play(id, "speedrun")
	check(play.run_state == Play.Run.COUNTDOWN, "a speedrun starts with a countdown")
	await _until(func(): return play.run_state == Play.Run.RUNNING, 5.0)
	check(absf(play.hero.global_position.z - play.level.spawn.z) < 0.2, "the hero waits at the start during the countdown")
	check(game == 0 or play.ghost_runner != null, "the best run's ghost races along")
	var pilot := CoursePilot.new(wt.legs(id))
	play.autopilot = pilot.drive
	var restarts := [0]
	var last := [0.0]
	var finished := await _until(func():
		if play.run_time < last[0]:
			restarts[0] += 1
		last[0] = play.run_time
		return play.run_state == Play.Run.FINISHED, 120.0)
	check(finished, "the pilot finishes %s in Speedrun (stuck at leg %d, %s)" % [id, pilot.leg, play.hero.global_position])
	if finished:
		var msec := play.run_msec()
		var medal := Courses.medal_for(id, msec)
		print("  %s: pilot finished in %s (%s)" % [Courses.title(id), Courses.time_text(msec), Courses.MEDALS[medal] if medal > 0 else "no medal"])
		check(Progress.best_time(id) > 0 and Progress.best_time(id) <= msec, "the time is kept")
		check(play.results.visible, "the results show")
		var g := Progress.load_ghost(id)
		check(g != null and absf(g.duration() - msec / 1000.0) < 0.2, "the run's ghost is kept")
		check(medal >= 3, "the pilot wins gold or better on %s" % id)
	check(restarts[0] == 0, "no falls on %s" % id)
	play.restart_run()
	check(play.run_state == Play.Run.COUNTDOWN and play.run_msec() == 0, "start again resets the clock")
	_fast(false)
	await _free(play)


## An autopilot that leaves the hero's input to the test.
func _hands_off(_play: Play) -> void:
	pass


func _find_star(level: Level, id: String) -> Pickup:
	for n in level.find_children("*", "Pickup", true, false):
		var p := n as Pickup
		if p.kind == "star" and p.id == id and not p.is_queued_for_deletion():
			return p
	return null


## Lets a test's pilot drive the hero until it's done; true if it got there.
func _pilot(play: Play, legs: Array, seconds: float) -> bool:
	var pilot := CoursePilot.new(legs)
	play.autopilot = pilot.drive
	var ok := await _until(func(): return pilot.done, seconds)
	play.autopilot = _hands_off
	if not ok:
		printerr("  pilot stuck at leg %d, %s" % [pilot.leg, play.hero.global_position])
	return ok
