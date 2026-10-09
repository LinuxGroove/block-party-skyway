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
## the ice starts (it's slow to speed up on).
static func _clear_run(play: Play, from: Vector3, to: Vector3, margin := 0.3, ice_from := INF) -> bool:
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
		d += v * dt
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
