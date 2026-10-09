class_name DonutHop
extends Level
## Course 2 of Snack Valley: donuts floating in the sky. Hop a zig-zag of
## still donuts, cross two gliding ones, rest on a slab of frosting, then
## turn east over old donuts that crumble under you, bounce off a pudding up
## to a giant donut, and hop down bobbing donuts to the flag.
##
## Adventure: coins, hearts, a hidden gem on a ledge below the turn (with a
## pudding back up) and checkpoints. Speedrun: just the course and the
## clock.

const STAR := "snack/donut_hop"
const GEM := "snack/gem_donut_hop"

## The two gliding donuts, nearest the start first.
var gliders: Array[SnackRaft] = []


func _init() -> void:
	super()
	title = "Donut Hop"
	spawn = Vector3(0, 0, 1.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 10.0, false]


func build() -> void:
	# The start.
	land(-3, -2, 3, 4, 0, 3, "snow")
	add_sign("Hop from donut to donut. Some glide, some crumble: keep moving!", Vector3(-2, 0, 2.5))
	deco("arrows", Vector3(0, 0, -1.2), 0.0, 2.0)

	# A zig-zag of still donuts, each a little higher.
	add(SnackRaft.make("food:donut-sprinkles", 12.0), Vector3(-1.2, 0, -5.2))
	add(SnackRaft.make("food:donut-chocolate", 12.0), Vector3(1.2, 0.5, -9.0))
	add(SnackRaft.make("food:donut", 12.0), Vector3(-1.0, 1.0, -12.8))
	add_coin(Vector3(-1.2, 0.6, -5.2))
	add_coin(Vector3(1.2, 1.1, -9.0))
	add_coin(Vector3(-1.0, 1.6, -12.8))

	# Two donuts gliding past each other.
	gliders.append(add(SnackRaft.glide("food:donut-sprinkles", 12.0, Vector3(6, 0, 0), 3.4), Vector3(-3, 1.0, -17)) as SnackRaft)
	gliders.append(add(SnackRaft.glide("food:donut-chocolate", 12.0, Vector3(-6, 0, 0), 3.4), Vector3(3, 1.0, -21.2)) as SnackRaft)

	# A slab of frosting to rest on; the course turns east here.
	land(-3, -29, 3, -24.5, 1.0, 3)
	add_checkpoint(Vector3(0.2, 1.0, -26.9), Vector3.RIGHT)
	add_heart(Vector3(-2.2, 1.0, -28.2))
	add_sign("Old donuts crumble when you land on them.", Vector3(2.2, 1.0, -28.6), Vector3.LEFT)
	camera_zone(Vector3(-3.5, -6, -36), Vector3(50, 18, -24.2), -90.0, 30.0, 10.5)
	if not is_speedrun():
		# Off the racing line: a ledge below the turn, with a pudding back up.
		land(5, -23, 8, -20, -1.0, 2, "snow")
		add_gem(GEM, Vector3(7.2, -0.8, -20.8))
		add_heart(Vector3(7.2, -1.0, -22.2))
		add(SnackPudding.make(), Vector3(5.8, -1.0, -21.5))

	# Old donuts that crumble.
	for i in 4:
		var d := SnackRaft.make(["food:donut", "food:donut-chocolate", "food:donut-sprinkles", "food:donut"][i], 12.0)
		d.falls = true
		d.delay = 0.5
		add(d, Vector3(6.2 + i * 3.6, 1.0 + i * 0.5, -27))
		add_coin(Vector3(6.2 + i * 3.6, 1.6 + i * 0.5, -27))

	# A pudding up to the giant donut.
	land(19, -29, 23, -25, 3.0, 2, "snow")
	add_checkpoint(Vector3(19.8, 3.0, -28.2), Vector3.RIGHT)
	add(SnackPudding.make(), Vector3(21.2, 3.0, -27))
	add(SnackRaft.make("food:donut-sprinkles", 16.0), Vector3(25.5, 6.5, -27))
	coin_line(Vector3(22.2, 5.5, -27), Vector3(24.5, 7.2, -27), 3)

	# Bobbing donuts down to the flag.
	for i in 3:
		var at := Vector3(29.8 + i * 3.6, 5.6 - i * 0.8, -27)
		add(SnackRaft.make(["food:donut", "food:donut-chocolate", "food:donut-sprinkles"][i], 12.0, 0.25), at)
		add_coin(at + Vector3(0, 0.7, 0))
	land(39, -31, 47, -23, 3.0, 3)
	add_flag(Vector3(43, 3.0, -27), Vector3.RIGHT)
	for z in [-30.2, -23.8]:
		SnackFood.stick(self, "food:lollypop", Vector3(45.5, 3.0, z), 5.0, z * 20.0)
	_scenery()
	finish()


func _scenery() -> void:
	# Big donuts drifting far below, and a cake on the horizon.
	for at in [Vector3(-9, -9, -10), Vector3(10, -11, -6), Vector3(-6, -12, -32), Vector3(24, -10, -15), Vector3(30, -12, -40)]:
		SnackFood.prop(self, ["food:donut-sprinkles", "food:donut", "food:donut-chocolate"][int(absf(at.x)) % 3], at, 22.0, at.z * 9.0)
	SnackFood.prop(self, "food:cake-birthday", Vector3(52, -16, -46), 30.0, 20.0)
	SnackFood.prop(self, "food:cupcake", Vector3(-14, -6, -20), 8.0, 10.0)


func shots() -> Array:
	return [{"name": "crumble", "at": Vector3(1.0, 1.0, -27.0), "face": Vector3.RIGHT}]
