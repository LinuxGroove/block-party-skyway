class_name SunnyPinchArena
extends BossArena
## Captain Pinch's sand bar: a round beach out in the sea with a ring of
## rocks, open to the south where the hero arrives. Lure him into charging
## a rock, then jump on him while he's dizzy (see SunnyPinch). Knocked into
## the sea, the hero comes back at the flag by the way in.

const SAND := "res://game/levels/sunny/sunny_sand.png"
## The ring of rocks: how many, and how far out.
const ROCKS := 8
const RING := 8.6
const RADIUS := 12.5

var rock_spots: Array[Vector3] = []


func _init() -> void:
	super()
	title = "Captain Pinch's Sand Bar"
	spawn = Vector3(0, 0, 10.5)
	spawn_facing = Vector3.FORWARD
	block_palette = SAND
	star_spot = Vector3(0, 1.2, 0)
	camera_base = [0.0, 40.0, 13.0, true]


func build() -> void:
	water(-50, -50, 50, 50, -1.0, Color(0.2, 0.62, 0.9, 0.8))
	# A round sand bar, a row of blocks at a time.
	for i in range(-6, 6):
		var z0 := i * 2
		var zc := z0 + 1.0
		var half := int(floor(sqrt(RADIUS * RADIUS - zc * zc)))
		land(-half, z0, half, z0 + 2, 0, 3, "snow")
	# The ring of rocks, with a gap to the south for the way in.
	for i in ROCKS:
		var a := TAU * (i + 0.5) / ROCKS
		var at := Vector3(sin(a), 0, cos(a)) * RING
		rock_spots.append(at)
		piece("pirate:rocks-c", at, rad_to_deg(a) + 40.0 * i, 0.6)
		solid(at + Vector3(-0.85, 0, -0.85), at + Vector3(0.85, 1.3, 0.85))
	add_checkpoint(Vector3(-2.2, 0, 10.6), Vector3.FORWARD)
	for a in [PI / 2.0, PI, PI * 1.5]:
		add_heart(Vector3(sin(a), 0, cos(a)) * 10.6)
	# The captain's beach: palms, his flag and his boat.
	for i in 4:
		var a := TAU * (i + 0.5) / 4.0
		tree(Vector3(sin(a), 0, cos(a)) * 11.2, "pirate:palm-straight", 0.7)
	piece("pirate:flag-pirate-high", Vector3(0, 0, -11.6), 0.0, 0.8)
	piece("pirate:boat-row-small", Vector3(12.6, -0.5, 4.5), 70.0, 0.8)
	for at in [Vector3(4, 0, 11), Vector3(-6.5, 0, 4), Vector3(5.5, 0, -6), Vector3(-3, 0, -9)]:
		deco("stones", at, at.x * 29.0, 1.6)
	var pinch := SunnyPinch.new()
	pinch.rocks = rock_spots
	pinch.center = Vector3.ZERO
	pinch.edge = RADIUS - 2.5
	add_boss(pinch, Vector3(0, 0, -2))
	finish()


## Extra views for the screenshots.
func shots() -> Array:
	return [{"name": "rocks", "at": Vector3(0, 0, 6), "face": Vector3.FORWARD}]
