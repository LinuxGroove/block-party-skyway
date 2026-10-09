class_name HauntedHeights
extends StarCourse
## Star Road course 6, Spooky Hollow meets Sky Castle: a graveyard where
## ghosts drift, a wall kick up a slot in the haunted keep, crumbling
## stones climbing into the night, a spring past a ghost, a wall walk with
## more of them, and a last wall kick up to the flag on the roof.

const STAR := "star/haunted_heights"
const GEM := "star/gem_haunted_heights"
## Ghosts: [x they start from, height, z]. They drift across and back.
const GHOSTS := [[-3.0, 0.0, -11.0], [3.0, 0.0, -17.0], [-3.0, 8.0, -31.5], [3.0, 8.0, -34.5], [3.0, 18.0, -67.0], [-3.0, 18.0, -72.0], [3.0, 18.0, -77.0], [-3.0, 18.0, -82.0]]
## The two wall-kick slots, each between two blocks of the keep: the
## slot's centre at its foot, and the height of its top.
const SLOTS := [Vector3(-0.5, 0, -26.0), Vector3(-0.5, 18.0, -88.0)]
const SLOT_TOPS := [8.0, 26.0]
## Crumbling stones climbing from the keep's first tier.
const STONES := [Vector3(0, 9, -38.5), Vector3(0, 10, -41.5), Vector3(0, 11, -44.5), Vector3(0, 12, -47.5), Vector3(0, 13, -50.5), Vector3(0, 14, -53.5)]
const SPRING := Vector3(0, 14, -59.5)
## The ghost that drifts over the spring.
const SPRING_GHOST := Vector3(-3.0, 16.0, -61.0)
## The wall walk after the spring.
const WALK := 18.0
const ROOF := 26.0


func _init() -> void:
	super()
	title = "Haunted Heights"
	cloud_center = Vector3(0, 0, -50)
	cloud_spread = 60.0


