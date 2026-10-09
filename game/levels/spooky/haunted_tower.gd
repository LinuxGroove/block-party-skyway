class_name SpookyHauntedTower
extends Level
## Course 4 of Spooky Hollow: climb the haunted tower's south face. Jump up
## the ledges past a ghost that drifts through the wall, kick up the gap
## between the tower and its buttress, hop a row of crumbling ledges back
## across the face, ride the cold draught up the west side, and dodge the
## lantern arm on the roof and ride the lift up to the flag in the belfry.
##
## Adventure: coins, hearts, checkpoints, and a hidden gem on a ledge off
## the west side, reached by a spring on the first ledge. Speedrun: the
## course and the clock.

const STAR := "spooky/haunted_tower"
const GEM := "spooky/gem_haunted_tower"
## The roof's height, and the belfry's on top of it.
const ROOF := 16.0
const BELFRY := 19.5

var ghost: SpookyGhost
var crumbling: Array[FallingPlatform] = []
var spinner: Spinner
var lift: MovingPlatform


func _init() -> void:
	super()
	title = "Haunted Tower"
	spawn = Vector3(0, 0, 3)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 20.0, 13.0, false]


func build() -> void:
	_tower()
	_courtyard()
	_ledges()
	_chimney()
	_crumbling()
	_draught()
	_roof()
	finish()


## The tower itself and the buttress on its east side, dressed with
## windows, pillars and candles.
func _tower() -> void:
	land(-5, -14, 7, -6, ROOF, 17, "snow")
	land(8, -9, 10, -5, 10.5, 12, "snow")
	# Dark windows up the face, with a lit one here and there.
	for at in [Vector3(-3.5, 6.5, -5.95), Vector3(0.5, 8.5, -5.95), Vector3(4.5, 7.0, -5.95), Vector3(-1.5, 13.5, -5.95), Vector3(3.5, 14.0, -5.95)]:
		deco("grave:crypt-door", at, 0.0, 3.0)
	for at in [Vector3(0.5, 9.6, -5.4), Vector3(-1.5, 14.6, -5.4)]:
		SpookyProps.glow(self, at, 1.2, 5.0)


func _courtyard() -> void:
	land(-10, -6, 12, 6, 0, 3)
	add_sign("Climb the haunted tower to the flag on the roof!", Vector3(-2.5, 0, 4))
	SpookyProps.lamp(self, Vector3(3, 0, 4.5))
	SpookyProps.lamp(self, Vector3(-7, 0, -3), "single")
	SpookyProps.stone_row(self, Vector3(-9, 0, 0), Vector3(-9, 0, 4), 3, 90.0, 2)
	SpookyProps.stone_row(self, Vector3(10.5, 0, -2), Vector3(10.5, 0, 4), 3, -90.0, 5)
	SpookyProps.pine(self, Vector3(-8.5, 0, -4.5), "grave:pine-crooked", 1.6)
	SpookyProps.pine(self, Vector3(11, 0, -4.8), "grave:pine-fall-crooked", 1.5)
	SpookyProps.pumpkins(self, Vector3(4, 0, -3.6), Vector3(9, 0, -2.4), 5, 3)
	coin_line(Vector3(-1, 0.3, 1), Vector3(-3, 0.3, -1.5), 3)


## Ledges up the face, zig-zagging east, with a ghost drifting through.
func _ledges() -> void:
	ledge(-6, -6, -2, -4, 1.6, "snow")
	ledge(-1, -6, 3, -4, 3.2, "snow")
	ledge(4, -6, 8, -4, 4.8, "snow")
	ghost = SpookyGhost.drift(Vector3(0, 0, 3.6), 3.6, 0.0)
	add(ghost, Vector3(1.5, 3.5, -6.8))
	for at in [Vector3(-4, 1.6, -5), Vector3(1, 3.2, -5), Vector3(6, 4.8, -5)]:
		add_coin(at + Vector3.UP * 0.3)
	deco("grave:candle-multiple", Vector3(-2.5, 1.6, -5.6), 0.0, 2.0)
	deco("grave:candle-multiple", Vector3(-0.6, 3.2, -5.6), 0.0, 2.0)
	SpookyProps.glow(self, Vector3(-1.5, 3.0, -4.5), 1.0, 5.0)
	add_checkpoint(Vector3(4.6, 4.8, -4.6), Vector3.RIGHT)
	# Off the west side: a gem on a ledge, and a spring up to it.
	add(Spring.new(), Vector3(-5.4, 1.6, -5.4))
	ledge(-10, -6, -8, -4, 5.5, "snow")
	add_gem(GEM, Vector3(-9.0, 5.5, -5.0))
	deco("grave:candle", Vector3(-9.6, 5.5, -5.6), 0.0, 2.0)


