class_name PiratePollyShip
extends BossArena
## Polly's ship, the boss of Pirate Cove: the main deck of her flagship,
## out at sea. She circles the mainmast flinging cannonballs, then lands on
## the deck to reload (see PiratePolly). Hearts wait on the foredeck and
## the stern castle; fall overboard and it's back to the flag by the mast.

const SEA := PirateBuild.SEA
## The ship's size, and how deep it sits: its main deck is at 0.
const S := 3.0
const KEEL := -2.1 * S
## The raised decks fore and aft, and where Polly perches to start.
const FOREDECK := 0.7 * S
const STERN := 1.4 * S
const PERCH := Vector3(0, STERN, -13.0)
## Where she lands to reload.
const SPOTS := [Vector3(-3.0, 0, 0.6), Vector3(3.0, 0, 0.6), Vector3(-3.2, 0, -8.3), Vector3(3.2, 0, -8.3)]

var polly: PiratePolly


func _init() -> void:
	super()
	title = "Polly's Ship"
	spawn = Vector3(0, 0, 0.5)
	spawn_facing = Vector3.FORWARD
	star_spot = Vector3(0, 1.4, 0.8)
	camera_base = [0.0, 60.0, 12.0, true]


func build() -> void:
	PirateBuild.sea(self)
	# Sails furled, so they don't hide the deck.
	PirateBuild.ship(self, "pirate:ship-pirate-large", Vector3(0, KEEL, 0), 0.0, S, false, false)
	_decks()
	add_checkpoint(Vector3(-2.2, 0, 1.5), Vector3.FORWARD)

	# Hearts on the foredeck and the stern castle, up the stairs.
	add_heart(Vector3(-3.5, FOREDECK + 0.3, 6.5))
	add_heart(Vector3(3.5, FOREDECK + 0.3, 6.5))
	add_heart(Vector3(-3.0, STERN + 0.3, -13.5))
	add_heart(Vector3(3.0, STERN + 0.3, -13.5))

	# Low stacks of planks along the foot of the foredeck, so there's room
	# for the camera between the hero and its wall.
	for x in [-2.7, 0.0, 2.7]:
		piece("pirate:platform-planks", Vector3(x, 0, 2.55), 90.0)
	solid(Vector3(-4.05, 0, 1.6), Vector3(4.05, 0.43, 3.5))

	# Barrels and crates about the deck, out of the way.
	piece("pirate:barrel", Vector3(-4.6, 0, -2.5), 20.0, 0.8)
	piece("pirate:barrel", Vector3(4.6, 0, 1.5), 70.0, 0.8)
	piece("pirate:crate", Vector3(4.5, 0, -6.0), 90.0, 0.9)
	solid(Vector3(-5.1, 0, -3.0), Vector3(-4.1, 1.0, -2.0))
	solid(Vector3(4.1, 0, 1.0), Vector3(5.1, 1.0, 2.0))
	solid(Vector3(3.9, 0, -6.6), Vector3(5.1, 0.7, -5.4))

	# The rest of her fleet, at anchor round about.
	piece("pirate:ship-pirate-medium", Vector3(-26, SEA - 1.0, -12), 60.0, 1.6)
	piece("pirate:ship-pirate-small", Vector3(24, SEA - 1.0, 8), -120.0, 1.6)
	piece("pirate:ship-pirate-medium", Vector3(22, SEA - 1.0, -28), 200.0, 1.6)
	piece("pirate:rocks-sand-a", Vector3(-20, SEA, 18), 30.0, 1.6)

	polly = PiratePolly.new()
	polly.center = Vector3(0, 0, -3.5)
	for s in SPOTS:
		polly.spots.append(s)
	add_boss(polly, PERCH)
	finish()


## The ship's decks as plain boxes (her masts and rigging would only get in
## the camera's way): the main deck, the bulwarks, the foredeck and the stern
## castle with their stairs, the mainmast's foot, and a grating over the
## main hatch.
func _decks() -> void:
	solid(Vector3(-6.2, -1.0, -10.5), Vector3(6.2, 0, 3.5))
	for side in [-1.0, 1.0]:
		solid(Vector3(side * 5.5, 0, -10.5), Vector3(side * 6.4, 1.5, 3.5))
		# Stairs up to the foredeck and to the stern castle.
		solid(Vector3(side * 3.0, 0, 2.5), Vector3(side * 5.5, 1.05, 3.5))
		for k in 3:
			solid(Vector3(side * 3.0, 0, -9.5 - k), Vector3(side * 5.5, 1.05 * (k + 1), -10.5 - k))
		solid(Vector3(side * 5.5, STERN, -19.6), Vector3(side * 6.4, STERN + 0.8, -12.5))
	solid(Vector3(-5.5, 0, 3.5), Vector3(5.5, FOREDECK, 12.0))
	solid(Vector3(-3.0, 0, -12.5), Vector3(3.0, STERN, -10.5))
	solid(Vector3(-5.5, 0, -19.6), Vector3(5.5, STERN, -12.5))
	solid(Vector3(-5.5, STERN, -19.6), Vector3(5.5, STERN + 0.8, -19.0))
	solid(Vector3(-0.45, 0, -1.45), Vector3(0.45, 2.4, -0.55))
	for x in [-1.25, 1.25]:
		for z in [-4.75, -7.25]:
			piece("pirate:platform", Vector3(x, 0.02, z), 0.0, 1.0)
	# Low enough to step up on.
	solid(Vector3(-2.5, 0.0, -8.5), Vector3(2.5, 0.25, -3.5))
