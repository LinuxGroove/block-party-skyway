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


func run() -> void:
	pass


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
