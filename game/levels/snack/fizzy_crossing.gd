class_name FizzyCrossing
extends Level
## Course 4 of Snack Valley: across a lake of orange soda. Hop bobbing
## donuts and cookies that sink while you stand on them to an island, step
## into a fizzy geyser that lifts you up to a cream cloud, cross it over
## wafers that drop, then come down onto giant soda cans standing in the
## lake and hop them to the flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge east of the island
## (with a pudding back up) and checkpoints. Speedrun: just the course and
## the clock.

const STAR := "snack/fizzy_crossing"
const GEM := "snack/gem_fizzy_crossing"

## The geyser up to the cream cloud.
var geyser: WindZone


func _init() -> void:
	super()
	title = "Fizzy Crossing"
	spawn = Vector3(0, 0.5, 3.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 28.0, 10.0, false]


func build() -> void:
	# The soda lake, the whole way.
	land(-16, -92, 16, 10, -3.0, 1, "snow")
	SnackSoda.lake(self, -16, -92, 16, 10, -0.5)

	# The start, on a dock of frosting.
	land(-3, 0, 3, 6, 0.5, 3, "snow")
	add_sign("Soda is too fizzy to swim in! Hop the donuts, and don't stand about on cookies: they sink.", Vector3(-2, 0.5, 5))

	# Bobbing donuts, then cookies that sink.
	for at in [Vector3(-1.2, 0.3, -3.2), Vector3(1.2, 0.3, -7.0), Vector3(-1.0, 0.3, -10.8)]:
		add(SnackRaft.make(["food:donut-sprinkles", "food:donut", "food:donut-chocolate"][int(-at.z) % 3], 12.0, 0.12), at)
		add_coin(at + Vector3(0, 0.6, 0))
	for at in [Vector3(0.8, 0.3, -14.6), Vector3(-0.8, 0.3, -18.2), Vector3(0.6, 0.3, -21.8)]:
		var cookie := SnackRaft.make("food:cookie", 14.0)
		cookie.sinks = 0.5
		cookie.sink_depth = 1.6
		add(cookie, at)
		add_coin(at + Vector3(0, 0.6, 0))

	# An island, and the geyser up to the cloud.
	land(-4, -31, 4, -25, 0.5, 3, "snow")
	add_checkpoint(Vector3(0, 0.5, -26.2), Vector3.FORWARD)
	add_sign("Step into the fizz and stay in it: it lifts you up!", Vector3(-3, 0.5, -29.6), Vector3.RIGHT)
	add_heart(Vector3(-2.6, 0.5, -26.4))
	SnackFood.solid(self, "food:soda-can", Vector3(3, 0.5, -26.2), 3.0)
	geyser = add(WindZone.make(Vector3(3.0, 8.5, 3.0), Vector3.UP * 52.0), Vector3(0, -0.5, -33.2)) as WindZone
	_fizz_column(Vector3(0, -0.5, -33.2), 8.5, 1.4)
	coin_line(Vector3(0, 2.0, -33.2), Vector3(0, 6.5, -33.2), 4)
	if not is_speedrun():
		# Off the racing line: a ledge east of the island, with a pudding back up.
		land(7, -30, 10, -26, -0.2, 2, "snow")
		add_gem(GEM, Vector3(9.0, 0.0, -28.8))
		add(SnackPudding.make(), Vector3(7.8, -0.2, -27.0))
		SnackFood.prop(self, "food:soda-can-crushed", Vector3(9.2, -0.2, -26.8), 4.0, 30.0)

	# The cream cloud, with wafers that drop.
	ledge(-3, -44, 3, -35, 7.0, "snow")
	add_checkpoint(Vector3(0, 7.0, -36.4), Vector3.FORWARD)
	add_heart(Vector3(2.2, 7.0, -42))
	SnackFood.prop(self, "food:whipped-cream", Vector3(-2.2, 7.0, -39), 9.0, 20.0)
	for z in [-46.8, -50.8]:
		add(SnackRaft.wafer("food:waffle", 9.0), Vector3(0, 7.0, z))
		add_coin(Vector3(0, 7.6, z))
	ledge(-3, -60, 3, -53, 7.0, "snow")
	add_sign("Drop down onto the cans!", Vector3(-2.2, 7.0, -54), Vector3.BACK)

	# Giant soda cans standing in the lake, out to the flag.
	for at in [Vector3(0, -3.0, -63.5), Vector3(2.2, -3.0, -67.3), Vector3(-0.4, -3.0, -71.1), Vector3(1.6, -3.0, -74.9)]:
		var top := SnackFood.solid(self, "food:soda-can", at, 12.0, at.z * 17.0)
		add_coin(Vector3(at.x, top + 0.6, at.z))
	land(-4, -86, 4, -78, 1.2, 4, "snow")
	add_flag(Vector3(0, 1.2, -83))
	SnackFood.stick(self, "food:soda-bottle", Vector3(-3, 1.2, -85), 6.0, 0.0, 1.0)
	SnackFood.stick(self, "food:soda-bottle", Vector3(3, 1.2, -85), 6.0, 0.0, 1.0)
	_scenery()
	finish()


## A see-through column of fizz over a geyser.
func _fizz_column(at: Vector3, height: float, radius: float) -> void:
	var m := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * 0.8
	cyl.bottom_radius = radius
	cyl.height = height
	m.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.75, 0.4, 0.28)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material_override = mat
	m.position = at + Vector3.UP * height / 2.0
	add_child(m)


func _scenery() -> void:
	# Things floating and standing in the soda, away from the course.
	SnackFood.prop(self, "food:soda-glass", Vector3(-11, -3.0, -20), 16.0, 20.0)
	SnackFood.prop(self, "food:soda-bottle", Vector3(11, -3.0, -48), 18.0)
	SnackFood.prop(self, "food:soda-can", Vector3(-10, -3.0, -66), 14.0, 50.0)
	SnackFood.prop(self, "food:cookie-chocolate", Vector3(9, -0.6, -10), 18.0, 40.0)
	SnackFood.prop(self, "food:donut-sprinkles", Vector3(-9, -0.6, -40), 14.0, 10.0)
	SnackFood.prop(self, "food:lemon-half", Vector3(10, -0.8, -80), 12.0)
	SnackFood.prop(self, "food:cupcake", Vector3(-11, -3.0, -86), 14.0)


func shots() -> Array:
	return [{"name": "cloud", "at": Vector3(0, 7.0, -37), "face": Vector3.FORWARD}]
