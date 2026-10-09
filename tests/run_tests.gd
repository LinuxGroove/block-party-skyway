extends Node
## Headless tests: run with
##   godot --headless --path . tests/run_tests.tscn
## Add `-- --games=N` to run Saw Mill Sprint N times with the course pilot
## (default 1; the second run races the first one's ghost), or
## `-- --only=_test_island` for one test. Prints the pilot's time, which the
## medal times are set from. Exits non-zero on failure.

const CoursePilot := preload("res://tests/course_pilot.gd")

var failures := 0
var checks := 0


func _ready() -> void:
	var games := 1
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--games="):
			games = maxi(1, arg.substr(8).to_int())
		elif arg.begins_with("--only="):
			only = arg.substr(7)
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGTheme.apply(get_tree().root)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	Progress.use_path("user://test-progress.cfg", "user://test-ghosts/")
	Progress.wipe()
	if only != "":
		await call(only)
		print("\n%d checks, %d failed" % [checks, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	for t in ["_test_data", "_test_medals", "_test_progress", "_test_ghost"]:
		printerr("- ", t)
		call(t)
	for t in ["_test_moves", "_test_wall_climb", "_test_menus", "_test_island", "_test_course_adventure"]:
		printerr("- ", t)
		await call(t)
	for i in games:
		printerr("- _test_speedrun %d" % (i + 1))
		await _test_speedrun(i)
	Progress.wipe()
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

## Every star and gem the worlds list is in a level, and nothing else is.
func _test_data() -> void:
	var stars := {}
	var gems := {}
	for id in Courses.ids():
		var def := Courses.get_def(id)
		stars[def.star] = true
		check(Worlds.star_ids(def.world).has(def.star), "%s's star is in its world" % id)
		check(Worlds.gem_ids(def.world).has(def.gem), "%s's gem is in its world" % id)
		check(Levels.make(id, "adventure") != null, "%s has a level" % id)
	# Pebble's chicks and the silver rush hand out their stars when done.
	stars["sunny/chicks"] = true
	stars["sunny/silver"] = true
	for id in ["sunny", "sawmill"]:
		var level := Levels.make(id, "adventure")
		add_child(level)
		level.build()
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
		level.free()
	var want_stars := Worlds.star_ids("sunny")
	var want_gems := Worlds.gem_ids("sunny")
	check(stars.size() == want_stars.size(), "Sunny Isles places %d stars (has %d)" % [want_stars.size(), stars.size()])
	for id in want_stars:
		check(stars.has(id), "star %s is placed" % id)
	check(gems.size() == want_gems.size(), "Sunny Isles hides %d gems (has %d)" % [want_gems.size(), gems.size()])
	for id in want_gems:
		check(gems.has(id), "gem %s is hidden" % id)
	check(Worlds.total_stars() == 6, "six stars so far")
	# Speedrun builds without the Adventure extras.
	var course := Levels.make("sawmill", "speedrun")
	add_child(course)
	course.build()
	check(course.find_children("*", "Pickup", true, false).is_empty(), "a speedrun course has no pickups")
	check(course.find_children("*", "Checkpoint", true, false).is_empty(), "a speedrun course has no checkpoints")
	check(course.find_children("*", "FinishFlag", true, false).size() == 1, "the course has one finish flag")
	course.free()


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
	check(locked == Courses.ids().size(), "courses are locked until Adventure finds them")
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


# --- Sunny Isles -------------------------------------------------------------

func _test_island() -> void:
	_fast(true)
	Progress.wipe()
	var play := _make_play("sunny", "adventure")
	await _ticks(10)
	var isle := play.level as SunnyIsle
	var h := play.hero
	check(h.is_on_floor(), "the hero lands on Sunny Isles")
	check(not isle.bridge.shown, "the Skyway is hidden at first")
	check(play.hud.visible, "the HUD shows")
	# Pebble's chicks: touch each one and it hops home.
	h.place(isle.pebble.global_position + Vector3(1.0, 0.1, 0))
	await _ticks(4)
	check(isle.nearest_talker() == isle.pebble, "Pebble is there to talk to")
	isle.pebble.talk()
	check(play.speech_open(), "Pebble explains about her chicks")
	while play.speech_open():
		play._next_line()
	for c in isle.chicks:
		h.place(c.global_position + Vector3.UP * 0.1)
		await _until(func(): return c.is_home, 2.0)
	check(await _until(func(): return isle.chicks_home == 3, 3.0), "all three chicks go home")
	check(play.speech_open(), "Pebble thanks you")
	while play.speech_open():
		play._next_line()
	await _ticks(2)
	var star := _find_star(isle, "sunny/chicks")
	check(star != null, "Pebble gives a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		check(await _until(func(): return Progress.has_star("sunny/chicks"), 2.0), "the chicks' star is found")
	await _until(func(): return not h.is_locked(), 3.0)
	# Silver rush: step on the button, grab the eight coins.
	h.place(isle.silver_button.global_position + Vector3.UP * 0.1)
	check(await _until(func(): return isle.silver_left > 0.0, 1.0), "the button starts the silver rush")
	for p in isle._silver.duplicate():
		if is_instance_valid(p):
			h.place(p.global_position - Vector3.UP * 0.2)
			await _ticks(6)
	star = _find_star(isle, "sunny/silver")
	check(star != null, "eight silver coins give a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		check(await _until(func(): return Progress.has_star("sunny/silver"), 2.0), "the silver star is found")
	check(isle.bridge.shown, "two stars bring the Skyway back")
	await _until(func(): return not h.is_locked(), 3.0)
	# The secret ledge: walk off the north cliff, then the spring goes back up.
	var pilot := CoursePilot.new([
		{"to": Vector3(4.5, 2, -21.0), "walk": true},
		{"to": Vector3(4.5, -1.5, -24.6), "walk": true, "until": func(_p): return Progress.has_star("sunny/ledge")},
		{"to": Vector3(2.7, -1.5, -23.6), "walk": true, "until": func(_p): return h.velocity.y > 10.0},
		{"to": Vector3(2.7, 2, -20.5), "until": func(_p): return h.is_on_floor() and h.global_position.y > 1.9},
	])
	h.place(Vector3(4.5, 2.05, -19.0), Vector3.FORWARD)
	play.autopilot = pilot.drive
	check(await _until(func(): return pilot.done, 20.0), "the ledge under the cliff has a star, and a spring back up (stuck at leg %d, %s)" % [pilot.leg, h.global_position])
	check(Progress.has_star("sunny/ledge"), "the ledge star is found")
	# The old tower: kick up between the tower and the wall beside it.
	pilot = CoursePilot.new([
		{"to": Vector3(15.5, 0, -3.0), "walk": true},
		{"to": Vector3(15.5, 0, -5.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 7.3, "off": Vector3.LEFT,
			"until": func(_p): return Progress.has_star("sunny/tower")},
	])
	h.place(Vector3(15.5, 0.05, -1.5), Vector3.FORWARD)
	play.autopilot = pilot.drive
	check(await _until(func(): return pilot.done, 20.0), "the tower can be climbed for its star (at %s)" % h.global_position)
	play.autopilot = _hands_off
	await _until(func(): return not h.is_locked(), 3.0)
	# Lookout Islet, across the Skyway: walk over, pound the strong crate.
	pilot = CoursePilot.new([
		{"to": Vector3(12.5, 0, 8.6)},
		{"to": Vector3(23.5, 0, 8.6)},
	])
	h.place(Vector3(9, 0.05, 8.6), Vector3.RIGHT)
	play.autopilot = pilot.drive
	check(await _until(func(): return pilot.done, 15.0), "the Skyway reaches Lookout Islet (at %s)" % h.global_position)
	play.autopilot = _hands_off
	var crate: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "star:sunny/crates":
			crate = b
	check(crate != null, "Lookout Islet has the strong crate")
	if crate:
		var crate_at := crate.global_position
		h.place(crate_at + Vector3.UP * 3.0)
		await _drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		check(not is_instance_valid(crate), "a ground pound breaks the strong crate")
		check(await _until(func(): return Progress.has_star("sunny/crates"), 3.0), "the crate's star is found")
	# The course door leads into Saw Mill Sprint.
	var door: CourseDoor = isle.find_children("*", "CourseDoor", true, false)[0]
	await _until(func(): return not h.is_locked(), 3.0)
	h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
	await _ticks(4)
	check(isle.nearest_talker() == door, "the course door can be used")
	check(isle.secrets_left() == Worlds.total_gems() + 1, "only the course and the gems are left (%d)" % isle.secrets_left())
	# Falling off costs a heart and comes back at the last flag.
	play.hearts = Play.MAX_HEARTS
	var hearts := play.hearts
	h.place(Vector3(0, -20, 40))
	await _ticks(3)
	check(h.global_position.y > -2.0 and play.hearts == hearts - 1, "falling off costs a heart and comes back")
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


# --- Saw Mill Sprint ---------------------------------------------------------

## The sliding platforms, nearest the start first.
static func _platforms(play: Play) -> Array:
	var list := play.level.find_children("*", "MovingPlatform", true, false)
	list.sort_custom(func(a, b): return a.position.z > b.position.z)
	return list


static func _plat_at(play: Play, i: int, t: float) -> Vector3:
	var p: MovingPlatform = _platforms(play)[i]
	return p._start + p.offset_at(p._t + t)


## The pilot's way through Saw Mill Sprint: hop the stones, jump each saw
## and the spikes, ride the platforms, double jump the shelf, long jump the
## gap and the conveyor, and run to the flag.
func _sawmill_legs() -> Array:
	return [
		{"to": Vector3(0, 0, -5.6), "jump": "jump", "aim": Vector3(0, 0.5, -8.7)},
		{"to": Vector3(-0.5, 0.5, -9.6), "jump": "jump", "aim": Vector3(-1, 1, -12.7)},
		{"to": Vector3(-0.6, 1, -13.6), "jump": "jump", "aim": Vector3(1, 1.5, -16.7)},
		{"to": Vector3(1, 1.5, -17.6), "jump": "jump", "aim": Vector3(0.5, 1.5, -21.2)},
		{"to": Vector3(0, 1.5, -22.5), "jump": "jump", "aim": Vector3(0, 1.5, -26.0)},
		{"to": Vector3(0, 1.5, -26.4), "jump": "jump", "aim": Vector3(0, 1.5, -29.8)},
		{"to": Vector3(0, 1.5, -30.2), "jump": "jump", "aim": Vector3(0, 1.5, -32.8)},
		{"to": Vector3(0, 1.5, -32.9), "when": func(p): return absf(_plat_at(p, 0, 0.8).x) < 1.2},
		{"to": Vector3(0, 1.5, -33.7), "jump": "jump", "aim": func(p, t): return _plat_at(p, 0, t) + Vector3(0, 0, 0.8)},
		{"to": func(p): return Vector3(_plat_at(p, 0, 0).x, 1.5, -38.0), "jump": "jump", "aim": func(p, t): return _plat_at(p, 1, t) + Vector3(0, 0, 0.6)},
		{"to": func(p): return Vector3(_plat_at(p, 1, 0).x, 1.5, -42.6), "jump": "jump", "aim": Vector3(1.5, 1.5, -47.6)},
		{"to": Vector3(-0.8, 1.5, -48.3), "jump": "double", "aim": Vector3(-6.5, 4.0, -48.5)},
		{"to": Vector3(-11.2, 4.0, -48.5), "jump": "long", "aim": Vector3(-21.8, 3.0, -48.5)},
		{"to": Vector3(-23.0, 3.0, -48.5), "jump": "long", "aim": Vector3(-33.0, 3.0, -48.5)},
		{"to": Vector3(-40.0, 3.0, -48.5)},
	]


func _test_course_adventure() -> void:
	_fast(true)
	Progress.wipe()
	var play := _make_play("sawmill", "adventure")
	await _ticks(6)
	var pilot := CoursePilot.new(_sawmill_legs())
	play.autopilot = pilot.drive
	var hurts := [0]
	play.level.hurt.connect(func(_f): hurts[0] += 1)
	var got := await _until(func(): return Progress.has_star("sunny/sawmill"), 60.0)
	check(got, "the course pilot reaches the flag in Adventure (stuck at leg %d, %s)" % [pilot.leg, play.hero.global_position])
	check(hurts[0] == 0, "the pilot's way through takes no hits (%d)" % hurts[0])
	check(Progress.coins > 0, "coins on the way")
	_fast(false)
	await _free(play)


func _test_speedrun(game: int) -> void:
	_fast(true)
	if game == 0:
		Progress.wipe()
	var play := _make_play("sawmill", "speedrun")
	check(play.run_state == Play.Run.COUNTDOWN, "a speedrun starts with a countdown")
	await _until(func(): return play.run_state == Play.Run.RUNNING, 5.0)
	var start_z := play.hero.global_position.z
	check(absf(start_z - play.level.spawn.z) < 0.2, "the hero waits at the start during the countdown")
	check(game == 0 or play.ghost_runner != null, "the best run's ghost races along")
	var pilot := CoursePilot.new(_sawmill_legs())
	play.autopilot = pilot.drive
	var restarts := [0]
	var last := [0.0]
	var finished := await _until(func():
		if play.run_time < last[0]:
			restarts[0] += 1
		last[0] = play.run_time
		return play.run_state == Play.Run.FINISHED, 60.0)
	check(finished, "the course pilot finishes Saw Mill Sprint (stuck at leg %d, %s)" % [pilot.leg, play.hero.global_position])
	if finished:
		var msec := play.run_msec()
		var medal := Courses.medal_for("sawmill", msec)
		print("  Saw Mill Sprint: pilot finished in %s (%s)" % [Courses.time_text(msec), Courses.MEDALS[medal] if medal > 0 else "no medal"])
		check(Progress.best_time("sawmill") > 0 and Progress.best_time("sawmill") <= msec, "the time is kept")
		check(play.results.visible, "the results show")
		var g := Progress.load_ghost("sawmill")
		check(g != null and absf(g.duration() - msec / 1000.0) < 0.2, "the run's ghost is kept")
		check(medal >= 3, "the pilot wins gold or better")
	check(restarts[0] == 0, "no falls")
	# Start again works straight away.
	play.restart_run()
	check(play.run_state == Play.Run.COUNTDOWN and play.run_msec() == 0, "start again resets the clock")
	_fast(false)
	await _free(play)