func build() -> void:
	start_pad(-3, -6, 3, 4, "A haunted keep! Ghosts can't be jumped on, so wait for them to drift aside.")
	deco("grave:lightpost-double", Vector3(-2.5, 0, -5.4), 0.0, 1.4)
	deco("grave:pumpkin-carved", Vector3(2.4, 0, -5.0), 200.0, 1.6)
	deco("grave:iron-fence", Vector3(2.4, 0, 3.0), 90.0, 1.2)

	# The graveyard, with two ghosts drifting across.
	land(-4, -28, 4, -6, 0, 3)
	var stones := ["grave:gravestone-cross", "grave:gravestone-round", "grave:gravestone-bevel", "grave:gravestone-decorative"]
	for k in 6:
		var x := -3.4 if k % 2 == 0 else 3.4
		deco(stones[k % stones.size()], Vector3(x, 0, -8.0 - k * 2.6), 90.0 if x < 0.0 else -90.0, 1.4)
	for z in [-9.0, -14.0, -20.0]:
		add_coin(Vector3(0, 0.6, z))

	# The keep: a slot to kick up between two blocks, and its first tier.
	var s0: Vector3 = SLOTS[0]
	_slot(s0, SLOT_TOPS[0])
	land(-4, -36, 4, -28, SLOT_TOPS[0], 9)
	add_checkpoint(Vector3(-3.2, 0, -21.6), Vector3.FORWARD)
	add_heart(Vector3(3.2, 0, -21.6))
	add_sign("A narrow slot: jump at one wall, then keep jumping from wall to wall.", Vector3(-2.6, 0, -22.2))
	camera_zone(Vector3(-6, -2, -31), Vector3(6, 12, -20), 0.0, 22.0, 11.0)
	coin_line(Vector3(-0.5, 3.0, -26.0), Vector3(-0.5, 7.0, -26.0), 3)
	_battlements(-4, 4, -36, SLOT_TOPS[0])
	add_checkpoint(Vector3(-3.2, SLOT_TOPS[0], -29.0), Vector3.FORWARD)

	# Off the racing line: a crypt ledge below the first tier, with a spring.
	if not is_speedrun():
		ledge(-9, -35, -5, -30, 4.0)
		deco("grave:crypt-small", Vector3(-8.0, 4.0, -33.8), 90.0, 1.0)
		add_gem(GEM, Vector3(-6.4, 4.3, -31.0))
		add(Spring.new(), Vector3(-5.6, 4.0, -33.4))

	# Crumbling stones climbing away from the keep.
	for st in STONES:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.5), st)
		add_coin(st + Vector3(0, 1.2, 1.4))
	add_sign("These stones crumble: hop up them quickly!", Vector3(2.6, SLOT_TOPS[0], -34.6))

	# A ledge with a spring, and a ghost drifting through where it throws you.
	land(-2, -61, 2, -56, SPRING.y, 3)
	add(Spring.new(), SPRING)
	add_heart(Vector3(1.4, SPRING.y, -56.8))
	var sg := Critter.make("grave:character-ghost", Vector3(-SPRING_GHOST.x * 2.0, 0, 0), 2.6, 0.0, 1.0)
	sg.spiky = true
	add(sg, SPRING_GHOST)

	# A wall walk with two more ghosts, then the last slot up to the roof.
	land(-1, -90, 1, -62, WALK, 4)
	add_checkpoint(Vector3(-0.6, WALK, -63.0), Vector3.FORWARD)
	for z in range(-85, -62, 2):
		for x in [-1.25, 1.25]:
			deco("castle:wall-narrow", Vector3(x, WALK - 0.9, z + 1.0), 90.0, 1.0)
	var s1: Vector3 = SLOTS[1]
	_slot(s1, SLOT_TOPS[1])
	land(-5, -100, 5, -90, ROOF, 10)
	camera_zone(Vector3(-6, 16, -89.6), Vector3(6, 30, -82), 0.0, 26.0, 11.0)
	coin_line(Vector3(-0.5, WALK + 3.0, -88.0), Vector3(-0.5, WALK + 7.0, -88.0), 3)

	# Every ghost but the spring's drifts across a path.
	for g in GHOSTS:
		var ghost := Critter.make("grave:character-ghost", Vector3(-2.0 * g[0], 0, 0), 2.6, 0.0 if g[0] < 0.0 else 0.5, 1.0)
		ghost.spiky = true
		ghost.bob = 0.25
		add(ghost, Vector3(g[0], g[1], g[2]))

	# The flag on the roof.
	goal(Vector3(0, ROOF, -96.5), Vector3.FORWARD)
	_battlements(-5, 5, -100, ROOF)
	for x in [-4.2, 4.2]:
		deco("castle:flag-banner-long", Vector3(x, ROOF, -98.8), 0.0, 1.6)
		deco("grave:lantern-candle", Vector3(x, ROOF, -91.0), 0.0, 2.0)
	glow(Vector3(-8, 12, -40), 1.8)
	glow(Vector3(8, 24, -66), 1.6, Color("ffb3f0"))
	glow(Vector3(-7, 32, -98), 2.0)
	add(StarRainbow.make(16.0, 0.0, 0.5), Vector3(0, 14, -114))
	finish()


## A slot in the keep, centred on `foot` (x on a half metre), 1 m wide and
## 4 deep, between two blocks rising a metre above `top` (the tier behind
## it), so the last kick clears the tier's edge.
func _slot(foot: Vector3, top: float) -> void:
	var x := floori(foot.x)
	var z0 := int(foot.z) - 2
	var depth := int(top - foot.y) + 2
	land(-4, z0, x, z0 + 4, top + 1.0, depth)
	land(x + 1, z0, 4, z0 + 4, top + 1.0, depth)
	for side in [-4.0, 4.0]:
		deco("castle:tower-square-mid-windows", Vector3(side * 0.9, top - 2.0, z0 + 3.4), 0.0, 1.6)


## Castle battlements along the back edge of a tier, from x0 to x1 at z.
func _battlements(x0: int, x1: int, z: int, top: float) -> void:
	for x in range(x0, x1):
		deco("castle:wall-narrow", Vector3(x + 0.5, top - 0.9, z + 0.25), 0.0, 1.0)
