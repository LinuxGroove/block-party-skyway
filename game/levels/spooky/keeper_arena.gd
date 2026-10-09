class_name SpookyKeeperArena
extends BossArena
## The Night Keeper's graveyard: a round lawn of graves in the middle of the
## swamp, lit by lamps, with his crypt at the back. Falling off the edge
## into the swamp comes back at the flag by the gate.

var keeper: SpookyNightKeeper


func _init() -> void:
	super()
	title = "The Night Keeper"
	spawn = Vector3(0, 0, 8.5)
	spawn_facing = Vector3.FORWARD
	star_spot = Vector3(0, 1.0, 0)


func build() -> void:
	# The lawn: a square with its corners cut, so it's nearly round.
	land(-10, -8, 10, 8, 0, 3)
	land(-8, -10, 8, -8, 0, 3)
	land(-8, 8, 8, 12, 0, 3)
	land(-12, -6, -10, 6, 0, 3)
	land(10, -6, 12, 6, 0, 3)
	SpookyProps.swamp(self, -40, -40, 40, 40, -1.5)
	add_checkpoint(Vector3(0, 0, 10), Vector3.FORWARD)
	# His crypt at the back, on its own bank.
	land(-5, -17, 5, -10, 0.5, 3)
	SpookyProps.mausoleum(self, Vector3(0, 0.5, -13.6), 0.0, 2.4)
	SpookyProps.pine(self, Vector3(-4, 0.5, -15.5), "grave:pine-crooked", 1.8)
	SpookyProps.pine(self, Vector3(4, 0.5, -15.5), "grave:pine-fall-crooked", 1.8)
	# Lamps round the edge, graves and pumpkins between them.
	for at in [Vector3(-8.5, 0, -6.5), Vector3(8.5, 0, -6.5), Vector3(-8.5, 0, 6.5), Vector3(8.5, 0, 6.5)]:
		SpookyProps.lamp(self, at, "all", 0.0, 2.2, 10.0)
	for i in 10:
		var a := TAU * (i + 0.5) / 10.0
		var at := Vector3(sin(a) * 10.3, 0, cos(a) * 10.3)
		if absf(at.x) < 2.5 and at.z > 0.0:
			continue
		deco(["grave:gravestone-cross", "grave:gravestone-round", "grave:gravestone-broken", "grave:gravestone-roof"][i % 4], at, rad_to_deg(a) + 180.0, 1.8)
	SpookyProps.pumpkins(self, Vector3(-7, 0, 9), Vector3(-3, 0, 11), 4, 2)
	SpookyProps.pumpkins(self, Vector3(3, 0, 9), Vector3(7, 0, 11), 4, 5)
	deco("grave:iron-fence-border-gate", Vector3(0, 0, 11.6), 0.0, 2.0)
	# Hearts to pick up between slams.
	add_heart(Vector3(-10.5, 0, 0))
	add_heart(Vector3(10.5, 0, 0))
	add_heart(Vector3(0, 0, -9))
	finish()
	keeper = SpookyNightKeeper.new()
	keeper.facing = Vector3.BACK
	add_boss(keeper, Vector3(0, 0, -4))
