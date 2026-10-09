class_name SpookyCryptCreep
extends Level
## Course 1 of Spooky Hollow: hop the stone tops across an open crypt, run
## a corridor of slamming crypt lids, cross the bone yard past pacing
## skeletons and popping spikes, climb two crypt roofs past a spinning arm
## of pumpkin lanterns, and hop the coffins floating over a pit to the
## flag. It runs north, then turns east at the roofs, where the camera
## turns with it.
##
## Adventure: coins, a heart, checkpoints, and a hidden gem on top of the
## corridor wall (ride a lid up to reach it). Speedrun: the course and the
## clock.

const STAR := "spooky/crypt_creep"
const GEM := "spooky/gem_crypt_creep"

var lids: Array[SpookyCryptLid] = []
var skeletons: Array[Critter] = []
var spinner: Spinner
var coffins: Array[SpookyCoffin] = []


func _init() -> void:
	super()
	title = "Crypt Creep"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "lids", "at": Vector3(0, 1.0, -23.4), "face": Vector3.FORWARD},
		{"name": "coffins", "at": Vector3(2.7, 4.0, -58.3), "face": Vector3.RIGHT},
	]


func build() -> void:
	# The start, in front of the crypt's gate.
	land(-3, -6, 3, 4, 0, 3)
	add_sign("Crypt lids slam down hard. Wait for one to lift, then run under it.", Vector3(-2, 0, 1.5))
	SpookyProps.lamp(self, Vector3(-2.6, 0, 3.4))
	SpookyProps.lamp(self, Vector3(2.6, 0, 3.4))
	SpookyProps.fence(self, Vector3(-3, 0, 4), Vector3(-3, 0, -6))
	SpookyProps.fence(self, Vector3(3, 0, 4), Vector3(3, 0, -6))
	deco("grave:iron-fence-border-gate", Vector3(0, 0, -5.6), 0.0, 2.2)
	coin_line(Vector3(0, 0.3, -1), Vector3(0, 0.3, -4), 3)

	# The open crypt: stone tops to hop along over the dark.
	SpookyProps.swamp(self, -4, -22, 4, -6, -2.0)
	land(-2, -10, 0, -7, 0, 4, "snow")
	land(0, -15, 2, -12, 0.5, 4, "snow")
	land(-2, -20, 0, -17, 1.0, 4, "snow")
	for at in [Vector3(-1, 0, -8.5), Vector3(1, 0.5, -13.5), Vector3(-1, 1.0, -18.5)]:
		deco("grave:grave-border", at, 0.0, 1.4)
		add_coin(at + Vector3.UP * 0.6)
	deco("grave:candle-multiple", Vector3(-1.6, 0, -7.4), 0.0, 2.0)
	deco("grave:candle-multiple", Vector3(1.6, 0.5, -12.4), 0.0, 2.0)
	SpookyProps.glow(self, Vector3(0, 2.0, -13.5), 1.4, 7.0)

	# The corridor of crypt lids, between two high walls.
	land(-2, -38, 2, -22, 1.0, 4, "snow")
	land(-3, -38, -2, -22, 4.0, 7, "snow")
	land(2, -38, 3, -22, 4.0, 7, "snow")
	add_checkpoint(Vector3(-1, 1.0, -22.6), Vector3.FORWARD)
	add_heart(Vector3(1.2, 1.0, -22.6))
	# Look down on the lids from high up, so a raised one never hides the hero.
	camera_zone(Vector3(-3, 0.5, -38), Vector3(3, 12, -21.5), 0.0, 54.0, 10.5)
	for i in 3:
		# Each lid lifts a moment after the one before, so a runner can flow
		# through.
		var lid := SpookyCryptLid.slab(Vector3(4, 1, 2), 2.2, fposmod(-0.21 * i, 1.0))
		add(lid, Vector3(0, 1.0, -25.5 - i * 4.5))
		lids.append(lid)
	for z in [-27.75, -32.25, -36.5]:
		add_coin(Vector3(0, 1.3, z))
	for z in [-23.0, -27.75, -32.25, -37.0]:
		SpookyProps.glow(self, Vector3(0, 3.6, z), 1.0, 5.0)
		deco("grave:candle", Vector3(-1.8, 1.0, z), 0.0, 2.2)
		deco("grave:candle", Vector3(1.8, 1.0, z), 0.0, 2.2)
	# Up on the west wall: a gem for anyone who rides a lid up.
	add_gem(GEM, Vector3(-2.5, 4.0, -36.5))
	add_coin(Vector3(-2.5, 4.3, -31))
	add_coin(Vector3(-2.5, 4.3, -33.5))

	# The bone yard: skeletons pace across it, and a row of spikes pops up.
	land(-5, -50, 5, -38, 1.0, 4)
	add_checkpoint(Vector3(-3.5, 1.0, -39), Vector3.FORWARD)
	skeletons.append(add(Critter.make("grave:character-skeleton", Vector3(7, 0, 0), 3.6, 0.0, 1.05), Vector3(-3.5, 1.0, -41.5)) as Critter)
	skeletons.append(add(Critter.make("grave:character-skeleton", Vector3(-7, 0, 0), 3.6, 0.5, 1.05), Vector3(3.5, 1.0, -47.5)) as Critter)
	for i in 8:
		add(SpikeTrap.make(i * 0.08), Vector3(-3.5 + i, 1.0, -44.5))
	for x in [-4.4, 4.4]:
		SpookyProps.stone_row(self, Vector3(x, 1.0, -39.5), Vector3(x, 1.0, -48.5), 4, 90.0 if x < 0 else -90.0, 2)
	SpookyProps.lamp(self, Vector3(-4.4, 1.0, -44.5), "single", 90.0)
	SpookyProps.lamp(self, Vector3(4.4, 1.0, -44.5), "single", -90.0)
	for z in [-40.0, -43.0, -46.0, -49.0]:
		add_coin(Vector3(0, 1.3, z))
	add_heart(Vector3(-3.6, 1.0, -49.2))

	# Two crypt roofs, the second with a spinning arm of pumpkin lanterns.
	land(-3, -56, 3, -50, 2.5, 4)
	land(-3, -62, 3, -58, 4.0, 5, "snow")
	SpookyProps.crypt(self, Vector3(2.2, 2.5, -54.8), 90.0, 1.0)
	SpookyProps.pine(self, Vector3(-2.3, 2.5, -52.2), "grave:pine-crooked", 1.2)
	spinner = Spinner.make(2, 80.0, "grave:pumpkin-carved")
	spinner.model_scale = 2.4
	add(spinner, Vector3(0, 4.0, -60))
	SpookyProps.paint(self, spinner.get_child(0))
	add_coin(Vector3(1.5, 4.3, -58.7))
	add_coin(Vector3(1.5, 2.8, -52.5))
	add_checkpoint(Vector3(-2.2, 2.5, -50.6), Vector3.FORWARD)
	camera_zone(Vector3(-5, 2.2, -68), Vector3(28, 14, -57.5), -90.0, 30.0, 10.0)

	# Coffins float over a dark pit: each drops away soon after it's stood on.
	SpookyProps.swamp(self, 3, -65, 13, -55, -1.0)
	for i in 3:
		var c := SpookyCoffin.floating(0.5)
		add(c, Vector3(5.0 + 3.0 * i, 2.5, -60))
		coffins.append(c)
		add_coin(Vector3(5.0 + 3.0 * i, 3.0, -60))
	for at in [Vector3(5, 0, -63.5), Vector3(10, 0, -56.5), Vector3(12.5, 0, -63)]:
		deco("grave:candle-multiple", at + Vector3.UP * -1.0, 0.0, 2.4)
	SpookyProps.glow(self, Vector3(8.0, 1.5, -60), 1.2, 6.0)

	# The way out, and the flag.
	land(13, -66, 26, -54, 1.0, 4)
	add_flag(Vector3(20, 1.0, -60), Vector3.RIGHT)
	SpookyProps.lamp(self, Vector3(18.4, 1.0, -62.2), "single")
	SpookyProps.lamp(self, Vector3(18.4, 1.0, -57.8), "single")
	SpookyProps.mausoleum(self, Vector3(23.8, 1.0, -60), -90.0, 1.4)
	SpookyProps.stone_row(self, Vector3(15, 1.0, -65), Vector3(19, 1.0, -65), 3)
	SpookyProps.pine(self, Vector3(15.5, 1.0, -55.2), "grave:pine-crooked", 1.3)
	coin_line(Vector3(15, 1.3, -60), Vector3(17.5, 1.3, -60), 3)
	finish()
