class_name KitchenDash
extends Level
## Course 3 of Snack Valley: a dash across a giant kitchen. A belt carries
## you up the counter while fruit rolls across it; then a belt runs against
## you under two pots that slam down in turn. The course turns east over
## sideways belts that push you towards the edge, past a spinning skewer and
## up a stack of pancakes to the flag on a plate.
##
## Adventure: coins, hearts, a hidden gem on a ledge west of the turn (with
## a pudding back up) and checkpoints. Speedrun: just the course and the
## clock.

const STAR := "snack/kitchen_dash"
const GEM := "snack/gem_kitchen_dash"

## The two pots over the backward belt, nearest the start first.
var presses: Array[SnackPress] = []
var skewer: SnackSkewer


func _init() -> void:
	super()
	title = "Kitchen Dash"
	spawn = Vector3(0, 0, 1.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 28.0, 10.0, false]


func build() -> void:
	# The start, on the counter.
	land(-4, -2, 4, 4, 0, 3, "snow")
	add_sign("Belts carry you along. Jump the rolling fruit!", Vector3(-3, 0, 2.5))
	SnackFood.prop(self, "food:knife-block", Vector3(3, 0, 3), 4.0, -20.0)

	# A belt up the counter, with fruit rolling across it.
	land(-4, -22, -1, -2, 0, 3, "snow")
	land(1, -22, 4, -2, 0, 3, "snow")
	add(Conveyor.make(20, Vector3.FORWARD, 3.0), Vector3(0, -0.35, -2))
	add(SnackRoller.make("food:watermelon", Vector3(8.8, 0, 0), 5.0, 1.3), Vector3(-4.4, 0, -7))
	add(SnackRoller.make("food:orange", Vector3(-8.8, 0, 0), 5.5, 1.0, 0.4), Vector3(4.4, 0, -13))
	add(SnackRoller.make("food:apple", Vector3(8.8, 0, 0), 5.0, 1.1, 0.7), Vector3(-4.4, 0, -19))
	for z in [-4.5, -10.0, -16.0]:
		add_coin(Vector3(0, 0.9, z))
	SnackFood.prop(self, "food:bottle-ketchup", Vector3(-3.2, 0, -10), 5.0)
	SnackFood.prop(self, "food:bottle-musterd", Vector3(3.2, 0, -16), 5.0)

	# A rest on a chopping board.
	land(-3, -24, 3, -22, 0, 3, "snow")
	add_checkpoint(Vector3(0, 0, -23.0), Vector3.FORWARD)
	add_sign("The pots slam down. Wait for one to lift, then run under it.", Vector3(-2.4, 0, -22.6))
	add_heart(Vector3(2.2, 0, -23))

	# A belt running against you, under two pots that slam in turn.
	add(Conveyor.make(14, Vector3.BACK, 2.5), Vector3(-1, -0.35, -38))
	add(Conveyor.make(14, Vector3.BACK, 2.5), Vector3(1, -0.35, -38))
	presses.append(add(SnackPress.pot(2.4, 0.0, "food:pot", 5.6), Vector3(0, 0, -28.5)) as SnackPress)
	presses.append(add(SnackPress.pot(2.4, 0.72, "food:pot", 5.6), Vector3(0, 0, -33.5)) as SnackPress)
	add_coin(Vector3(0, 0.9, -26))
	add_coin(Vector3(0, 0.9, -31))
	add_coin(Vector3(0, 0.9, -36))

	# A big chopping board, where the course turns east.
	land(-4, -46, 4, -38, 0, 3, "snow")
	add_checkpoint(Vector3(0, 0, -39.6), Vector3.RIGHT)
	add_sign("These belts push sideways. Keep away from the edge!", Vector3(-2.6, 0, -44.8), Vector3.RIGHT)
	camera_zone(Vector3(-4.5, -3, -48), Vector3(50, 12, -37.5), -90.0, 28.0, 10.0)
	if not is_speedrun():
		# Off the racing line: a ledge west of the board, with a pudding back up.
		land(-11, -45, -7, -40, -1.5, 2, "snow")
		add_gem(GEM, Vector3(-9.8, -1.3, -43.6))
		add_heart(Vector3(-9.8, -1.5, -41.2))
		add(SnackPudding.make(), Vector3(-7.8, -1.5, -42.5))
		SnackFood.prop(self, "food:cup-saucer", Vector3(-10, -1.5, -42.5), 7.0)

	# Sideways belts, all pushing south, off the edge.
	for i in 8:
		add(Conveyor.make(4, Vector3.BACK, 2.2), Vector3(5 + i * 2, -0.35, -44))
	coin_line(Vector3(6, 0.9, -42.6), Vector3(18, 0.9, -42.6), 4)
	var bee := Critter.make("animal-bee", Vector3(10, 0, 0), 3.5)
	bee.bob = 0.2
	add(bee, Vector3(6, 0.3, -43.4))

	# A board with a spinning skewer, then pancakes up to the plate.
	land(20, -46, 28, -38, 0, 3, "snow")
	add_checkpoint(Vector3(20.8, 0, -41.2), Vector3.RIGHT)
	skewer = add(SnackSkewer.make(3.6, -50.0, "food:skewer-vegetables", 2), Vector3(24.5, 0, -44.4)) as SnackSkewer
	for i in 3:
		for k in i + 1:
			SnackFood.solid(self, "food:pancakes", Vector3(29.9 + i * 4.2, k * 0.96, -42), 8.0, 15.0 * k)
		add_coin(Vector3(29.9 + i * 4.2, (i + 1) * 0.96 + 0.6, -42))
	land(40, -46, 48, -38, 3.0, 4)
	SnackFood.prop(self, "food:plate", Vector3(44, 2.6, -42), 9.0)
	add_flag(Vector3(45, 3.0, -42), Vector3.RIGHT)
	_scenery()
	finish()


func _scenery() -> void:
	# Kitchen things far below and around.
	SnackFood.prop(self, "food:pot-stew", Vector3(-12, -10, -14), 14.0, 30.0)
	SnackFood.prop(self, "food:frying-pan", Vector3(14, -9, -18), 14.0, -40.0)
	SnackFood.prop(self, "food:cutting-board", Vector3(12, -12, -56), 18.0, 70.0)
	SnackFood.prop(self, "food:whisk", Vector3(-14, -6, -34), 12.0, 50.0)
	SnackFood.prop(self, "food:rollingPin", Vector3(32, -8, -30), 14.0, 10.0)
	SnackFood.prop(self, "food:steamer", Vector3(54, -6, -50), 14.0)
	for at in [Vector3(-8, 0, -28), Vector3(8, 0, -30)]:
		SnackFood.prop(self, "food:shaker-salt" if at.x < 0 else "food:shaker-pepper", at + Vector3(0, -10, 0), 30.0)


func shots() -> Array:
	return [{"name": "belts", "at": Vector3(1.0, 0, -40.5), "face": Vector3.RIGHT}]
