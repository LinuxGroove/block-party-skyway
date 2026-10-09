extends RefCounted
## The Star Road's tests, run by tests/run_tests.gd: Stardust Plaza's two
## stars (the silver lap and the top of the spire), its hidden gem and the
## Skyway gate back to Star Station, and the course pilot's way through
## each of the eight courses (legs(), see tests/course_pilot.gd).
##
## The courses' hazards keep their own time, so the pilot often waits for
## a gap: _clear_run() looks ahead at every spinner, saw, critter, crusher,
## spike trap and cannonball to see whether a run would get through
## untouched.

const CoursePilot := preload("res://tests/course_pilot.gd")
const Runner := preload("res://tests/run_tests.gd")

## The test runner, for check(), _until(), _make_play() and the rest.
var t: Runner


## The pilot's legs through one of this world's courses.
func legs(course_id: String) -> Array:
	match course_id:
		"rainbow_rush":
			return _rainbow_rush()
		"cannon_crypts":
			return _cannon_crypts()
		"sugar_gears":
			return _sugar_gears()
		"moon_ramparts":
			return _moon_ramparts()
		"blizzard_bluffs":
			return _blizzard_bluffs()
		"haunted_heights":
			return _haunted_heights()
		"bounce_hollow":
			return _bounce_hollow()
		"starlight_finale":
			return _starlight_finale()
	return []


# --- Stardust Plaza ----------------------------------------------------------

