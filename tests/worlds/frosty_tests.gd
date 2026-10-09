extends RefCounted
## Frosty Peaks' tests, run by tests/run_tests.gd: the island's stars, The
## Big Chill, and the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"icerink":
			return _icerink()
		"chimneys":
			return _chimneys()
		"toytrain":
			return _toytrain()
		"giftstack":
			return _giftstack()
	return []


## Frosty Peaks: Dasher's presents (up a cabin roof and across the ice
## floes), the silver coins, the climb up Frosty Peak, the hollow behind the
## ice curtain, catching Pingo, the tight present, the boss door, then The
## Big Chill.
func run() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("frosty", "adventure")
	await t._ticks(10)
	var isle := play.level as FrostyPeaks
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Frosty Peaks")
	var boss_door: BossDoor = isle.find_children("*", "BossDoor", true, false)[0]
	t.check(not boss_door.is_open(), "the boss door is shut at first")
	# Dasher explains about his presents.
	h.place(isle.dasher.global_position + Vector3(0, 0.1, 1.0))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.dasher, "Dasher is there to talk to")
	isle.dasher.talk()
	t.check(play.speech_open(), "Dasher explains about his presents")
	while play.speech_open():
		play._next_line()
	await t._until(func(): return not h.is_locked(), 2.0)
	# The roof present: up the stacked presents and onto the cabin's roof.
	h.place(Vector3(-4.4, 0.05, -4.9), Vector3.LEFT)
	await t._ticks(4)
	var roof := isle.presents[0]
	t.check(await t._pilot(play, [
		{"to": Vector3(-5.3, 0, -4.9), "walk": true, "jump": "jump", "aim": Vector3(-6.8, 1.0, -4.9)},
		{"to": Vector3(-6.85, 1.0, -5.2), "walk": true, "jump": "jump", "aim": Vector3(-6.9, 1.9, -6.9)},
		{"to": Vector3(-7.0, 1.9, -7.0), "walk": true, "jump": "jump", "aim": Vector3(-8.8, 2.9, -8.0)},
		{"to": Vector3(-10.0, 3.6, -8.6), "walk": true, "until": func(_p): return roof.is_home},
	], 20.0), "the stacked presents lead up onto the cabin roof")
	t.check(roof.is_home, "the roof present flies back to the sled")
	await t._until(func(): return not h.is_locked(), 2.0)
	# The peak present: on the first tier's far corner.
	var high := isle.presents[1]
	h.place(high.global_position + Vector3(1.5, 0.1, 0))
	t.check(await t._pilot(play, [{"to": high.global_position, "walk": true, "until": func(_p): return high.is_home}], 5.0), "the present on the peak goes home")
	# The floe present: bounce across the ice floe (it's too slippery to
	# stop on) to the snowy floe with the gem, and back.
	h.place(Vector3(35.5, 0.05, -0.5), Vector3.RIGHT)
	await t._ticks(4)
	t.check(await t._pilot(play, [
		{"to": Vector3(37.4, 0, -0.5), "jump": "jump", "aim": Vector3(41.8, 0, -0.5)},
		{"to": Vector3(43.0, 0, -0.5), "jump": "jump", "aim": Vector3(47.8, 0, -0.5)},
		{"to": Vector3(48.5, 0, -0.5), "stop": true},
		{"to": Vector3(47.3, 0, -0.5), "jump": "jump", "aim": Vector3(42.8, 0, -0.5)},
		{"to": Vector3(42.0, 0, -0.5), "jump": "jump", "aim": Vector3(36.5, 0, -0.5)},
		{"to": Vector3(35.5, 0, -0.5), "stop": true},
	], 20.0), "the ice floes can be crossed and crossed back")
	t.check(Progress.has_gem("frosty/gem_floe"), "the gem on the far floe is found")
	t.check(await t._until(func(): return isle.presents_home == 3, 3.0), "all three presents go home")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	var star := t._find_star(isle, "frosty/presents")
	t.check(star != null, "Dasher gives a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("frosty/presents"), 2.0), "Dasher's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# Silver rush: step on the button, grab the eight coins.
	h.place(isle.silver.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.silver.time_left > 0.0, 1.0), "the button starts the silver rush")
	for p in isle.silver.coins.duplicate():
		if is_instance_valid(p):
			h.place(p.global_position - Vector3.UP * 0.2)
			await t._ticks(6)
	star = t._find_star(isle, "frosty/silver")
	t.check(star != null, "eight silver coins give a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("frosty/silver"), 2.0), "the silver star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# Frosty Peak: jump up the first tier, high jump onto the icy second and
	# again onto the third, then up the ledges to the top.
	h.place(Vector3(0, 2.05, -17.5), Vector3.FORWARD)
	await t._ticks(4)
	t.check(await t._pilot(play, [
		{"to": Vector3(0, 2, -20.8), "jump": "jump", "aim": Vector3(0, 3.5, -23.4)},
		{"to": Vector3(0, 3.5, -23.6), "jump": "high", "aim": Vector3(0, 6, -26.2)},
		{"to": Vector3(0, 6, -26.6), "jump": "high", "aim": Vector3(0, 8.5, -29.0)},
		{"to": Vector3(1.0, 8.5, -29.4), "jump": "jump", "aim": Vector3(3.0, 10, -29.2)},
		{"to": Vector3(3.0, 10, -29.6), "jump": "jump", "aim": Vector3(3.0, 11.5, -33.0)},
		{"to": Vector3(2.4, 11.5, -32.6), "jump": "jump", "aim": Vector3(0, 13, -32), "until": func(_p): return Progress.has_star("frosty/peak")},
	], 30.0), "Frosty Peak can be climbed")
	t.check(await t._until(func(): return Progress.has_star("frosty/peak"), 2.0), "the star on top of the peak is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The ice curtain: walk straight through it into the hollow.
	h.place(Vector3(-36.5, -0.95, 0), Vector3.LEFT)
	await t._ticks(4)
	t.check(await t._pilot(play, [
		{"to": Vector3(-40.5, -1, 0), "walk": true, "until": func(_p): return Progress.has_star("frosty/curtain")},
	], 8.0), "the ice curtain can be walked through")
	t.check(Progress.has_star("frosty/curtain"), "the star behind the ice curtain is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# Pingo: Waddles asks, then chase him down on the ice.
	h.place(isle.waddles.global_position + Vector3(1.0, 0.1, 0.4))
	await t._ticks(4)
	isle.waddles.talk()
	t.check(play.speech_open(), "Waddles asks you to catch Pingo")
	while play.speech_open():
		play._next_line()
	await t._until(func(): return not h.is_locked(), 2.0)
	h.place(Vector3(20, 0.05, 0), Vector3.RIGHT)
	play.autopilot = _chase_pingo
	t.check(await t._until(func(): return isle.pingo.is_home, 40.0), "Pingo can be caught on the ice (at %s, Pingo at %s)" % [h.global_position, isle.pingo.global_position])
	play.autopilot = t._hands_off
	t.check(await t._until(func(): return play.speech_open(), 3.0), "Waddles thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	star = t._find_star(isle, "frosty/pingo")
	t.check(star != null, "Waddles gives a star")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("frosty/pingo"), 2.0), "Pingo's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The present tied too tight: a ground pound opens it.
	var tight: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "gem:frosty/gem_present":
			tight = b
	t.check(tight != null and tight.strong, "the woods have a present too tight to open")
	if tight:
		h.place(tight.global_position + Vector3.UP * 3.0)
		await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		t.check(not is_instance_valid(tight), "a ground pound opens the tight present")
		var gem: Pickup = null
		for p in isle.find_children("*", "Pickup", true, false):
			if (p as Pickup).kind == "gem" and (p as Pickup).id == "frosty/gem_present":
				gem = p
		if gem:
			h.place(gem.global_position - Vector3.UP * 0.3)
		t.check(await t._until(func(): return Progress.has_gem("frosty/gem_present"), 2.0), "the gem in the tight present is found")
	# Five stars open the boss door.
	t.check(boss_door.is_open(), "five stars open the boss door (%d found)" % isle.world_stars())
	h.place(boss_door.global_position + boss_door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == boss_door, "the boss door can be used")
	# Every course door works.
	for c in Courses.of_world("frosty"):
		var door: CourseDoor = null
		for d in isle.find_children("*", "CourseDoor", true, false):
			if (d as CourseDoor).course_id == c:
				door = d
		h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
		await t._ticks(4)
		t.check(isle.nearest_talker() == door, "the door to %s can be used" % c)
	var left := 0
	for id in Worlds.star_ids("frosty"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("frosty"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(isle.secrets_left() == left, "secrets left counts what's still hidden (%d)" % isle.secrets_left())
	# Falling off costs a heart and comes back at the last flag.
	play.hearts = Play.MAX_HEARTS
	var hearts := play.hearts
	h.place(Vector3(0, -20, 60))
	await t._ticks(3)
	t.check(h.global_position.y > -2.0 and play.hearts == hearts - 1, "falling off costs a heart and comes back")
	t._fast(false)
	await t._free(play)
	await _boss()
	await _train_gem()


## Runs at Pingo: the stick points at him every tick.
func _chase_pingo(play: Play) -> void:
	var h := play.hero
	h.input.clear()
	var isle := play.level as FrostyPeaks
	if play.speech_open() or isle.pingo.is_home:
		return
	var to := isle.pingo.global_position - h.global_position
	to.y = 0.0
	h.input.move = to.normalized()
	h.input.run = true


# --- The Big Chill -----------------------------------------------------------

## The Big Chill: wait for him to slam into the wall, then ground pound him
## while he's dazed, three times. The star comes out, and he can't be hit
## while he isn't dazed.
func _boss() -> void:
	t._fast(true)
	var play := t._make_play("big_chill", "adventure")
	await t._ticks(10)
	var arena := play.level as BigChillArena
	var h := play.hero
	t.check(arena != null and arena.boss != null, "The Big Chill is in his arena")
	if arena == null or arena.boss == null:
		t._fast(false)
		await t._free(play)
		return
	var bear := arena.boss as FrostyBigChill
	t.check(h.is_on_floor(), "the hero lands in the arena")
	# Pounding him before he's dazed only hurts.
	await t._until(func(): return bear.state == FrostyBigChill.State.AIM, 6.0)
	h.safe_time = 0.0
	var health := bear.health
	h.place(bear.global_position + Vector3.UP * 3.5)
	await t._drive(h, 40, func(inp, i): inp.crouch_pressed = i == 4)
	t.check(bear.health == health, "he can't be hit before he's dazed")
	for hit in 3:
		h.place(arena.spawn + Vector3.UP * 0.1, Vector3.FORWARD)
		h.safe_time = 0.0
		var dazed := await t._until(func(): return bear.open, 12.0)
		t.check(dazed, "he slides into the wall and is dazed (hit %d)" % (hit + 1))
		if not dazed:
			break
		h.place(bear.global_position + Vector3.UP * 3.5)
		await t._drive(h, 40, func(inp, i): inp.crouch_pressed = i == 4)
		t.check(bear.health == 2 - hit, "a ground pound while he's dazed is a hit (%d left)" % bear.health)
		await t._until(func(): return not h.is_locked(), 2.0)
	t.check(bear.beaten, "three hits beat The Big Chill")
	await t._until(func(): return t._find_star(arena, "frosty/boss") != null, 3.0)
	var star := t._find_star(arena, "frosty/boss")
	t.check(star != null, "his star comes out")
	if star:
		h.place(star.global_position - Vector3.UP * 0.4)
		t.check(await t._until(func(): return Progress.has_star("frosty/boss"), 2.0), "The Big Chill's star is found")
	t._fast(false)
	await t._free(play)


# --- Courses -----------------------------------------------------------------

## Toy Train Express's gem: ride the first crossing train to its far end and
## step off onto the ledge.
func _train_gem() -> void:
	t._fast(true)
	var play := t._make_play("toytrain", "adventure")
	await t._ticks(6)
	var lane := (play.level as ToyTrainExpress).lanes[0]
	play.hero.place(Vector3(-4, 1.05, -30.4), Vector3.FORWARD)
	t.check(await t._pilot(play, [
		{"to": Vector3(-4, 1, -30.5), "when": func(_p): return lane.along() == 0.0 and lane.time_to_leave() > 1.0},
		{"to": func(_p): return lane.point_at(5.2) + Vector3(0, 0.85, 0), "when": func(_p): return lane.along() >= 0.999},
		{"to": Vector3(10.6, 1, -29.4), "walk": true, "until": func(_p): return Progress.has_gem("frosty/gem_toytrain")},
	], 30.0), "a crossing train carries the hero to Toy Train Express's gem")
	t._fast(false)
	await t._free(play)


## The pilot's way through Ice Rink Rush: jump each snowball lane, hop the
## floes without stopping, jump each penguin's lane across the rink and the
## spikes, then up the icy steps to the flag.
func _icerink() -> Array:
	return [
		{"to": Vector3(0, 0, -8.8), "jump": "jump", "aim": Vector3(0, 0, -13.4)},
		{"to": Vector3(0, 0, -17.8), "jump": "jump", "aim": Vector3(0, 0, -22.4)},
		{"to": Vector3(0, 0, -27.3), "jump": "jump", "aim": Vector3(0, 0, -30.6)},
		{"to": Vector3(0, 0, -31.6), "jump": "jump", "aim": Vector3(0, 0, -35.6)},
		{"to": Vector3(0, 0, -36.6), "jump": "jump", "aim": Vector3(0, 0, -40.6)},
		{"to": Vector3(0, 0, -41.6), "jump": "jump", "aim": Vector3(0, 0, -45.8)},
		{"to": Vector3(-3.0, 0, -48)},
		{"to": Vector3(-7.8, 0, -48), "jump": "jump", "aim": Vector3(-12.4, 0, -48)},
		{"to": Vector3(-13.8, 0, -48), "jump": "jump", "aim": Vector3(-18.4, 0, -48)},
		{"to": Vector3(-19.8, 0, -48), "jump": "jump", "aim": Vector3(-24.4, 0, -48)},
		{"to": Vector3(-25.8, 0, -48), "jump": "jump", "aim": Vector3(-30.4, 0, -48)},
		{"to": Vector3(-33.2, 0, -48), "jump": "jump", "aim": Vector3(-38.0, 0, -48)},
		{"to": Vector3(-38.0, 0, -53.3), "jump": "jump", "aim": Vector3(-38, 1, -56.0)},
		{"to": Vector3(-38.0, 1, -57.0), "jump": "jump", "aim": Vector3(-38, 2, -60.0)},
		{"to": Vector3(-38.0, 2, -61.0), "jump": "jump", "aim": Vector3(-38, 3, -64.0)},
		{"to": Vector3(-38.0, 3, -65.0), "jump": "jump", "aim": Vector3(-38, 4, -68.4)},
		{"to": Vector3(-38.0, 4, -70.4), "jump": "jump", "aim": Vector3(-38, 4, -73.3)},
		{"to": Vector3(-38.0, 4, -74.0), "jump": "jump", "aim": Vector3(-38, 4, -77.3)},
		{"to": Vector3(-38.0, 4, -78.0), "jump": "jump", "aim": Vector3(-38, 4, -81.3)},
		{"to": Vector3(-38.0, 4, -82.0), "jump": "jump", "aim": Vector3(-38, 4, -85.0)},
		{"to": Vector3(-38.0, 4, -89.5)},
	]


## The pilot's way through Chimney Hop: bounce onto the first roof, along
## the ridges and over the chimney, double jump to the high house, over the
## snowball lane, kick up between the chimneys, across to the last house and
## west over the crumbling shelves.
func _chimneys() -> Array:
	return [
		{"to": Vector3(0, 0, 6.0), "jump": "jump", "aim": Vector3(0, 0, 1.6)},
		{"to": Vector3(0, 0, -4.3), "walk": true, "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(0, 3.6, -8.5), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 3.0},
		{"to": Vector3(0, 3.6, -11.5), "jump": "jump", "aim": Vector3(0, 3.6, -15.6)},
		{"to": Vector3(0, 3.6, -16.6), "jump": "jump", "aim": Vector3(0, 3.6, -20.6)},
		{"to": Vector3(0, 3.6, -20.9), "jump": "double", "aim": Vector3(0, 5.6, -26.5)},
		{"to": Vector3(0, 5.6, -28.6), "jump": "jump", "aim": Vector3(0.5, 4, -33)},
		{"to": Vector3(0.5, 4, -33.5), "jump": "jump", "aim": Vector3(0.5, 4, -37.6)},
		{"to": Vector3(0.5, 4, -39), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 8.8, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 8.3},
		{"to": Vector3(-1.0, 8.5, -38.3)},
		{"to": Vector3(-1.0, 8.5, -39.7), "jump": "double", "aim": Vector3(-0.4, 7.5, -45.5)},
		{"to": Vector3(1.0, 7.0, -46.6)},
		{"to": Vector3(-0.6, 7.5, -47), "jump": "jump", "aim": Vector3(-4.8, 6, -47)},
		{"to": Vector3(-5.3, 6, -47), "jump": "jump", "aim": Vector3(-8.8, 6, -47)},
		{"to": Vector3(-9.3, 6, -47), "jump": "jump", "aim": Vector3(-12.8, 6, -47)},
		{"to": Vector3(-13.3, 6, -47), "jump": "jump", "aim": Vector3(-17.0, 6.6, -47)},
		{"to": Vector3(-17.4, 6.6, -47), "jump": "jump", "aim": Vector3(-21.0, 7.2, -47)},
		{"to": Vector3(-21.4, 7.2, -47), "jump": "jump", "aim": Vector3(-25.0, 7.8, -47)},
		{"to": Vector3(-25.4, 7.8, -47), "jump": "jump", "aim": Vector3(-30.6, 6.0, -47)},
		{"to": Vector3(-37.5, 6.0, -47)},
	]


func _toytrain() -> Array:
	var train := func(p: Play) -> FrostyTrain: return (p.level as ToyTrainExpress).express
	var lane := func(p: Play) -> FrostyTrain: return (p.level as ToyTrainExpress).lanes[0]
	var local := func(p: Play) -> FrostyTrain: return (p.level as ToyTrainExpress).local
	return [
		# Wait beside the train while it's in, with time to step on.
		{"to": Vector3(1.6, 1, -5.2), "when": func(p): return train.call(p).along() == 0.0 and train.call(p).time_to_leave() > 0.9},
		# Stand on the first wagon and ride to the far end.
		{"to": func(p): return train.call(p).point_at(5.2) + Vector3(0, 0.85, 0),
			"when": func(p): return train.call(p).along() >= 0.999},
		{"to": Vector3(-3.5, 1, -26.0)},
		# Cross when the three trains have just stopped in a row.
		{"to": Vector3(-4, 1, -30.4), "when": func(p): return lane.call(p).along() == 0.0 and lane.call(p).time_to_leave() > 1.2},
		{"to": Vector3(-4, 1, -39.0)},
		{"to": Vector3(-6, 1, -43.5)},
		{"to": Vector3(-13.8, 1, -43.5), "jump": "jump", "aim": Vector3(-17.4, 1, -43.5)},
		{"to": Vector3(-19.8, 1, -43.5), "jump": "jump", "aim": Vector3(-23.4, 1, -43.5)},
		# Onto the second train, and north on it.
		{"to": Vector3(-33.4, 1, -44.6), "when": func(p): return local.call(p).along() == 0.0 and local.call(p).time_to_leave() > 0.9},
		{"to": func(p): return local.call(p).point_at(5.2) + Vector3(0, 0.85, 0),
			"when": func(p): return local.call(p).along() >= 0.999},
		{"to": Vector3(-29, 1, -63.0)},
		{"to": Vector3(-29, 1, -64.8), "jump": "jump", "aim": Vector3(-29, 2.4, -67.4)},
		{"to": Vector3(-29, 2.4, -68.2), "jump": "jump", "aim": Vector3(-29, 3.8, -70.7)},
		{"to": Vector3(-29, 3.8, -71.6), "jump": "jump", "aim": Vector3(-29, 4.5, -75.0)},
		{"to": Vector3(-29, 4.5, -80.6)},
	]


func _giftstack() -> Array:
	var lift := func(p: Play) -> MovingPlatform: return (p.level as GiftStackClimb).lift
	var slid := func(p: Play) -> float: return lift.call(p).position.z - GiftStackClimb.LIFT_HOME.z
	return [
		{"to": Vector3(-2.3, 0, 12.5), "jump": "jump", "aim": Vector3(1.4, 0, 12.2)},
		{"to": Vector3(5.6, 0, 10.5), "walk": true, "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(10, 3.5, 10), "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 3.0},
		# Up the crumbling shelves.
		{"to": Vector3(10, 3.5, 8.6), "jump": "jump", "aim": Vector3(10, 4.0, 5.0)},
		{"to": Vector3(10, 4.0, 4.4), "jump": "jump", "aim": Vector3(10, 4.6, 1.5)},
		{"to": Vector3(10, 4.6, 0.9), "jump": "jump", "aim": Vector3(10, 5.2, -2.0)},
		{"to": Vector3(10, 5.2, -2.6), "jump": "jump", "aim": Vector3(10, 5.8, -5.5)},
		{"to": Vector3(10, 5.8, -6.1), "jump": "jump", "aim": Vector3(10, 6.3, -9.6)},
		# West over the snowball lane, then kick up between the tall presents.
		{"to": Vector3(9.0, 6.3, -10.6)},
		{"to": Vector3(6.3, 6.3, -10.6), "jump": "jump", "aim": Vector3(2.7, 6.3, -10.6)},
		{"to": Vector3(0.5, 6.3, -10.4)},
		{"to": Vector3(0.5, 6.3, -9.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 11.1, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 10.6},
		{"to": Vector3(-0.3, 10.8, -9.0)},
		{"to": Vector3(-1.6, 10.8, -9.0), "jump": "jump", "aim": Vector3(-6.0, 11.3, -9.0)},
		# Ride the sliding block down the west side.
		{"to": Vector3(-10, 11.3, -5.6), "when": func(p): return absf(slid.call(p)) < 0.15},
		{"to": func(p): return lift.call(p).position, "when": func(p): return slid.call(p) > 7.8},
		{"to": Vector3(-9.5, 11.3, 7.4)},
		{"to": Vector3(-9.5, 11.3, 7.6), "jump": "jump", "aim": Vector3(-9.5, 12.3, 10.9)},
		{"to": Vector3(-9.5, 12.3, 11.3)},
	]
