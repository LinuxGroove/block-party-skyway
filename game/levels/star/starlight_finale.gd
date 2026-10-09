class_name StarlightFinale
extends StarCourse
## Star Road course 8, the last and longest: a run through a bit of every
## world on the Skyway, climbing all the way. Sliding platforms from Sunny
## Isles, saws on Frosty Peaks' ice, Pirate Cove's cannons across a pier,
## Spooky Hollow's rotten planks and a ghost, a donut over Snack Valley's
## soda, a Gear Works crusher lift, Sky Castle's towers, a Star Station deck
## with an updraft, and one last bee to bounce up to the flag.

const STAR := "star/starlight_finale"
const GEM := "star/gem_starlight_finale"
## The two platforms sliding across the first gap.
const SLIDERS := [-8.5, -13.0]
const SAWS := [-27.0, -33.0]
## The pier's cannon lanes, and which side each cannon fires from.
const CANNON_LANES := [[-47.0, 1.0], [-50.5, -1.0], [-54.0, 1.0]]
const PLANKS := [-59.5, -63.0, -66.5, -70.0]
const GHOST := Vector3(-3.0, 0, -78.5)
## Where the donut starts, and how far it floats.
const DONUT := Vector3(0, 0, -86.5)
const DONUT_TRAVEL := Vector3(0, 0, -6)
const LIFT := Vector3(0, 0, -104.5)
## The castle towers' tops.
const TOWERS := [Vector3(1.5, 6.0, -115.5), Vector3(-1.5, 8.0, -120.5)]
const STATION := 8.0
const SUMMIT := 14.0
const BEE := Vector3(0, 13.3, -145.5)
const LANDING := 17.0
const FINISH := Vector3(0, 18.5, -167.0)
const UPDRAFT := 48.0
const GRAPE := Color(0.62, 0.3, 0.85, 0.78)


func _init() -> void:
	super()
	title = "Starlight Finale"
	cloud_center = Vector3(0, 0, -85)
	cloud_spread = 100.0


## Extra views for the screenshots.
func shots() -> Array:
	return [{"name": "summit", "at": Vector3(0, SUMMIT, -140.5)}]


func build() -> void:
	start_pad(-3, -6, 3, 4, "The last road: a bit of every world, one after another. Good luck!")
	_sunny()
	_frosty()
	_pirate()
	_spooky()
	_snack()
	_gears()
	_castle()
	_station()
	_finale()
	finish()


## Sunny Isles: platforms sliding across the first gap.
func _sunny() -> void:
	tree(Vector3(-2.4, 0, -4.8), "tree")
	deco("flowers", Vector3(2.2, 0, -4.6), 30.0, 1.2)
	deco("mushrooms", Vector3(2.3, 0, 3.0), 0.0, 1.2)
	for z in SLIDERS:
		add(MovingPlatform.make(Vector3(4, 0, 0), 3.6, 0.0, Vector3(2, 0.4, 3)), Vector3(-2, 0, z))
		add_coin(Vector3(0, 1.1, z))


## Frosty Peaks: saws sliding across an icy bridge.
func _frosty() -> void:
	land(-3, -22, 3, -16, 0, 3, "snow")
	add_checkpoint(Vector3(-2.2, 0, -17.2), Vector3.FORWARD)
	tree(Vector3(2.4, 0, -21.0), "tree-pine-snow")
	deco("holiday:snowman", Vector3(-2.4, 0, -21.2), 160.0, 1.0)
	land(-2, -38, 2, -22, -1, 2, "snow")
	ice(-2, -38, 2, -22, 0)
	for k in SAWS.size():
		var dir := 1.0 if k == 0 else -1.0
		add(Saw.make(Vector3(3.2 * dir, 0, 0), 1.7, 0.4 * k), Vector3(-1.6 * dir, 0, SAWS[k]))
	for z in [-24.5, -30.0, -36.0]:
		add_coin(Vector3(0, 0.5, z))


