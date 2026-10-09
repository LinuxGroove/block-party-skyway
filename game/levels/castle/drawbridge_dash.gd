class_name CastleDrawbridgeDash
extends Level
## Course 2 of Sky Castle: from gate to gate over the moat in the sky.
## Two drawbridges north, then east along a causeway through two portcullis
## gates, then north again over three drawbridges that come down one after
## another: catch the first and the rest follow like a wave.
##
## Each drawbridge is hinged on the near side and swings up in front of you,
## so you watch it come down and the camera never has one behind you.
##
## Adventure: coins, a heart, checkpoints, and a gem on an islet off the
## causeway. Speedrun: just the gates and the clock.

const P := preload("res://game/levels/castle/castle_parts.gd")

const STAR := "castle/drawbridge"
const GEM := "castle/gem_drawbridge"
## The causeway's middle, and the line the wave of bridges runs along.
const CAUSEWAY_Z := -25.5
const WAVE_X := 31.0

var bridges: Array[CastleDrawbridge] = []
var gates: Array[CastlePortcullis] = []
var wave: Array[CastleDrawbridge] = []


func _init() -> void:
	super()
	title = "Drawbridge Dash"
	spawn = Vector3(0, 0, 2.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 32.0, 9.5, false]


func build() -> void:
	# The start, and the first gate.
	land(-4, -4, 4, 5, 0, 4)
	add_sign("Wait for each drawbridge to come down, then dash across!", Vector3(-2.6, 0, 1.2))
	for at in [Vector3(-3, 0, 4), Vector3(3, 0, 4)]:
		P.tree(self, at, false, 1.6)
	_gate(Vector3(0, 0, -4), 6.0, 0.9)

	# The second island and its gate.
	land(-4, -16, 4, -10, 0, 4)
	add_checkpoint(Vector3(2.5, 0, -11.5), Vector3.FORWARD)
	coin_line(Vector3(0, 0, -5.5), Vector3(0, 0, -9), 3)
	_gate(Vector3(0, 0, -16), 6.0, 0.65)
	coin_line(Vector3(0, 0, -17.5), Vector3(0, 0, -21), 3)
	camera_zone(Vector3(-5, -2, -22), Vector3(5, 10, -2), 0.0, 48.0, 9.5)

	# The third island, where the way turns east along the causeway.
	land(-4, -30, 8, -22, 0, 4)
	add_checkpoint(Vector3(-1.5, 0, -27.5), Vector3.RIGHT)
	add_heart(Vector3(-2.5, 0, -24))
	add_sign("Portcullis gates! Run under while they're up.", Vector3(4, 0, -23), Vector3.BACK)
	P.tower(self, Vector3(-2.5, 0, -28.5), 1.6, 3, "roof")
	P.banner(self, Vector3(1.0, 0, -22.0), Vector3.BACK, false, 1.6)
	land(8, -27, 28, -24, 0, 3, "snow")
	for i in 2:
		var gate := CastlePortcullis.make_gate(3.0, 2.4, Vector3.RIGHT, 0.55 - i * 0.3)
		gates.append(add(gate, Vector3(14 + i * 7, 0, CAUSEWAY_Z)) as CastlePortcullis)
	coin_line(Vector3(9.5, 0, CAUSEWAY_Z), Vector3(12, 0, CAUSEWAY_Z), 2)
	coin_line(Vector3(16, 0, CAUSEWAY_Z), Vector3(19, 0, CAUSEWAY_Z), 2)
	camera_zone(Vector3(6, -2, -32), Vector3(29, 10, -19), 0.0, 30.0, 10.0)
	if not is_speedrun():
		# North of the causeway, across a gap: an islet with the gem.
		land(16, -33, 19, -30, 0, 3)
		add_gem(GEM, Vector3(17.5, 0, -31.8))
		coin_line(Vector3(17.5, 1.2, -28.2), Vector3(17.5, 0.5, -29.6), 2)
		P.tree(self, Vector3(18.4, 0, -32.5), false, 1.4)

	# The fourth island, and the wave of three bridges north.
	land(28, -30, 35, -21, 0, 4)
	add_checkpoint(Vector3(33, 0, -24), Vector3.FORWARD)
	add_sign("These three come down one after another. Catch the first and keep running!", Vector3(29, 0, -26.5), Vector3.LEFT)
	for i in 3:
		# Each comes down a little after the one before.
		var hinge := Vector3(WAVE_X, 0, -30 - i * 7)
		wave.append(_gate(hinge, 4.5, fposmod(0.62 - i * 0.16, 1.0), 2.0, 2.0, 1.0))
		if i < 2:
			land(28, -37 - i * 7, 34, -34 - i * 7, 0, 3, "snow")
			add_coin(hinge + Vector3(0, 0.1, -5.5))
	camera_zone(Vector3(27, -2, -50), Vector3(36, 10, -29), 0.0, 50.0, 9.5)

	# The finish.
	land(27, -57, 35, -48, 0, 4)
	add_flag(Vector3(WAVE_X, 0, -53), Vector3.FORWARD)
	P.tower(self, Vector3(28.5, 0, -55.5), 2.0, 3, "spire")
	P.tower(self, Vector3(33.5, 0, -55.5), 2.0, 3, "spire")
	P.banner(self, Vector3(28.5, 4.5, -54.45), Vector3.BACK, true, 1.6)
	P.banner(self, Vector3(33.5, 4.5, -54.45), Vector3.BACK, true, 1.6)
	P.cloud_sea(self, Vector3(14, 0, -26), 12.0, 70.0, -16.0, -8.0, 50, 21)
	finish()


## A drawbridge hinged at `hinge` that lowers north over a gap `reach`
## long, between two little gate towers. Returns the bridge.
func _gate(hinge: Vector3, reach: float, phase: float, down := 3.0, up := 2.0, swing := 1.2) -> CastleDrawbridge:
	var bridge := CastleDrawbridge.make(Vector3(0, 0, -reach), 3.0, down, up, phase)
	bridge.swing_time = swing
	add(bridge, hinge)
	bridges.append(bridge)
	for s in [-1.0, 1.0]:
		P.tower(self, hinge + Vector3(s * 2.3, 0, 0.8), 1.4, 3, "roof")
	return bridge
