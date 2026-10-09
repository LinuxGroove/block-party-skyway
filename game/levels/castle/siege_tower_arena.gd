class_name CastleSiegeArena
extends BossArena
## Sky Castle's boss arena: the top of the castle's north wall, with King
## Thud's Siege Tower rolling along the road below it. The battlements have
## three gaps; the tower stops at one to reload and drops its gangway across
## to the wall, and that's when to run over and ground pound its deck. Its
## stones land in red rings on the wall walk while it rolls. Falling off the
## wall brings you back to the flag.

const P := preload("res://game/levels/castle/castle_parts.gd")

## Where the tower stops (x), the wall's north edge, and the road below.
const STOPS := [-6.0, 0.0, 6.0]
const EDGE_Z := -4.0
const TOWER_Z := -7.9
const ROAD_Y := CastleSiegeTower.DECK_Y - CastleSiegeTower.LIFT
## Below this, the hero has gone over the edge.
const FALL_Y := -3.0
## How wide the gaps in the battlements are.
const GAP := 3.8

var tower: CastleSiegeTower


func _init() -> void:
	super()
	title = "The Siege Tower"
	spawn = Vector3(0, 0, 5.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 36.0, 12.5, true]
	star_spot = Vector3(0, 1.2, 2.5)


func build() -> void:
	# The wall walk: stone along the battlements, grass behind.
	land(-10, -4, 10, -1, 0, 6, "snow")
	land(-10, -1, 10, 9, 0, 6)
	_battlements()
	add_checkpoint(Vector3(-2.5, 0, 7.2), Vector3.FORWARD)
	add_sign("The Siege Tower! Wait at a gap for its gangway.", Vector3(2.6, 0, 7.4))
	for at in [Vector3(-8.5, 0, 6.5), Vector3(8.5, 0, 6.5), Vector3(0, 0, -1.6)]:
		add_heart(at)
	# Towers at the corners of the wall, and banners.
	for x in [-11.0, 11.0]:
		P.tower(self, Vector3(x, -6, -2.5), 2.6, 4, "roof")
		P.banner(self, Vector3(x, 3.6, -1.15), Vector3.BACK, true, 1.8)
	for at in [Vector3(-9, 0, 8.2), Vector3(9, 0, 8.2)]:
		P.tree(self, at, false, 1.6)
	deco("flowers", Vector3(-5.5, 0, 7.6), 0.0, 1.2)
	deco("flowers", Vector3(6, 0, 7.4), 40.0, 1.2)
	# The road below the wall, and Thud's camp beyond it.
	land(-20, -12, 20, -4, ROAD_Y, 3, "snow")
	land(-20, -26, 20, -12, ROAD_Y, 3)
	for c in [["trebuchet", Vector3(-9, ROAD_Y, -17), Vector3.BACK], ["catapult", Vector3(4, ROAD_Y, -16), Vector3.BACK],
			["ram", Vector3(12, ROAD_Y, -19), Vector3.LEFT], ["tower", Vector3(-15, ROAD_Y, -21), Vector3.BACK],
			["ballista", Vector3(-2, ROAD_Y, -21), Vector3.BACK]]:
		P.siege(self, c[0], c[1], c[2], 1.8)
	for at in [Vector3(-17, ROAD_Y, -14), Vector3(8, ROAD_Y, -23), Vector3(17, ROAD_Y, -15)]:
		P.tree(self, at, true, 2.0)
	P.rocks(self, Vector3(-5, ROAD_Y, -14), true, 2.0)
	P.pennant(self, Vector3(1, ROAD_Y, -24), 0.0, 2.5)
	P.pennant(self, Vector3(-12, ROAD_Y, -24), 0.0, 2.5)
	P.cloud_sea(self, Vector3(0, 0, -6), 16.0, 80.0, -18.0, -10.0, 60, 71)
	tower = CastleSiegeTower.new()
	tower.stops = STOPS
	tower.wall_z = EDGE_Z
	add_boss(tower, Vector3(-8.5, ROAD_Y, TOWER_Z))
	finish()


## A stone parapet along the wall's north edge, with merlons, and a gap
## wherever the tower stops.
func _battlements() -> void:
	var x := -10.0
	while x < 10.0:
		var next := x + 1.0
		var in_gap := false
		for s in STOPS:
			if absf(x + 0.5 - float(s)) < GAP / 2.0:
				in_gap = true
		if not in_gap:
			piece("block-snow-low", Vector3(x + 0.5, 0, EDGE_Z + 0.5))
			solid(Vector3(x, 0, EDGE_Z), Vector3(next, 0.5, EDGE_Z + 1.0))
			if int(x) % 2 == 0:
				piece("block-snow", Vector3(x + 0.5, 0.5, EDGE_Z + 0.5))
				solid(Vector3(x, 0.5, EDGE_Z), Vector3(next, 1.5, EDGE_Z + 1.0))
		x = next


func _physics_process(_delta: float) -> void:
	# Over the edge (onto the road, or into the clouds): back to the flag.
	if hero and hero.global_position.y < global_position.y + FALL_Y:
		fall_off()