## Stardust Plaza: no boss door, a door to every course, the gate back to
## Star Station, the silver lap round the ring, the spire's chimney climb,
## and the gem below the north path.
func run() -> void:
	t._fast(true)
	Progress.wipe()
	var play := t._make_play("star", "adventure")
	await t._ticks(10)
	var plaza := play.level as StarPlaza
	var h := play.hero
	t.check(h.is_on_floor(), "the hero lands on Stardust Plaza")
	t.check(plaza.find_children("*", "BossDoor", true, false).is_empty(), "the Star Road has no boss door")
	var doors := {}
	for d in plaza.find_children("*", "CourseDoor", true, false):
		doors[(d as CourseDoor).course_id] = true
	t.check(doors.size() == 8, "eight course doors round the plaza (%d)" % doors.size())
	# The Skyway gate back to Star Station (there's no world after this one).
	var gates := plaza.find_children("*", "SkywayGate", true, false)
	t.check(gates.size() == 1 and (gates[0] as SkywayGate).to_world == "station", "one Skyway gate, back to Star Station")
	t.check(plaza.gate.is_open() == Worlds.is_built("station"), "the way back is open once Star Station is there")
	h.place(plaza.gate.global_position + plaza.gate.facing * 1.4 + Vector3.UP * 0.05)
	await t._ticks(4)
	t.check(plaza.nearest_talker() == plaza.gate, "the gate can be used")
	plaza.gate.talk()
	t.check(play._leaving == plaza.gate.is_open(), "the gate leads back only when it's open")
	if play._leaving:
		await t._free(play)
		play = t._make_play("star", "adventure")
		await t._ticks(10)
		plaza = play.level as StarPlaza
		h = play.hero
	# The silver lap: the button, then a silver coin on every pad.
	h.place(plaza.silver.button.global_position + Vector3(0, 0.1, 0.8), Vector3.FORWARD)
	await t._ticks(4)
	h.place(plaza.silver.button.global_position + Vector3.UP * 0.1, Vector3.FORWARD)
	t.check(await t._until(func(): return plaza.silver.is_running(), 1.0), "the button starts the silver lap")
	var lap := _silver_lap(plaza)
	t.check(await t._pilot(play, lap, StarPlaza.SILVER_TIME + 2.0), "the pilot runs the ring")
	t.check(plaza.silver.got == StarPlaza.PADS.size(), "a silver coin on every pad, all found in time (%d)" % plaza.silver.got)
	var star := t._find_star(plaza, "star/silver")
	t.check(star != null, "the silver lap gives a star")
	if star:
		var back := [
			{"to": Vector3(0, 0, 15.5)},
			{"to": Vector3(0, 0, 8.0)},
			{"to": star.global_position + Vector3(0, -1.2, 0.8), "stop": true, "jump": "jump", "aim": star.global_position},
		]
		await t._pilot(play, back, 8.0)
		t.check(await t._until(func(): return Progress.has_star("star/silver"), 2.0), "the silver star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The spire: four double jumps round the corners, then the chimney.
	h.place(Vector3(3.5, 0.05, 8.6), Vector3.FORWARD)
	await t._ticks(4)
	var climb := _spire_climb(h)
	t.check(await t._pilot(play, climb, 30.0), "the spire can be climbed (at %s)" % h.global_position)
	t.check(Progress.has_star("star/spire"), "the spire's star is found")
	await t._until(func(): return not h.is_locked(), 3.0)
	# The hidden gem: off the north path, onto the ledge below, and the
	# spring back up.
	var ledge := StarPlaza.GEM_LEDGE
	h.place(Vector3(0, 0.05, -16.4), Vector3.FORWARD)
	await t._ticks(4)
	var gem := [
		{"to": Vector3(0, 0, -21.6), "walk": true, "until": func(_p): return Progress.has_gem("star/gem_hub")},
		{"to": Vector3(-1.0, ledge, -19.7), "walk": true, "until": func(_p): return h.velocity.y > 10.0},
		{"to": Vector3(-1.0, 0, -16.6), "until": func(_p): return h.is_on_floor() and h.global_position.y > -0.2},
	]
	t.check(await t._pilot(play, gem, 15.0), "the gem below the north path, and the spring back up (at %s)" % h.global_position)
	t.check(Progress.has_gem("star/gem_hub"), "the plaza's gem is found")
	var left := 0
	for id in Worlds.star_ids("star"):
		left += 0 if Progress.has_star(id) else 1
	for id in Worlds.gem_ids("star"):
		left += 0 if Progress.has_gem(id) else 1
	t.check(plaza.secrets_left() == left, "secrets left counts what's still hidden (%d)" % plaza.secrets_left())
	# Arriving from Star Station comes out in front of the gate.
	await t._free(play)
	play = t._make_play("star", "adventure", {"door": "skyway:station"})
	await t._ticks(6)
	var g := (play.level as StarPlaza).gate
	t.check(play.hero.global_position.distance_to(g.global_position) < 2.5, "the Skyway from Star Station arrives at the gate")
	t._fast(false)
	await t._free(play)


## Up the spire: four double jumps round its corners, then kick up the
## chimney between the spire and its fin, and walk to the star.
static func _spire_climb(h: Hero) -> Array:
	var top := StarPlaza.SPIRE_TOP
	return [
		{"to": Vector3(3.5, 0, 7.0), "jump": "jump", "aim": Vector3(3.5, 1.5, 3.8)},
		{"to": Vector3(3.5, 1.5, 2.4), "jump": "double", "aim": Vector3(3.5, 4.0, -3.4)},
		{"to": Vector3(2.4, 4.0, -3.5), "jump": "double", "aim": Vector3(-3.4, 6.5, -3.5)},
		{"to": Vector3(-3.5, 6.5, -2.4), "jump": "double", "aim": Vector3(-3.5, 9.0, 3.4)},
		{"to": Vector3(-1.5, 9.0, 2.5), "walk": true},
		{"to": Vector3(0.0, 9.0, 2.5), "walk": true},
		{"wall": true, "toward": Vector3.BACK, "top": top + 0.3, "off": Vector3.FORWARD,
			"until": func(_p): return h.is_on_floor() and h.global_position.y > top - 0.1},
		{"to": Vector3(0, top, 0), "walk": true, "until": func(_p): return Progress.has_star("star/spire")},
	]


## Round the ring through every pad's silver coin, from the button.
static func _silver_lap(plaza: StarPlaza) -> Array:
	var spots := []
	for p in StarPlaza.PADS:
		spots.append(p + (Vector3.ZERO - p).normalized() * 1.2)
	return [
		{"to": Vector3(-6, 0, 8)},
		{"to": Vector3(-6, 0, 14)},
		{"to": spots[4]},
		{"to": Vector3(-9, 0, 15)},
		{"to": Vector3(-15, 0, 9)},
		{"to": spots[5]},
		{"to": Vector3(-17, 0, 4.2)},
		{"to": Vector3(-17, 0, -4.2)},
		{"to": spots[6]},
		{"to": Vector3(-15, 0, -9)},
		{"to": Vector3(-9, 0, -15)},
		{"to": spots[7]},
		{"to": Vector3(-4.2, 0, -17)},
		{"to": Vector3(4.2, 0, -17)},
		{"to": spots[3]},
		{"to": Vector3(9, 0, -15)},
		{"to": Vector3(15, 0, -9)},
		{"to": spots[2]},
		{"to": Vector3(17, 0, -4.2)},
		{"to": Vector3(17, 0, 4.2)},
		{"to": spots[1]},
		{"to": Vector3(15, 0, 9)},
		{"to": Vector3(9, 0, 15)},
		{"to": spots[0], "until": func(_p): return plaza.silver.got >= StarPlaza.PADS.size()},
	]


# --- Looking ahead at hazards ------------------------------------------------

## Metres covered `secs` after setting off at `v0`, speeding up at `accel`
## to a run.
static func _dist_after(secs: float, v0: float, accel: float) -> float:
	var v := Hero.RUN_SPEED
	var ta := maxf((v - v0) / accel, 0.0)
	if secs <= ta:
		return v0 * secs + 0.5 * accel * secs * secs
	return v0 * ta + 0.5 * accel * ta * ta + (secs - ta) * v


## True if the hero, setting off now from `from` and running straight to
## `to`, keeps clear of every hazard on the way. `ice_from` is how far along
## the ice starts (it's slow to speed up on), and `drag` the speed of a belt
## running against the hero.
static func _clear_run(play: Play, from: Vector3, to: Vector3, margin := 0.3, ice_from := INF, drag := 0.0) -> bool:
	var level := play.level
	var hazards := []
	for kind in ["Spinner", "Saw", "Critter", "Crusher", "SpikeTrap", "Projectile", "Launcher"]:
		hazards.append_array(level.find_children("*", kind, true, false))
	var length := from.distance_to(to)
	var v := play.hero.horizontal_speed()
	var d := 0.0
	var secs := 0.0
	var dt := 1.0 / 60.0
	while true:
		var at := from + (to - from) * minf(d / maxf(length, 0.01), 1.0)
		for hz in hazards:
			if is_instance_valid(hz) and _hits(hz, at, secs, margin):
				return false
		if d >= length:
			break
		var accel := Hero.GROUND_ACCEL * (0.35 if d >= ice_from else 1.0)
		v = minf(v + accel * dt, Hero.RUN_SPEED)
		d += maxf(v - drag, 0.0) * dt
		secs += dt
	return true


## Whether a hazard would touch a hero standing at `at`, `secs` from now.
static func _hits(hz: Node, at: Vector3, secs: float, margin: float) -> bool:
	if hz is Spinner:
		var sp := hz as Spinner
		var rel := at - sp.global_position
		rel.y = 0.0
		var reach := sp.length + 0.5 + 0.3 + margin
		if rel.length() > reach + 0.6:
			return false
		var ang := deg_to_rad(sp._arm.rotation_degrees.y + sp.speed * secs)
		for a in sp.arms:
			var th := ang + TAU * a / sp.arms
			var dir := Vector3(sin(th), 0, cos(th))
			var along := rel.dot(dir)
			if along > 0.0 and along < reach and (rel - dir * along).length() < 0.28 + 0.3 + margin:
				return true
		return false
	if hz is Saw:
		var s := hz as Saw
		var c := s.global_position + s.travel * _wave(s._t + secs, s.period)
		return _flat(c - at) < 0.55 + 0.3 + margin and absf(c.y - at.y) < 1.0
	if hz is Critter:
		var cr := hz as Critter
		if cr.defeated or cr.chase_range > 0.0:
			return false
		var c := cr._start + cr.travel * _wave(cr._t + secs, cr.period)
		if cr.get_parent() != null and cr.get_parent() is Node3D:
			c = (cr.get_parent() as Node3D).global_transform * c
		return _flat(c - at) < 0.45 + 0.3 + margin and at.y < c.y + 1.0 + cr.bob * 2.0 and at.y > c.y - 1.0
	if hz is Crusher:
		var k := hz as Crusher
		var rel := at - k._home
		if absf(rel.x) > k.size.x / 2.0 + 0.3 + margin or absf(rel.z) > k.size.z / 2.0 + 0.3 + margin:
			return false
		return k.offset_at(k._t + secs) < 1.3 + margin
	if hz is SpikeTrap:
		var sk := hz as SpikeTrap
		if _flat(sk.global_position - at) > 0.48 + 0.3 + margin or absf(sk.global_position.y - at.y) > 0.6:
			return false
		var beat := SpikeTrap.DOWN_TIME + SpikeTrap.UP_TIME
		var u := fposmod(sk._t + secs, beat)
		return u >= SpikeTrap.DOWN_TIME - 0.12 or u < 0.05
	if hz is Projectile:
		var pr := hz as Projectile
		var p := pr.global_position + pr.velocity * secs + Vector3.DOWN * 0.5 * pr.fall * secs * secs
		return secs < pr.life and _near_body(p, at, pr.radius + 0.3 + margin)
	if hz is Launcher:
		var l := hz as Launcher
		var first := l.period - l._t
		var k := 0
		while first + k * l.period <= secs:
			var age := secs - (first + k * l.period)
			if age < l.shot_life:
				var p := l.global_position + l.muzzle + l.direction * (1.0 + l.speed * age) + Vector3.DOWN * 0.5 * l.shot_gravity * age * age
				if _near_body(p, at, 0.35 + 0.3 + margin):
					return true
			k += 1
		return false
	return false


static func _wave(secs: float, period: float) -> float:
	return (1.0 - cos(TAU * secs / period)) / 2.0


static func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()


## Whether a point is within `r` of the hero's body standing at `at`.
static func _near_body(p: Vector3, at: Vector3, r: float) -> bool:
	var y := clampf(p.y, at.y + 0.3, at.y + 0.56)
	return p.distance_to(Vector3(at.x, y, at.z)) < r


## True if a cannonball flying down a lane is between `lo` and `hi` metres
## from `at`, still coming.
static func _ball_coming(play: Play, at: Vector3, lo: float, hi: float) -> bool:
	for n in play.level.find_children("*", "Projectile", true, false):
		var pr := n as Projectile
		if pr.velocity.length() < 0.1:
			continue
		var back := -pr.velocity.normalized()
		var rel := pr.global_position - at
		var d := rel.dot(back)
		var off := rel - back * d
		off.y = 0.0
		if d > lo and d < hi and off.length() < 1.0:
			return true
	return false


## The crusher whose home is nearest `at`.
static func _crusher_at(play: Play, at: Vector3) -> Crusher:
	var best: Crusher = null
	for n in play.level.find_children("*", "Crusher", true, false):
		var k := n as Crusher
		if best == null or k._home.distance_to(at) < best._home.distance_to(at):
			best = k
	return best


## How far through its cycle (in seconds) the crusher nearest `at` is,
## `ahead` seconds from now.
static func _crusher_time(play: Play, at: Vector3, ahead := 0.0) -> float:
	var k := _crusher_at(play, at)
	return fposmod(k._t + ahead, k.cycle())


## True if the lift at `at` is down (or only just rising) and will be when
## a jump onto it lands.
static func _lift_ready(play: Play, at: Vector3) -> bool:
	var k := _crusher_at(play, at)
	return _crusher_time(play, at) < k.down_time + 0.2 - 0.55


## True if the lift at `at` is up, with time left to jump off.
static func _lift_up(play: Play, at: Vector3) -> bool:
	var k := _crusher_at(play, at)
	var u := _crusher_time(play, at)
	return u >= k.down_time + k.rise_time and u < k.down_time + k.rise_time + k.up_time - 0.45


## A level's moving platforms of one row (by z or x), nearest the start
## first.
static func _platforms(play: Play) -> Array:
	var list := play.level.find_children("*", "MovingPlatform", true, false)
	list.sort_custom(func(a, b): return a.position.z > b.position.z)
	return list


## Where moving platform `i` will be in `ahead` seconds.
static func _plat_at(play: Play, i: int, ahead: float) -> Vector3:
	var p: MovingPlatform = _platforms(play)[i]
	return p.global_position - p.offset_at(p._t) + p.offset_at(p._t + ahead)


# --- Rainbow Rush ------------------------------------------------------------

## Over the saw lines and spikes, wait for the spinners and cross the ice,
## ride the sliding platforms, double jump the shelf, hop the ice blocks
## and run up the rainbow to the flag.
func _rainbow_rush() -> Array:
	var out := [
		{"to": Vector3(0, 0, -8.0), "jump": "jump", "aim": Vector3(0, 0, -12.0)},
		{"to": Vector3(0, 0, -12.4), "jump": "jump", "aim": Vector3(0, 0, -16.2)},
		{"to": Vector3(0, 0, -16.6), "jump": "jump", "aim": Vector3(0, 0, -20.0)},
		{"to": Vector3(0, 0, -25.0), "when": func(p): return _clear_run(p, Vector3(0, 0, -25.0), Vector3(0, 0, -42.5), 0.35, 1.0)},
		{"to": Vector3(0, 0, -44.6), "when": func(p): return absf(_plat_at(p, 0, 0.7).x) < 1.0},
		{"to": Vector3(0, 0, -45.6), "jump": "jump", "aim": func(p, s): return _plat_at(p, 0, s)},
		{"to": func(p): return Vector3(_plat_at(p, 0, 0).x, 0, -51.4), "jump": "jump", "aim": func(p, s): return _plat_at(p, 1, s)},
		{"to": func(p): return Vector3(_plat_at(p, 1, 0).x, 0, -55.9), "jump": "jump", "aim": Vector3(0, 0, -59.8)},
		{"to": Vector3(-2.0, 0, -62.0), "jump": "double", "aim": Vector3(-5.9, 2.5, -62.0)},
		{"to": Vector3(-6.4, 2.5, -62.0), "jump": "jump", "aim": Vector3(-9.6, 2.5, -62.0)},
		{"to": Vector3(-9.9, 2.5, -62.0), "jump": "jump", "aim": Vector3(-13.0, 2.5, -62.0)},
		{"to": Vector3(-13.4, 2.5, -62.0), "jump": "jump", "aim": Vector3(-16.5, 2.5, -62.0)},
	]
	for i in 5:
		out.append({"to": Vector3(-17.1 - i * 3.5, 2.5, -62.0), "jump": "jump", "aim": Vector3(-20.0 - i * 3.5, 2.5, -62.0)})
	out.append_array([
		{"to": Vector3(-34.6, 2.5, -62.0), "jump": "jump", "aim": Vector3(-38.0, 2.5, -62.0)},
		{"to": Vector3(-41.4, 2.5, -62.0), "jump": "jump", "aim": Vector3(-45.5, 2.5, -62.0)},
		{"to": Vector3(-45.9, 2.5, -62.0), "jump": "jump", "aim": Vector3(-49.5, 2.5, -62.0)},
		{"to": Vector3(-49.9, 2.5, -62.0), "jump": "jump", "aim": Vector3(-53.5, 2.5, -62.0)},
		{"to": Vector3(-68.0, 4.0, -62.0)},
	])
	return out


# --- Cannon Crypts -----------------------------------------------------------

## Hop over the dock's cannon lines, wait for each terrace's ghost to drift
## aside, hop the rotting planks, jump each cannonball down the gangway and
## step off to the flag.
func _cannon_crypts() -> Array:
	var out := [
		{"to": Vector3(0, 0, -8.0), "jump": "jump", "aim": Vector3(0, 0, -12.0)},
		{"to": Vector3(0, 0, -12.4), "jump": "jump", "aim": Vector3(0, 0, -16.0)},
		{"to": Vector3(0, 0, -16.4), "jump": "jump", "aim": Vector3(0, 0, -20.0)},
		{"to": Vector3(0, 0, -20.4), "jump": "jump", "aim": Vector3(0, 0, -24.0)},
	]
	for i in 3:
		var top := 1.5 * i
		var z0 := -27.0 - 10.0 * i
		out.append({"to": Vector3(0, top, z0), "when": func(p): return _clear_run(p, Vector3(0, top, z0), Vector3(0, top, z0 - 7.6))})
		out.append({"to": Vector3(0, top, z0 - 7.6), "jump": "jump", "aim": Vector3(0, top + (1.5 if i < 2 else 0.0), z0 - 10.6 - (0.4 if i == 2 else 0.0))})
	for i in CannonCrypts.PLANKS - 1:
		out.append({"to": Vector3(0, 3.0, -59.6 - i * 3.5), "jump": "jump", "aim": Vector3(0, 3.0, -62.5 - i * 3.5)})
	out.append({"to": Vector3(0, 3.0, -80.6), "jump": "jump", "aim": Vector3(0, 3.0, -84.0)})
	for z in CannonCrypts.GANGWAY_JUMPS:
		out.append({"to": Vector3(0, 3.0, z), "stop": true, "when": func(p): return _ball_coming(p, Vector3(0, 3.0, z), 0.6, 2.2),
			"jump": "jump", "aim": Vector3(0, 3.0, z - 3.6)})
	out.append_array([
		{"to": Vector3(2.6, 3.0, -108.0)},
		{"to": Vector3(7.5, 3.0, -108.5)},
	])
	return out


# --- Sugar Gears -------------------------------------------------------------

## Under the presses one gap at a time against the belt, between the cogs,
## onto the pancakes and across on the waffle, then up both lifts to the
## cake.
func _sugar_gears() -> Array:
	var belt := SugarGears.BELT_SPEED
	var out := []
	var stops := [-7.3, -12.5, -17.5, -22.6]
	for i in stops.size() - 1:
		var a := Vector3(0, 0, stops[i])
		var b := Vector3(0, 0, stops[i + 1])
		out.append({"to": a, "when": func(p): return _clear_run(p, a, b, 0.25, INF, belt)})
	var gaps := [-30.5, -38.5, -46.5, -55.2]
	for i in gaps.size() - 1:
		var a := Vector3(0, 0, gaps[i])
		var b := Vector3(0, 0, gaps[i + 1])
		out.append({"to": a, "when": func(p): return _clear_run(p, a, b, 0.3)})
	var lift1: Vector3 = SugarGears.LIFTS[0]
	var lift2: Vector3 = SugarGears.LIFTS[1]
	out.append_array([
		{"to": Vector3(0, 0, -58.0), "when": func(p): return _plat_at(p, 0, 1.1).z > -65.0},
		{"to": Vector3(0, 0, -60.5), "jump": "jump", "aim": func(p, s): return _plat_at(p, 0, s)},
		# Ride at the back of each sweet, then run off its front.
		{"to": func(p): return _plat_at(p, 0, 0) + Vector3(0, 0, 0.8),
			"when": func(p): return _plat_at(p, 0, 0.5).z < -69.0 and absf(_plat_at(p, 1, 0.9).x) < 1.4},
		{"to": func(p): return _plat_at(p, 0, 0) + Vector3(0, 0, -0.9), "jump": "jump", "aim": func(p, s): return _plat_at(p, 1, s)},
		{"to": func(p): return _plat_at(p, 1, 0) + Vector3(0, 0, 0.8), "when": func(p): return absf(_plat_at(p, 1, 0.6).x) < 1.0},
		{"to": func(p): return _plat_at(p, 1, 0) + Vector3(0, 0, -0.9), "jump": "jump", "aim": Vector3(0, 0, -78.0)},
		{"to": lift1 + Vector3(0, 0, 2.4), "when": func(p): return _lift_ready(p, lift1),
			"jump": "jump", "aim": lift1 + Vector3.UP},
		{"to": lift1, "when": func(p): return _lift_up(p, lift1), "jump": "jump", "aim": Vector3(0, 4.0, -86.3)},
		{"to": Vector3(0, 4.0, -86.4), "when": func(p): return _lift_ready(p, lift2),
			"jump": "jump", "aim": lift2 + Vector3.UP},
		{"to": lift2, "when": func(p): return _lift_up(p, lift2), "jump": "jump", "aim": Vector3(0, 7.0, -92.4)},
		{"to": SugarGears.CAKE + Vector3(0, 0, -2.0)},
	])
	return out


# --- Moon Ramparts -----------------------------------------------------------

## Hop up the towers, wait between the spinners along the rampart, hop the
## planks, ride the spring up, cross the cannons' deck and long jump to the
## flag tower, all in low gravity.
func _moon_ramparts() -> Array:
	var top := MoonRamparts.RAMPART_TOP
	var deck := MoonRamparts.HIGH_DECK
	var tw: Array = MoonRamparts.TOWERS
	var out := [
		{"to": Vector3(0, 0, -5.4), "jump": "jump", "aim": tw[0]},
		{"to": Vector3(0.4, tw[0].y, -11.9), "jump": "jump", "aim": tw[1]},
		{"to": Vector3(1.9, tw[1].y, -18.0), "jump": "jump", "aim": tw[2]},
		{"to": Vector3(-0.5, top, -23.6), "jump": "jump", "aim": Vector3(0, top, -28.4)},
	]
	var stops := [-28.6, -35.0, -42.0, -49.4]
	for i in stops.size() - 1:
		var a := Vector3(0, top, stops[i])
		var b := Vector3(0, top, stops[i + 1])
		out.append({"to": a, "when": func(p): return _clear_run(p, a, b, 0.3)})
	var from := -49.4
	for z in MoonRamparts.PLANKS:
		out.append({"to": Vector3(0, top, from), "jump": "jump", "aim": Vector3(0, top, z)})
		from = z - 0.6
	var spring: Vector3 = MoonRamparts.SPRING
	out.append_array([
		{"to": Vector3(0, top, from), "jump": "jump", "aim": Vector3(0, top, -74.4)},
		{"to": spring, "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(0, deck, -81.8), "stop": true, "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > deck - 0.3},
		{"to": Vector3(0, deck, -81.8), "when": func(p): return _clear_run(p, Vector3(0, deck, -81.8), Vector3(0, deck, -90.4), 0.3)},
		{"to": Vector3(0, deck, -90.4), "jump": "long", "aim": MoonRamparts.FLAG_TOWER + Vector3(0, 0, 1.5)},
		{"to": MoonRamparts.FLAG_TOWER + Vector3(0, 0, -1.6)},
	])
	return out


# --- Blizzard Bluffs ---------------------------------------------------------

## Hop the floes in the cross wind, jump the spike rows, wait for the saws
## on the icy bridge, ride each updraft up to the next bluff (waiting for
## the penguins on the first), hop the spikes on the last, and let the
## tailwind carry the final jump.
func _blizzard_bluffs() -> Array:
	var bl: Array = BlizzardBluffs.BLUFFS
	var top := func(i: int) -> float: return float(bl[i][2])
	var fin := BlizzardBluffs.FINISH
	return [
		{"to": Vector3(0, 0, -5.4), "jump": "jump", "aim": Vector3(0, 0, -9.6)},
		{"to": Vector3(0, 0, -11.4), "jump": "jump", "aim": Vector3(0, 0, -15.8)},
		{"to": Vector3(0, 0, -17.4), "jump": "jump", "aim": Vector3(0, 0, -21.8)},
		{"to": Vector3(0, 0, -23.4), "jump": "jump", "aim": Vector3(0, 0, -27.0)},
		{"to": Vector3(0, 0, -28.4), "jump": "jump", "aim": Vector3(0, 0, -31.8)},
		{"to": Vector3(0, 0, -32.9), "jump": "jump", "aim": Vector3(0, 0, -36.4)},
		{"to": Vector3(0, 0, -39.2), "when": func(p): return _clear_run(p, Vector3(0, 0, -39.2), Vector3(0, 0, -54.4), 0.35, 0.8)},
		{"to": Vector3(0, 0, -54.4), "jump": "jump", "aim": Vector3(0, top.call(0), -61.0)},
		{"to": Vector3(0, top.call(0), -61.4), "when": func(p): return _clear_run(p, Vector3(0, top.call(0), -61.4), Vector3(0, top.call(0), -66.4), 0.3)},
		{"to": Vector3(0, top.call(0), -66.4), "jump": "jump", "aim": Vector3(0, top.call(1), -72.0)},
		{"to": Vector3(-0.5, top.call(1), -73.0)},
		{"to": Vector3(0, top.call(1), -76.2), "jump": "jump", "aim": Vector3(0, top.call(2), -83.0)},
		{"to": Vector3(0, top.call(2), -86.4), "jump": "jump", "aim": Vector3(0, top.call(3), -92.0)},
		{"to": Vector3(0, top.call(3), -93.4), "jump": "jump", "aim": Vector3(0, top.call(3), -96.8)},
		{"to": Vector3(0, top.call(3), -99.4), "jump": "jump", "aim": fin + Vector3(0, 0, 4.5)},
		{"to": fin + Vector3(0, 0, -0.5)},
	]


# --- Haunted Heights ---------------------------------------------------------

## Wait for the graveyard's ghosts, kick up the first slot, past the ghost on
## the tier, hop the crumbling stones, spring when the ghost has drifted off,
## along the wall walk between ghosts, and kick up the last slot to the flag.
func _haunted_heights() -> Array:
	var s0: Vector3 = HauntedHeights.SLOTS[0]
	var s1: Vector3 = HauntedHeights.SLOTS[1]
	var t0: float = HauntedHeights.SLOT_TOPS[0]
	var t1: float = HauntedHeights.SLOT_TOPS[1]
	var st: Array = HauntedHeights.STONES
	var spring := HauntedHeights.SPRING
	var out := [
		{"to": Vector3(0, 0, -7.0), "when": func(p): return _clear_run(p, Vector3(0, 0, -7.0), Vector3(0, 0, -14.0), 0.5)},
		{"to": Vector3(0, 0, -14.0), "when": func(p): return _clear_run(p, Vector3(0, 0, -14.0), Vector3(0, 0, -21.0), 0.5)},
		{"to": Vector3(s0.x, 0, -23.0)},
		{"to": s0 + Vector3(0, 0, -1.3), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": t0 + 0.3, "off": Vector3.FORWARD,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > t0 - 0.1 and p.hero.global_position.z < s0.z - 2.1},
		{"to": Vector3(0, t0, -29.6), "when": func(p): return _clear_run(p, Vector3(0, t0, -29.6), Vector3(0, t0, -35.4), 0.5)},
		{"to": Vector3(0, t0, -35.4), "jump": "jump", "aim": st[0]},
	]
	for i in range(1, st.size()):
		out.append({"to": st[i - 1] + Vector3(0, 0, -0.5), "jump": "jump", "aim": st[i]})
	var walk := HauntedHeights.WALK
	out.append_array([
		{"to": st[st.size() - 1] + Vector3(0, 0, -0.5), "jump": "jump", "aim": Vector3(0, spring.y, -57.4)},
		{"to": spring + Vector3(0, 0, 1.6), "when": func(p): return _ghost_clear(p, HauntedHeights.SPRING_GHOST, 0.25, 0.8)},
		{"to": spring, "until": func(p): return p.hero.velocity.y > 10.0},
		{"to": Vector3(0, walk, -64.0), "stop": true, "until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > walk - 0.3},
		{"to": Vector3(0, walk, -64.0), "when": func(p): return _clear_run(p, Vector3(0, walk, -64.0), Vector3(0, walk, -69.5), 0.5)},
		{"to": Vector3(0, walk, -69.5), "when": func(p): return _clear_run(p, Vector3(0, walk, -69.5), Vector3(0, walk, -74.5), 0.5)},
		{"to": Vector3(0, walk, -74.5), "when": func(p): return _clear_run(p, Vector3(0, walk, -74.5), Vector3(0, walk, -79.5), 0.5)},
		{"to": Vector3(0, walk, -79.5), "when": func(p): return _clear_run(p, Vector3(0, walk, -79.5), Vector3(0, walk, -84.4), 0.5)},
		{"to": Vector3(s1.x, walk, -85.0)},
		{"to": s1 + Vector3(0, 0, -1.3), "walk": true},
		{"wall": true, "toward": Vector3.RIGHT, "top": t1 + 0.3, "off": Vector3.FORWARD,
			"until": func(p): return p.hero.is_on_floor() and p.hero.global_position.y > t1 - 0.1 and p.hero.global_position.z < s1.z - 2.1},
		{"to": Vector3(0, t1, -97.0)},
	])
	return out


## True if the ghost that started at `start` will stay well away from the
## middle (x = 0) from `from` to `to` seconds from now.
static func _ghost_clear(play: Play, start: Vector3, from: float, to: float) -> bool:
	for n in play.level.find_children("*", "Critter", true, false):
		var cr := n as Critter
		if cr._start.distance_to(start) > 0.5:
			continue
		var t := from
		while t <= to:
			var c := cr._start + cr.travel * _wave(cr._t + t, cr.period)
			if absf(c.x) < 1.6:
				return false
			t += 1.0 / 30.0
		return true
	return true


# --- Bounce Hollow -----------------------------------------------------------

## Where the bee that started at `start` will be in `secs` seconds.
static func _bee_at(play: Play, start: Vector3, secs: float) -> Vector3:
	var best: StarBouncer = null
	for n in play.level.find_children("*", "StarBouncer", true, false):
		var b := n as StarBouncer
		if best == null or b._start.distance_to(start) < best._start.distance_to(start):
			best = b
	return best._start + best.offset_at(best._t + secs)


## An aim for one jump that bounces off each bee in `bees` (their starting
## spots) in turn, then comes down on `last`.
static func _bounce_aim(bees: Array, last: Vector3) -> Callable:
	var st := {"n": 0, "vy": 0.0}
	return func(p: Play, s: float) -> Vector3:
		var vy := p.hero.velocity.y
		if vy > 11.5 and st.vy < 6.0:
			st.n += 1
		st.vy = vy
		if st.n < bees.size():
			return _bee_at(p, bees[st.n], s) + Vector3(0, 0.75, 0)
		return last


## Jump onto each bee as it comes into line and bounce over every gap,
## wait for the zombies, the ghost and the spikes, bounce up the stair of
## bees, and hop the planks to the last big bounce.
func _bounce_hollow() -> Array:
	var bees: Array = []
	for b in BounceHollow.BEES:
		bees.append(b[0])
	var high := BounceHollow.HIGH
	var out: Array = [
		{"to": Vector3(0, 0, -2.6), "when": func(p): return absf(_bee_at(p, bees[0], 1.1).x) < 0.5},
		{"to": Vector3(0, 0, -5.6), "jump": "jump", "aim": _bounce_aim([bees[0]], Vector3(0, 0, -17.2))},
		{"to": Vector3(0, 0, -17.6), "jump": "jump", "aim": Vector3(0, 0, -20.6)},
		{"to": Vector3(0, 0, -22.6), "when": func(p): return absf(_bee_at(p, bees[1], 1.1).x) < 0.5},
		{"to": Vector3(0, 0, -25.6), "jump": "jump", "aim": _bounce_aim([bees[1]], Vector3(0, 0, -37.4))},
		{"to": Vector3(0, 0, -37.8), "when": func(p): return _clear_run(p, Vector3(0, 0, -37.8), Vector3(0, 0, -47.2), 0.4)},
		{"to": Vector3(0, 0, -47.2), "jump": "jump", "aim": _bounce_aim([bees[2], bees[3]], Vector3(0, high, -57.6))},
		{"to": Vector3(0, high, -57.8), "when": func(p): return _clear_run(p, Vector3(0, high, -57.8), Vector3(0, high, -63.4), 0.5)},
		{"to": Vector3(0, high, -62.6), "when": func(p): return absf(_bee_at(p, bees[4], 0.9).x) < 0.8},
		{"to": Vector3(0, high, -63.6), "jump": "jump", "aim": _bounce_aim([bees[4], bees[5]], Vector3(0, high, -78.0))},
		{"to": Vector3(0, high, -78.4), "when": func(p): return _clear_run(p, Vector3(0, high, -78.4), Vector3(0, high, -89.6), 0.4)},
	]
	var from := -89.6
	for z in BounceHollow.PLANKS:
		out.append({"to": Vector3(0, high, from), "jump": "jump", "aim": Vector3(0, high, z)})
		from = z - 0.6
	out.append({"to": Vector3(0, high, from), "jump": "jump", "aim": _bounce_aim([bees[6]], Vector3(0, BounceHollow.PATCH, -114.6))})
	out.append({"to": Vector3(0, BounceHollow.PATCH, -118.4)})
	return out


# --- Starlight Finale --------------------------------------------------------

## Ride the sliding platforms, wait for the saws on the ice and a gap in the
## cannon fire, hop the rotten planks, slip past the ghost, ride the donut
## over the soda, take the crusher lift, double jump up the towers, ride the
## updraft and bounce off the last bee to the flag.
func _starlight_finale() -> Array:
	var lift := StarlightFinale.LIFT
	var tw: Array = StarlightFinale.TOWERS
	var st := StarlightFinale.STATION
	var top := StarlightFinale.SUMMIT
	var land := StarlightFinale.LANDING
	var fin := StarlightFinale.FINISH
	var out := [
		{"to": Vector3(0, 0, -2.6), "when": func(p): return absf(_plat_at(p, 0, 0.7).x) < 1.0},
		{"to": Vector3(0, 0, -3.6), "jump": "jump", "aim": func(p, s): return _plat_at(p, 0, s)},
		{"to": func(p): return Vector3(_plat_at(p, 0, 0).x, 0, -9.4), "jump": "jump", "aim": func(p, s): return _plat_at(p, 1, s)},
		{"to": func(p): return Vector3(_plat_at(p, 1, 0).x, 0, -13.9), "jump": "jump", "aim": Vector3(0, 0, -17.8)},
		{"to": Vector3(0, 0, -18.2), "when": func(p): return _clear_run(p, Vector3(0, 0, -18.2), Vector3(0, 0, -37.4), 0.35, 3.8)},
		{"to": Vector3(0, 0, -42.4), "when": func(p): return _clear_run(p, Vector3(0, 0, -42.4), Vector3(0, 0, -55.4), 0.3)},
	]
	var from := -55.4
	for z in StarlightFinale.PLANKS:
		out.append({"to": Vector3(0, 0, from), "jump": "jump", "aim": Vector3(0, 0, z)})
		from = z - 0.6
	out.append_array([
		{"to": Vector3(0, 0, from), "jump": "jump", "aim": Vector3(0, 0, -74.4)},
		{"to": Vector3(0, 0, -74.8), "when": func(p): return _clear_run(p, Vector3(0, 0, -74.8), Vector3(0, 0, -83.4), 0.5)},
		# Ride at the back of the donut, then run off its front.
		{"to": Vector3(0, 0, -81.0), "when": func(p): return _plat_at(p, 2, 1.1).z > -88.0},
		{"to": Vector3(0, 0, -83.5), "jump": "jump", "aim": func(p, s): return _plat_at(p, 2, s)},
		{"to": func(p): return _plat_at(p, 2, 0) + Vector3(0, 0, 0.8), "when": func(p): return _plat_at(p, 2, 0.5).z < -92.0},
		{"to": func(p): return _plat_at(p, 2, 0) + Vector3(0, 0, -0.9), "jump": "jump", "aim": Vector3(0, 0, -97.0)},
		{"to": lift + Vector3(0, 0, 2.4), "when": func(p): return _lift_ready(p, lift),
			"jump": "jump", "aim": lift + Vector3.UP},
		{"to": lift, "when": func(p): return _lift_up(p, lift), "jump": "jump", "aim": Vector3(0, 4.0, -107.3)},
		{"to": Vector3(0, 4.0, -110.4), "jump": "double", "aim": tw[0]},
		{"to": tw[0] + Vector3(-0.3, 0, -0.9), "jump": "double", "aim": tw[1]},
		{"to": tw[1] + Vector3(0.3, 0, -0.9), "jump": "jump", "aim": Vector3(0, st, -125.0)},
		{"to": Vector3(0, st, -130.4), "jump": "jump", "aim": Vector3(0, top, -136.0)},
		{"to": Vector3(0, top, -141.6), "jump": "jump", "aim": _bounce_aim([StarlightFinale.BEE], Vector3(0, land, -151.6))},
		{"to": fin + Vector3(0, 0, 0.6)},
	])
	return out