## Pirate Cove: a dock and a narrow pier, with cannons firing across it.
func _pirate() -> void:
	deck(-3, -44, 3, -38, 0)
	add_checkpoint(Vector3(-2.2, 0, -38.8), Vector3.FORWARD)
	add_heart(Vector3(2.2, 0, -38.8))
	deco("pirate:barrel", Vector3(-2.4, 0, -43.2), 0.0, 0.5)
	deco("pirate:barrel", Vector3(2.4, 0, -43.4), 40.0, 0.45)
	deck(-1, -56, 1, -44, 0)
	for i in CANNON_LANES.size():
		var z: float = CANNON_LANES[i][0]
		var side: float = CANNON_LANES[i][1]
		var post := Vector3(5.0 * side, 0, z)
		deck(int(post.x) - 1, int(z) - 1, int(post.x) + 1, int(z) + 1, 0)
		var cannon := Launcher.make("pirate:cannon", Vector3(-side, 0, 0), 2.0, 0.33 * i)
		# Its balls drop out past the pier.
		cannon.shot_life = 1.6
		add(cannon, post)
		add_coin(Vector3(0, 0.5, z + 1.7))
	deco("pirate:flag-pirate", Vector3(5.4, 0, -46.4), 90.0, 0.7)
	deco("pirate:ship-ghost", Vector3(-15.0, -5.0, -56.0), 20.0, 1.0)


## Spooky Hollow: rotten planks, then a graveyard with a ghost drifting
## across it.
func _spooky() -> void:
	for z in PLANKS:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), Vector3(0, 0, z))
		add_coin(Vector3(0, 1.6, z + 1.7))
	land(-4, -84, 4, -73, 0, 3)
	add_checkpoint(Vector3(-3.2, 0, -73.8), Vector3.FORWARD)
	var ghost := Critter.make("grave:character-ghost", Vector3(6, 0, 0), 2.8, 0.0, 1.0)
	ghost.spiky = true
	ghost.bob = 0.25
	add(ghost, GHOST)
	for p in [Vector3(-3.3, 0, -76.0), Vector3(3.2, 0, -82.6)]:
		deco("grave:gravestone-round", p, 0.0, 1.4)
	deco("grave:pumpkin-carved", Vector3(3.3, 0, -75.6), 200.0, 1.6)
	for x in [-3.4, 3.4]:
		deco("grave:lightpost-single", Vector3(x, 0, -83.4), 0.0, 1.4)


## Snack Valley: a donut floating out over a lake of grape soda.
func _snack() -> void:
	land(-9, -96, 9, -84, -2.0, 2)
	water(-9, -96, 9, -84, -0.9, GRAPE)
	add(StarFloat.make_float("food:donut-sprinkles", 5.0, 0.2, DONUT_TRAVEL, 5.0), DONUT)
	add_coin(DONUT + Vector3(0, 1.2, -3.0))
	deco("food:soda-bottle", Vector3(-6.0, -2.0, -88.0), 30.0, 8.0)
	deco("food:soda-can", Vector3(7.6, -2.0, -91.0), 0.0, 9.0)
	deco("food:popsicle", Vector3(-7.8, -2.0, -92.5), 60.0, 7.0)
	deco("food:cupcake", Vector3(6.4, -2.0, -86.0), 20.0, 8.0)


## Gear Works: a crusher that lifts you up to a ledge.
func _gears() -> void:
	land(-3, -106, 3, -95, 0, 3)
	add_checkpoint(Vector3(-2.2, 0, -96.0), Vector3.FORWARD)
	add_heart(Vector3(2.2, 0, -96.0))
	land(-3, -111, 3, -106, 4.0, 5)
	# Timed to be down as a quick run arrives.
	var lift := Crusher.make(3.0, Vector3(2, 1, 2), 0.79, "block-moving-large")
	lift.down_time = 1.2
	lift.rise_time = 1.5
	lift.up_time = 1.2
	lift.fall_time = 0.4
	add(lift, LIFT)
	add_sign("Stand on the crusher to ride it up.", Vector3(-2.2, 0, -99.0))
	coin_line(Vector3(0, 4.6, -105.2), Vector3(0, 4.6, -107.0), 2)
	deco("factory:robot-arm-a", Vector3(-2.4, 0, -103.6), 45.0, 1.0)
	deco("factory:robot-arm-b", Vector3(2.4, 0, -103.6), -45.0, 1.0)
	deco("factory:machine", Vector3(-2.2, 4.0, -110.0), 90.0, 1.0)
	prop("factory:cog-b", Vector3(-3.6, 1.6, -100.0), 90.0, 2.6, 90.0)
	prop("factory:cog-c", Vector3(3.6, 1.6, -101.5), 90.0, 2.6, 90.0)


