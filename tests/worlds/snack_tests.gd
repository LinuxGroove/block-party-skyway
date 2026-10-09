extends RefCounted
## Snack Valley's tests, run by tests/run_tests.gd: the island's stars, the
## Hungry Hog, and the course pilot's way through each course (legs(), see
## tests/course_pilot.gd).

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"cake_climb":
			return _cake_climb()
		"donut_hop":
			return _donut_hop()
		"kitchen_dash":
			return _kitchen_dash()
		"fizzy_crossing":
			return _fizzy_crossing()
	return []


## Snack Valley: the boss door shut at first, Coco's cherries, the sprinkle
## rush, the top of the Wedding Cake, the star behind the chocolate falls,
## the runaway donut, the boss door open, the two hidden gems, a course
## door, and falling off; then the Hungry Hog.
func run() -> void:
	await _island()
	await _boss()


func _island() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("snack", "adventure")
	await t._ticks(10)
	var isle := play.level as SnackValley
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands in Snack Valley")
	# The Hog's door is shut until five stars are found.
	var boss_door: BossDoor = isle.find_children("*", "BossDoor", true, false)[0]
	t.check(not boss_door.is_open(), "the Hog's door is shut at first")
	h.place(boss_door.global_position + boss_door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == boss_door, "the Hog's door can be tried")
	boss_door.talk()
	await t._ticks(4)
	t.check(play.level == isle, "a shut door doesn't let you in")
	# Coco's cherries: touch each one and it hops back onto the sundae.
	h.place(isle.coco.global_position + Vector3(0, 0.1, 1.2))
	await t._ticks(4)
	t.check(isle.nearest_talker() == isle.coco, "Coco is there to talk to")
	isle.coco.talk()
	t.check(play.speech_open(), "Coco explains about her cherries")
	while play.speech_open():
		play._next_line()
	for c in isle.cherries:
		h.place(c.global_position + Vector3.UP * 0.1)
		await t._until(func(): return c.is_home, 3.0)
	t.check(await t._until(func(): return isle.cherries_home == 3, 3.0), "all three cherries go back on the sundae")
	t.check(play.speech_open(), "Coco thanks you")
	while play.speech_open():
		play._next_line()
	await t._ticks(2)
	await _collect(play, "snack/cherries", "Coco gives a star")
	# The sprinkle rush: step on the button, grab the eight coins.
	h.place(isle.rush.button.global_position + Vector3.UP * 0.1)
	t.check(await t._until(func(): return isle.rush.time_left > 0.0, 1.0), "the button starts the sprinkle rush")
	for p in isle.rush.coins.duplicate():
		if is_instance_valid(p):
			h.place(p.global_position - Vector3.UP * 0.2)
			await t._ticks(6)
	await _collect(play, "snack/sprinkles", "eight silver coins give a star")
	# The Wedding Cake: a high jump, the wafers, then kicks up beside the candle.
	h.place(CAKE_START, Vector3.FORWARD)
	t.check(await t._pilot(play, cake_top_legs(), 25.0), "the Wedding Cake can be climbed for its star (at %s)" % h.global_position)
	t.check(Progress.has_star("snack/cake_top"), "the Wedding Cake's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# Behind the chocolate falls.
	h.place(Vector3(-4, 0.05, -6), Vector3.FORWARD)
	t.check(await t._pilot(play, [
		{"to": Vector3(-4, 0, -11.6), "walk": true, "until": func(_p): return Progress.has_star("snack/falls")},
	], 10.0), "there's a star behind the chocolate falls")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The runaway donut: chase it into a corner.
	h.place(Vector3(-3, 0.35, 1.5), Vector3.FORWARD)
	t.check(await t._pilot(play, [
		{"to": func(_p): return isle.donut.global_position, "until": func(_p): return isle.donut.is_caught},
	], 30.0), "the runaway donut can be caught")
	await _collect(play, "snack/runaway", "the runaway donut had a star inside")
	t.check(boss_door.is_open(), "five stars open the Hog's door")
	# The pantry crate: only a ground pound opens it.
	await t._until(func(): return not h.is_locked(), 3.0)
	var crate: Breakable = null
	for b in isle.find_children("*", "Breakable", true, false):
		if (b as Breakable).contents == "gem:snack/gem_pantry":
			crate = b
	t.check(crate != null, "the kitchen has the pantry crate")
	if crate:
		h.place(crate.global_position + Vector3.UP * 3.0)
		await t._drive(h, 50, func(inp, i): inp.crouch_pressed = i == 8)
		t.check(not is_instance_valid(crate), "a ground pound breaks the pantry crate")
		t.check(await t._until(func(): return Progress.has_gem("snack/gem_pantry"), 3.0), "the pantry gem is found")
	# The fizzy geyser by the lake lifts the hero up to a gem.
	h.place(Vector3(-19, 0.4, 0.8), Vector3.FORWARD)
	await t._ticks(10)
	t.check(await t._pilot(play, [
		{"to": Vector3(-19.2, 0, -0.4), "jump": "jump", "aim": func(p, _s): return Vector3(-19.5, 6.0, -3.4) if p.hero.global_position.y < 7.0 else Vector3(-19.5, 6.0, -5.8)},
		{"to": Vector3(-19.5, 6.0, -6.0), "until": func(_p): return Progress.has_gem("snack/gem_fizz")},
	], 15.0), "the geyser lifts the hero to the gem over the lake")
	t.check(Progress.has_gem("snack/gem_fizz"), "the geyser's gem is found")
	# The course doors lead into the courses.
	var door: CourseDoor = null
	for d in isle.find_children("*", "CourseDoor", true, false):
		if (d as CourseDoor).course_id == "kitchen_dash":
			door = d
	await t._until(func(): return not h.is_locked(), 3.0)
	h.place(door.global_position + door.facing * 1.2 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(isle.nearest_talker() == door, "the Kitchen Dash door can be used")
	var left := 0
	for id in Worlds.star_ids("snack"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("snack"):
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


## Touches the star `id` once it's out (unless the hero already has);
## checks it's found.
func _collect(play: Play, id: String, what: String) -> void:
	var out := await t._until(func(): return Progress.has_star(id) or t._find_star(play.level, id) != null, 3.0)
	t.check(out, what)
	var star := t._find_star(play.level, id)
	if star and not Progress.has_star(id):
		play.hero.place(star.global_position - Vector3.UP * 0.4)
	t.check(await t._until(func(): return Progress.has_star(id), 2.0), "%s is found" % id)
	await t._until(func(): return not play.hero.is_locked(), 3.0)


## Where the climb up the Wedding Cake starts, and the pilot's way up: a
## high jump onto the first tier, the wafers to the second, then kicks
## between the top tier and the candle.
const CAKE_START := Vector3(23, 0.05, -11.2)


func cake_top_legs() -> Array:
	return [
		{"to": Vector3(23, 0, -12.6), "jump": "high", "aim": Vector3(23, 2.5, -14.6)},
		{"to": Vector3(23, 2.5, -14.8), "jump": "jump", "aim": Vector3(23, 4.0, -17.2)},
		{"to": Vector3(23, 4.0, -17.5), "jump": "jump", "aim": Vector3(23, 5.5, -20.2)},
		{"to": Vector3(23, 5.5, -20.5), "jump": "jump", "aim": Vector3(23, 7.0, -22.9)},
		{"to": Vector3(22.5, 7.0, -25.0), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": 11.8, "off": Vector3.LEFT,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > 11.4},
		{"to": Vector3(19.5, 11.5, -25.0), "until": func(_p): return Progress.has_star("snack/cake_top")},
	]


# --- The Hungry Hog ----------------------------------------------------------

## Where to wait for a charge: between the Hog's home and cake `k`.
static func _hog_wait(hog: HungryHog, k: int) -> Vector3:
	var c: Vector3 = hog.cakes[k][0]
	var to := c - hog.home
	to.y = 0.0
	return hog.home + to.normalized() * 4.5


## A step back along his charge line from where it ends.
static func _hog_back(hog: HungryHog, metres: float) -> Vector3:
	return hog.charge_end - hog.charge_dir * metres


## Beside the end of his charge line, on the side nearer the middle.
static func _hog_dodge(hog: HungryHog) -> Vector3:
	var side := hog.charge_dir.cross(Vector3.UP).normalized()
	var spot := _hog_back(hog, 4.2)
	if (spot + side).length() > (spot - side).length():
		side = -side
	return spot + side * 2.6


## The Hungry Hog: he says his piece, then three charges. Each time the
## hero waits in front of a cake, steps out of the line when it shows,
## and once he's stuck in the cake, runs up behind him and jumps on his
## back.
func _boss() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("hungry_hog", "adventure")
	await t._ticks(6)
	var pen := play.level as HogPen
	var hog := pen.hog
	var h := play.hero
	var said: Array[String] = []
	pen.message.connect(func(text): said.append(text))
	var hurts := [0]
	pen.hurt.connect(func(_f): hurts[0] += 1)
	t.check(await t._until(func(): return not said.is_empty(), 3.0), "the Hog says something as the fight starts")
	for i in 3:
		var health := hog.health
		var k: int = [0, 3, 5][i]
		var ok := await t._pilot(play, [
			{"to": func(_p): return _hog_wait(hog, k), "until": func(_p): return hog.is_aiming()},
			{"to": func(_p): return _hog_dodge(hog), "until": func(_p): return hog.is_stuck()},
			{"to": func(_p): return _hog_back(hog, 4.2), "stop": true},
			{"to": func(_p): return _hog_back(hog, 2.3), "jump": "jump", "aim": func(_p, _s): return hog.global_position - hog.charge_dir * 0.3},
		], 20.0)
		t.check(ok and hog.health == health - 1, "a jump on the stuck Hog's back is a hit (%d left)" % hog.health)
	t.check(hog.beaten, "three hits beat the Hungry Hog")
	t.check(hurts[0] == 0, "the hero dodges every charge (%d hits)" % hurts[0])
	t.check(await t._until(func(): return t._find_star(pen, "snack/boss") != null, 3.0), "the Hog leaves a star")
	await _collect(play, "snack/boss", "the Hog's star is out")
	# Falling off the pen comes back at its flag.
	await t._until(func(): return not h.is_locked(), 3.0)
	h.place(Vector3(0, -20, 30))
	await t._ticks(3)
	t.check(h.global_position.y > -1.0 and Vector2(h.global_position.x, h.global_position.z).length() < 10.0, "falling off the pen comes back at its flag")
	t._fast(false)
	await t._free(play)


static func _landed(p: Play, y: float) -> bool:
	return p.hero.is_on_floor() and p.hero.global_position.y > y - 0.1


# --- Layer Cake Climb --------------------------------------------------------

static func _fork_clear(p: Play) -> bool:
	var a := ((p.level as LayerCakeClimb).fork as SnackSkewer).angle()
	return a > 282.0 and a < 335.0


static func _lift(p: Play) -> SnackRaft:
	return (p.level as LayerCakeClimb).lift


static func _glider(p: Play) -> SnackRaft:
	return (p.level as LayerCakeClimb).glider


## The pilot's way up Layer Cake Climb: bounce on the pudding, jump the
## fruit, hop the wafers, slip past the fork, ride the pancake lift, jump
## the fruit again and double jump onto the topper.
func _cake_climb() -> Array:
	return [
		{"to": Vector3(0, 0, 15.4), "jump": "jump", "aim": Vector3(0, 0, 12.3)},
		{"to": Vector3(0, 0, 11.0), "when": func(p): return absf(_glider(p).top_ahead(0.55).x) < 0.4, "jump": "jump", "aim": func(p, s): return _glider(p).top_ahead(s) + Vector3(0, 0, 0.3)},
		{"to": func(p): return _glider(p).top_ahead(0.0) + Vector3(0, 0, -0.9), "jump": "jump", "aim": Vector3(0, 0, 2.6)},
		{"to": Vector3(0, 0, -2.5), "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(0, 4.0, -8.6), "until": func(p): return _landed(p, 4.0)},
		{"to": Vector3(0, 4.0, -9.3), "jump": "jump", "aim": Vector3(0, 4.0, -12.8)},
		{"to": Vector3(0, 4.0, -14.0), "jump": "jump", "aim": Vector3(0, 5.2, -16.0)},
		{"to": Vector3(0, 5.2, -16.6), "jump": "jump", "aim": Vector3(0, 6.4, -19.0)},
		{"to": Vector3(0, 6.4, -19.6), "jump": "jump", "aim": Vector3(0, 7.6, -23.0)},
		{"to": Vector3(-1.2, 7.6, -25.7), "when": _fork_clear},
		{"to": Vector3(-11.2, 7.6, -25.7)},
		{"to": Vector3(-10, 7.6, -27.6), "when": func(p): return _lift(p).top_ahead(0.3).y < 7.75},
		{"to": Vector3(-10, 7.6, -29.75), "when": func(p): return _lift(p).position.y > 10.95},
		{"to": Vector3(-10, 11.0, -30.9), "jump": "jump", "aim": Vector3(-10, 11.0, -34.5)},
		{"to": Vector3(-10, 11.0, -35.2), "jump": "jump", "aim": Vector3(-10, 11.0, -38.8)},
		{"to": Vector3(-10, 11.0, -39.7), "jump": "jump", "aim": Vector3(-10, 11.0, -43.3)},
		{"to": Vector3(-10, 11.0, -44.6), "jump": "double", "aim": Vector3(-10, 13.5, -49.5)},
		{"to": Vector3(-10, 13.5, -53.0)},
	]


# --- Donut Hop ---------------------------------------------------------------

static func _gliders(p: Play) -> Array[SnackRaft]:
	return (p.level as DonutHop).gliders


## The pilot's way over Donut Hop: the zig-zag, the two gliders (each
## caught as it swings under the next jump), the crumbling donuts without
## stopping, the pudding up to the giant donut, and down the bobbing ones.
func _donut_hop() -> Array:
	return [
		{"to": Vector3(-0.7, 0, -1.6), "jump": "jump", "aim": Vector3(-1.2, 0, -5.0)},
		{"to": Vector3(-0.77, 0, -5.88), "jump": "jump", "aim": Vector3(1.2, 0.5, -9.0)},
		{"to": Vector3(0.8, 0.5, -9.69), "jump": "jump", "aim": Vector3(-1.0, 1.0, -12.8)},
		{"to": Vector3(-1.0, 1.0, -13.8), "when": func(p): return absf(_gliders(p)[0].top_ahead(0.6).x + 1.0) < 1.0, "jump": "jump", "aim": func(p, s): return _gliders(p)[0].top_ahead(s)},
		{"to": func(p): return _gliders(p)[0].top_ahead(0.0) + Vector3(0, 0, -0.8), "when": func(p): return absf(_gliders(p)[1].top_ahead(0.6).x - _gliders(p)[0].top_ahead(0.6).x) < 1.0, "jump": "jump", "aim": func(p, s): return _gliders(p)[1].top_ahead(s)},
		{"to": func(p): return _gliders(p)[1].top_ahead(0.0) + Vector3(0, 0, -0.8), "jump": "jump", "aim": func(p, s): return Vector3(clampf(_gliders(p)[1].top_ahead(0.0).x, -2.0, 2.0), 1.0, -26.2)},
		{"to": Vector3(0.4, 1.0, -27)},
		{"to": Vector3(2.4, 1.0, -27), "jump": "jump", "aim": Vector3(6.2, 1.0, -27)},
		{"to": Vector3(7.0, 1.0, -27), "jump": "jump", "aim": Vector3(9.8, 1.5, -27)},
		{"to": Vector3(10.6, 1.5, -27), "jump": "jump", "aim": Vector3(13.4, 2.0, -27)},
		{"to": Vector3(14.2, 2.0, -27), "jump": "jump", "aim": Vector3(17.0, 2.5, -27)},
		{"to": Vector3(17.8, 2.5, -27), "jump": "jump", "aim": Vector3(20.0, 3.0, -27)},
		{"to": Vector3(21.2, 3.0, -27), "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(25.5, 6.5, -27), "until": func(p): return _landed(p, 6.5)},
		{"to": Vector3(27.0, 6.5, -27), "jump": "jump", "aim": Vector3(29.8, 5.6, -27)},
		{"to": Vector3(30.6, 5.6, -27), "jump": "jump", "aim": Vector3(33.4, 4.8, -27)},
		{"to": Vector3(34.2, 4.8, -27), "jump": "jump", "aim": Vector3(37.0, 4.0, -27)},
		{"to": Vector3(37.8, 4.0, -27), "jump": "jump", "aim": Vector3(41.0, 3.0, -27)},
		{"to": Vector3(44.5, 3.0, -27)},
	]


# --- Kitchen Dash ------------------------------------------------------------

## True just as a pot starts to lift, so a runner reaches it high and gets
## through before it slams.
static func _press_lifting(p: Play, i: int) -> bool:
	var press: SnackPress = (p.level as KitchenDash).presses[i]
	return press.position.y > 0.3 and press.position.y < 1.0 and not press.is_falling()


## True just after a skewer arm has swept past the west end of the path.
static func _skewer_clear(p: Play) -> bool:
	var a := fposmod((p.level as KitchenDash).skewer.angle(), 180.0)
	return a > 108.0 and a < 126.0


## The pilot's way through Kitchen Dash: jump the fruit on the belt, wait
## for the first pot to lift and run under both, cross the sideways belts,
## slip past the skewer and hop up the pancakes.
func _kitchen_dash() -> Array:
	return [
		{"to": Vector3(0, 0, -4.4), "jump": "jump", "aim": Vector3(0, 0, -8.8)},
		{"to": Vector3(0, 0, -10.6), "jump": "jump", "aim": Vector3(0, 0, -15.0)},
		{"to": Vector3(0, 0, -16.8), "jump": "jump", "aim": Vector3(0, 0, -21.2)},
		{"to": Vector3(0, 0, -23.2), "when": func(p): return _press_lifting(p, 0)},
		{"to": Vector3(0, 0, -38.6)},
		{"to": Vector3(0.6, 0, -42.2)},
		{"to": Vector3(20.6, 0, -42.0), "when": _skewer_clear},
		{"to": Vector3(27.4, 0, -42.0), "jump": "jump", "aim": Vector3(29.9, 0.96, -42.0)},
		{"to": Vector3(30.8, 0.96, -42.0), "jump": "jump", "aim": Vector3(34.1, 1.92, -42.0)},
		{"to": Vector3(35.0, 1.92, -42.0), "jump": "jump", "aim": Vector3(38.3, 2.88, -42.0)},
		{"to": Vector3(46.0, 3.0, -42.0)},
	]


# --- Fizzy Crossing ----------------------------------------------------------

## Into the geyser's fizz until high enough, then over to the cloud.
static func _ride_geyser(p: Play, _secs: float) -> Vector3:
	if p.hero.global_position.y < 7.8:
		return Vector3(0, 7.0, -33.2)
	return Vector3(0, 7.0, -37.6)


## The pilot's way over Fizzy Crossing: hop the donuts and the sinking
## cookies without stopping, step into the geyser and ride it up, cross the
## cloud and its wafers, and drop onto the cans.
func _fizzy_crossing() -> Array:
	return [
		{"to": Vector3(-0.6, 0.5, 0.4), "jump": "jump", "aim": Vector3(-1.2, 0.3, -3.2)},
		{"to": Vector3(-1.0, 0.3, -3.9), "jump": "jump", "aim": Vector3(1.2, 0.3, -7.0)},
		{"to": Vector3(0.9, 0.3, -7.7), "jump": "jump", "aim": Vector3(-1.0, 0.3, -10.8)},
		{"to": Vector3(-0.8, 0.3, -11.5), "jump": "jump", "aim": Vector3(0.8, 0.3, -14.6)},
		{"to": Vector3(0.6, 0.3, -15.3), "jump": "jump", "aim": Vector3(-0.8, 0.3, -18.2)},
		{"to": Vector3(-0.6, 0.3, -18.9), "jump": "jump", "aim": Vector3(0.6, 0.3, -21.8)},
		{"to": Vector3(0.5, 0.3, -22.5), "jump": "jump", "aim": Vector3(0, 0.5, -26.0)},
		{"to": Vector3(0, 0.5, -30.4), "jump": "jump", "aim": _ride_geyser},
		{"to": Vector3(0, 7.0, -38.0)},
		{"to": Vector3(0, 7.0, -43.4), "jump": "jump", "aim": Vector3(0, 7.0, -46.8)},
		{"to": Vector3(0, 7.0, -47.2), "jump": "jump", "aim": Vector3(0, 7.0, -50.8)},
		{"to": Vector3(0, 7.0, -51.2), "jump": "jump", "aim": Vector3(0, 7.0, -55.0)},
		{"to": Vector3(0, 7.0, -59.4), "jump": "jump", "aim": Vector3(0, 1.2, -63.5)},
		{"to": Vector3(0.3, 1.2, -64.1), "jump": "jump", "aim": Vector3(2.2, 1.2, -67.3)},
		{"to": Vector3(2.0, 1.2, -68.0), "jump": "jump", "aim": Vector3(-0.4, 1.2, -71.1)},
		{"to": Vector3(-0.2, 1.2, -71.8), "jump": "jump", "aim": Vector3(1.6, 1.2, -74.9)},
		{"to": Vector3(1.4, 1.2, -75.6), "jump": "jump", "aim": Vector3(0.4, 1.2, -79.0)},
		{"to": Vector3(0, 1.2, -84.5)},
	]
