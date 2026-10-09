class_name SpookyGhostBridge
extends Level
## Course 2 of Spooky Hollow: a rickety plank bridge across the swamp.
## Ghosts drift over the planks (too spiky to jump on: wait for a gap or
## pound them), a run of planks sinks as soon as it's stood on, a spinning
## arm of lanterns guards the islet in the middle, then the bridge turns
## west past two more ghosts to a raft that carries the hero to the far
## bank, where two last ghosts guard the flag. The camera turns west with
## it.
##
## Adventure: coins, hearts, checkpoints, and a hidden gem on a little
## islet north of the middle one, with a spring back up. Speedrun: the
## course and the clock.

const STAR := "spooky/ghost_bridge"
const GEM := "spooky/gem_ghost_bridge"

var ghosts: Array[SpookyGhost] = []
var spinner: Spinner
var raft: MovingPlatform


func _init() -> void:
	super()
	title = "Ghost Bridge"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 9.5, false]


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "islet", "at": Vector3(0, 0, -29), "face": Vector3.FORWARD},
		{"name": "raft", "at": Vector3(-14, 0, -33), "face": Vector3.LEFT},
	]


func build() -> void:
	SpookyProps.swamp(self, -44, -52, 12, 10, -1.5)
	var n := 0
	for at in [Vector3(-5, 0, -7), Vector3(4.5, 0, -11), Vector3(-6.5, 0, -19), Vector3(5, 0, -22),
			Vector3(-3.5, 0, -25.5), Vector3(7, 0, -33), Vector3(-9, 0, -27.5), Vector3(-15, 0, -38.5),
			Vector3(-21, 0, -27.5), Vector3(-24, 0, -39), Vector3(6, 0, 1), Vector3(-7, 0, -1)]:
		SpookyProps.reeds(self, at + Vector3.DOWN * 1.5, n)
		n += 1
	# The near bank.
	land(-3, -4, 3, 4, 0, 3)
	add_sign("Ghosts are too spiky to jump on. Wait for a gap, or crouch in the air to ground pound one.", Vector3(-2, 0, 1.5))
	SpookyProps.lamp(self, Vector3(2.4, 0, 3))
	SpookyProps.pine(self, Vector3(-2.2, 0, 3.4), "grave:pine-crooked", 1.3)
	deco("grave:iron-fence-border-gate", Vector3(0, 0, -3.6), 0.0, 2.0)

	# The first stretch of bridge, with a ghost drifting across it.
	_planks(-1, -16, 1, -4, 0)
	_ghost(Vector3(-3.2, 0.3, -10), Vector3(6.4, 0, 0), 4.4, 0.0)
	for z in [-6.0, -8.0, -12.0, -14.0]:
		add_coin(Vector3(0, 0.3, z))
	_posts(-16, -4, 0)

	# Planks that sink as soon as they're stood on: keep running.
	for i in 4:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.45), Vector3(0, 0, -17.25 - i * 2.5))
	for i in 4:
		add_coin(Vector3(0, 0.3, -17.25 - i * 2.5))

	# The islet in the middle, with a spinning arm of lanterns.
	land(-4, -38, 4, -28, 0, 3)
	add_checkpoint(Vector3(3, 0, -29.2), Vector3.FORWARD)
	spinner = Spinner.make(3, 55.0, "grave:lantern-candle")
	spinner.model_scale = 2.8
	add(spinner, Vector3(0, 0, -33))
	SpookyProps.paint(self, spinner.get_child(0))
	SpookyProps.glow(self, Vector3(0, 2.0, -33), 1.4, 6.0)
	SpookyProps.lamp(self, Vector3(-3.4, 0, -28.6), "single")
	SpookyProps.stone(self, Vector3(3.2, 0, -37.2), 2, 180.0)
	add_heart(Vector3(3.2, 0, -31.5))
	# Off the north side, a little islet with the hidden gem.
	ledge(1, -43, 4, -40, -0.6)
	add_gem(GEM, Vector3(2.5, -0.6, -41.8))
	add(Spring.new(), Vector3(1.6, -0.6, -40.8))
	SpookyProps.pine(self, Vector3(3.4, -0.6, -42.4), "grave:pine-fall-crooked", 1.0)

	# West from the islet: more bridge, two ghosts drifting along it.
	camera_zone(Vector3(-48, -6, -48), Vector3(-2.5, 12, -24), 90.0, 30.0, 10.0)
	_planks(-17, -34, -4, -32, 0)
	_posts(-17, -4, 0, true)
	_ghost(Vector3(-8, 0.3, -35.4), Vector3(0, 0, 4.8), 4.0, 0.0)
	_ghost(Vector3(-13, 0.3, -30.6), Vector3(0, 0, -4.8), 4.0, 0.35)
	for x in [-6.0, -10.5, -15.0]:
		add_coin(Vector3(x, 0.3, -33))
	add_checkpoint(Vector3(-5.6, 0, -33), Vector3.LEFT)

	# A raft drifts back and forth to the far bank.
	raft = add(MovingPlatform.make(Vector3(-6, 0, 0), 4.0, 0.0, Vector3(3, 0.4, 3), "platform"), Vector3(-18.5, 0, -33)) as MovingPlatform
	coin_line(Vector3(-19, 0.6, -33), Vector3(-24, 0.6, -33), 3)

	# The far bank: two more ghosts drift across the way to the flag.
	land(-42, -40, -27, -26, 0.5, 3)
	add_checkpoint(Vector3(-28.4, 0.5, -36.4), Vector3.LEFT)
	_ghost(Vector3(-31.5, 0.8, -35.4), Vector3(0, 0, 4.8), 3.6, 0.0)
	_ghost(Vector3(-34.5, 0.8, -30.6), Vector3(0, 0, -4.8), 3.6, 0.3)
	add_flag(Vector3(-37.5, 0.5, -33), Vector3.LEFT)
	SpookyProps.mausoleum(self, Vector3(-40.5, 0.5, -33), 90.0, 1.4)
	SpookyProps.lamp(self, Vector3(-36, 0.5, -36.6), "double")
	SpookyProps.lamp(self, Vector3(-36, 0.5, -29.4), "double")
	SpookyProps.pine(self, Vector3(-40.5, 0.5, -38.5), "grave:pine", 1.4)
	SpookyProps.pine(self, Vector3(-40.5, 0.5, -27.5), "grave:pine-crooked", 1.4)
	SpookyProps.stone_row(self, Vector3(-29, 0.5, -39), Vector3(-34, 0.5, -39), 3, 0.0, 3)
	coin_line(Vector3(-30, 0.8, -33), Vector3(-35, 0.8, -33), 3)
	finish()