## Sky Castle: two towers up from the ledge, each a double jump.
func _castle() -> void:
	for t in TOWERS:
		tower(t, 2.5, t.y + 6.0)
		deco("castle:flag-pennant", t + Vector3(0.9 * signf(t.x), 0, 0.9), 45.0, 1.2)
	coin_line(Vector3(0.6, 6.4, -112.6), Vector3(1.4, 7.4, -114.2), 2)
	coin_line(Vector3(0.2, 8.6, -117.6), Vector3(-1.0, 9.4, -119.0), 2)
	add_sign("Too high? Jump twice.", Vector3(2.2, 4.0, -107.0))
	# Off the racing line: a ledge west of the second tower.
	if not is_speedrun():
		ledge(-8, -122, -5, -119, 10.0, "snow")
		add_gem(GEM, Vector3(-6.6, 10.3, -120.6))
		add_heart(Vector3(-5.6, 10.0, -121.4))


## Star Station: a deck, and a fan's updraft up to the summit.
func _station() -> void:
	deck(-3, -131, 3, -124, STATION, "station:floor-panel", 0.3)
	add_checkpoint(Vector3(-2.2, STATION, -124.8), Vector3.FORWARD)
	deco("station:container", Vector3(2.3, STATION, -125.6), 10.0, 1.6)
	deco("station:container-tall", Vector3(-2.4, STATION, -130.2), -15.0, 1.6)
	deco("station:table-display-planet", Vector3(2.4, STATION + 0.3, -130.2), 0.0, 1.5)
	var foot := Vector3(0, STATION - 2.0, -132.5)
	ledge(-2, -134, 2, -131, foot.y, "snow")
	add(WindZone.make(Vector3(3, SUMMIT + 1.0 - foot.y, 3), Vector3.UP * UPDRAFT), foot)
	var fan := StarFan.make(Vector3.UP, 1.1)
	fan.rise = SUMMIT + 2.0 - foot.y
	add(fan, foot)
	coin_line(Vector3(0, SUMMIT - 1.0, foot.z), Vector3(0, SUMMIT + 2.0, foot.z - 1.2), 3)
	add_sign("Jump into the updraft and it lifts you up.", Vector3(2.2, STATION, -127.6))


## The summit, the last bee, and a rainbow up to the flag.
func _finale() -> void:
	land(-4, -142, 4, -134, SUMMIT, 5)
	add_checkpoint(Vector3(-3.0, SUMMIT, -135.0), Vector3.FORWARD)
	add_heart(Vector3(3.0, SUMMIT, -135.0))
	var bee := StarBouncer.make(Vector3.ZERO, 3.0)
	bee.power = 16.0
	add(bee, BEE)
	coin_line(Vector3(0, SUMMIT + 2.5, -146.0), Vector3(0, LANDING + 1.5, -149.0), 3)
	land(-4, -154, 4, -149, LANDING, 5)
	rainbow_path(Vector3(0, LANDING, -154.0), Vector3(0, FINISH.y, -162.0))
	add_coin(Vector3(0, LANDING + 1.4, -157.0))
	add_coin(Vector3(0, FINISH.y + 0.6, -160.0))
	# The flag, with a trophy from every world round it.
	land(-6, -172, 6, -162, FINISH.y, 6)
	goal(FINISH, Vector3.FORWARD)
	var trophies := [
		["tree", 1.0], ["holiday:tree-decorated-snow", 1.0], ["pirate:chest", 0.6], ["grave:pumpkin-tall-carved", 2.4],
		["food:cake-birthday", 3.0], ["factory:robot-arm-a", 1.0], ["castle:flag-banner-long", 1.6], ["station:table-display-planet", 1.5],
	]
	for i in trophies.size():
		var x := -4.8 if i % 2 == 0 else 4.8
		var z := -163.6 - 2.4 * floorf(i / 2.0)
		var at := Vector3(x, FINISH.y, z)
		if trophies[i][0] == "tree" or trophies[i][0] == "holiday:tree-decorated-snow":
			tree(at, trophies[i][0], trophies[i][1])
		else:
			deco(trophies[i][0], at, -90.0 * signf(x), trophies[i][1])
	glow(Vector3(-8, 6, -30), 1.8)
	glow(Vector3(8, 8, -66), 1.6, Color("ffb3f0"))
	glow(Vector3(-8, 12, -110), 1.8)
	glow(Vector3(9, 20, -140), 1.6, Color("ffb3f0"))
	glow(Vector3(-8, 26, -165), 2.4)
	glow(Vector3(8, 27, -170), 2.0)
	add(StarRainbow.make(22.0, 0.0, 0.5), Vector3(0, 8, -186))