## The gap between the tower and its buttress: kick up between them.
func _chimney() -> void:
	ledge(7, -9, 8, -6, 4.8, "snow")
	add_sign("Jump at a wall, then jump again to kick off it.", Vector3(7.4, 4.8, -4.4))
	add_heart(Vector3(9.3, 10.5, -8.4))
	coin_line(Vector3(7.5, 6.5, -7.5), Vector3(7.5, 9.5, -7.5), 3)
	deco("grave:lantern-candle", Vector3(9.6, 10.5, -5.4), 0.0, 2.2)
	SpookyProps.glow(self, Vector3(9.6, 11.4, -5.4), 1.2, 5.0)
	add_checkpoint(Vector3(9.2, 10.5, -6.0), Vector3.LEFT)


## Ledges that crumble a moment after they're stood on, back west across
## the face, over a balcony that catches a fall.
func _crumbling() -> void:
	for i in 3:
		var f := FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.7)
		add(f, Vector3(5.5 - 3.0 * i, 11.0, -5))
		crumbling.append(f)
		add_coin(Vector3(5.5 - 3.0 * i, 11.3, -5))
	ledge(-3, -6, 3, -4, 7.4, "snow")
	SpookyProps.fence(self, Vector3(-3, 7.4, -4.1), Vector3(3, 7.4, -4.1), "grave:iron-fence", 0.0)


## A cold draught blowing up the west side of the tower.
func _draught() -> void:
	add(WindZone.make(Vector3(2, 6.5, 2), Vector3.UP * 60.0), Vector3(-6.5, 9.0, -5))
	add_sign("A cold draught blows up the tower. Jump into it!", Vector3(-3.6, 11.0, -4.3))
	ledge(-5, -6, -3, -4, 11.0, "snow")
	coin_line(Vector3(-6.5, 12.5, -5), Vector3(-6.5, 15.5, -5), 3)


## The roof: an arm of lanterns sweeps round it, and a lift goes up to the
## belfry, where the flag waits.
func _roof() -> void:
	add_checkpoint(Vector3(-4.2, ROOF, -7.0), Vector3.RIGHT)
	add_heart(Vector3(-4.2, ROOF, -13.2))
	spinner = Spinner.make(3, 65.0, "grave:lantern-candle")
	spinner.model_scale = 2.8
	add(spinner, Vector3(-0.5, ROOF, -10))
	SpookyProps.paint(self, spinner.get_child(0))
	SpookyProps.glow(self, Vector3(-0.5, ROOF + 1.5, -10), 1.4, 7.0)
	SpookyProps.fence(self, Vector3(7, ROOF, -6.1), Vector3(-2, ROOF, -6.1), "grave:iron-fence", 0.0)
	SpookyProps.fence(self, Vector3(7, ROOF, -11), Vector3(7, ROOF, -6.1), "grave:iron-fence", 1.1)
	SpookyProps.fence(self, Vector3(-5, ROOF, -14), Vector3(3, ROOF, -14), "grave:iron-fence", 1.1)
	deco("grave:pumpkin-carved", Vector3(-4.4, ROOF, -10.5), 90.0, 2.4)
	coin_line(Vector3(-1.5, ROOF + 0.3, -6.9), Vector3(2.5, ROOF + 0.3, -6.9), 3)
	# The belfry on the roof's north-east corner, and the lift up to it.
	land(3, -14, 7, -11, BELFRY, 4, "snow")
	lift = add(MovingPlatform.make(Vector3(0, BELFRY - ROOF, 0), 4.4, 0.0, Vector3(2, 0.4, 2), "platform"), Vector3(5, ROOF, -9.5)) as MovingPlatform
	add_coin(Vector3(5, ROOF + 2.0, -9.5))
	add_flag(Vector3(5, BELFRY, -12.8), Vector3.FORWARD)
	for x in [3.4, 6.6]:
		for z in [-11.4, -13.6]:
			deco("grave:pillar-large", Vector3(x, BELFRY, z), 0.0, 3.0)
	piece("grave:crypt-large-roof", Vector3(5, BELFRY + 3.3, -12.5), 90.0, 2.0)
	SpookyProps.glow(self, Vector3(5, BELFRY + 2.6, -12.5), 1.6, 6.0)
	SpookyProps.glow(self, Vector3(5, ROOF + 1.2, -8.0), 1.0, 5.0)