## A plank walkway over the swamp, solid, from (x0, z0) to (x1, z1).
func _planks(x0: int, z0: int, x1: int, z1: int, top: float) -> void:
	solid(Vector3(x0, top - 0.3, z0), Vector3(x1, top, z1))
	for x in range(x0, x1):
		for z in range(z0, z1):
			piece("platform", Vector3(x + 0.5, top - 0.2, z + 0.5), 90.0 * ((x + z) % 2))


## Posts and lanterns along both sides of a stretch of bridge.
func _posts(a: int, b: int, top: float, west := false) -> void:
	for t in range(a + 2, b, 4):
		for side in [-1.4, 1.4]:
			var at := Vector3(t, top - 1.6, -33 + side) if west else Vector3(side, top - 1.6, t)
			piece("grave:pillar-small", at, 0.0, 2.6)
		var lamp_at := Vector3(t, top, -31.6) if west else Vector3(1.4, top, t)
		piece("grave:lantern-candle", lamp_at + Vector3.UP * 0.38, 0.0, 1.6)
		SpookyProps.glow(self, lamp_at + Vector3.UP * 0.8, 0.9, 4.0)


func _ghost(at: Vector3, travel: Vector3, period: float, phase: float) -> void:
	var g := SpookyGhost.drift(travel, period, phase)
	add(g, at)
	ghosts.append(g)
