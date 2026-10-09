class_name SunnyIsle
extends Level
## Sunny Isles' first island, for Adventure: a meadow with a terrace to the
## north (and the door to Saw Mill Sprint), Pebble the penguin's hollow to
## the west, the old tower to the east, and Lookout Islet across the Skyway
## once two stars are found.
##
## Stars: the course, Pebble's lost chicks, the silver coin rush, the top of
## the old tower, a ledge hidden under the north cliff, and the crabs' crate
## on Lookout Islet. Two hidden gems, plus one in the course.

signal countdown(label: String, seconds: float)

const WORLD := "sunny"
const SILVER_TIME := 30.0
## Where the hero comes out of the course door.
const DOOR_SPOT := Vector3(3, 2, -15.5)

var pebble: Islander
var chicks: Array[Chick] = []
var chicks_home := 0
var bridge: SkywayBridge
var silver_button: PadButton
var silver_left := 0.0
var _silver: Array[Pickup] = []
var _silver_got := 0


func _init() -> void:
	super()
	title = "Sunny Isles"
	spawn = Vector3(0, 0, 9)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 34.0, 10.0, true]
	music = "res://assets/kenney/audio/music/farm_frolics.ogg"


func build() -> void:
	_meadow()
	_terrace()
	_hollow()
	_tower()
	_lookout()
	_scenery()
	finish()
	if world_stars() >= int(Worlds.get_def(WORLD).skyway):
		bridge.show_bridge(false)


func world_stars() -> int:
	var n := 0
	for id in Worlds.star_ids(WORLD):
		if found_stars.has(id):
			n += 1
	return n


## Stars and gems still hidden on this island and in its course.
func secrets_left() -> int:
	var n := 0
	for id in Worlds.star_ids(WORLD):
		if not found_stars.has(id):
			n += 1
	for id in Worlds.gem_ids(WORLD):
		if not found_gems.has(id):
			n += 1
	return n


func collect_star(id: String) -> void:
	var before := world_stars()
	super(id)
	var need := int(Worlds.get_def(WORLD).skyway)
	if before < need and world_stars() >= need:
		bridge.show_bridge(true)
		say("The Skyway is back! A rainbow bridge reaches Lookout Islet.")


func _star(id: String, at: Vector3) -> Pickup:
	return add(Pickup.make("star", id, found_stars.has(id)), at) as Pickup


func _gem(id: String, at: Vector3) -> Pickup:
	return add(Pickup.make("gem", id, found_gems.has(id)), at) as Pickup


func _sign(text: String, at: Vector3, face := Vector3.BACK) -> void:
	var s := SignPost.new()
	s.text = text
	s.facing = face
	add(s, at)


func _checkpoint(at: Vector3, face: Vector3) -> void:
	var c := Checkpoint.new()
	c.facing = face
	add(c, at)


func _coin_ring(center: Vector3, radius: float, n: int) -> void:
	for i in n:
		var a := TAU * i / n
		add(Pickup.make("coin"), center + Vector3(cos(a), 0.1, sin(a)) * radius)


func _coin_line(from: Vector3, to: Vector3, n: int) -> void:
	for i in n:
		add(Pickup.make("coin"), from.lerp(to, float(i) / maxf(n - 1, 1)) + Vector3.UP * 0.1)


# --- The meadow (where the hero lands) ---------------------------------------

func _meadow() -> void:
	land(-12, -10, 12, 12, 0, 3)
	# The east bump the old tower stands on.
	land(12, -8, 18, -1, 0, 3)
	_checkpoint(Vector3(-2, 0, 10), Vector3.FORWARD)
	_sign("Hold Run to go faster. Crouch while running, then jump: a long jump.", Vector3(2, 0, 9))
	# The way up to the terrace: two slopes and a step.
	ramp(Vector3(-1, 0, -5), Vector3.FORWARD)
	land(-2, -10, 0, -6, 1, 1)
	ramp(Vector3(-1, 1, -9), Vector3.FORWARD)
	_coin_line(Vector3(-1, 0.4, -3), Vector3(-1, 1.9, -9.5), 4)
	_coin_ring(Vector3(4, 0, 4), 1.6, 8)
	# Big rocks with a chick on top.
	land(8, 5, 10, 7, 2, 2)
	land(10, 5, 11, 7, 1, 1)
	# Silver Rush: step on the button and grab eight silver coins in time.
	silver_button = add(PadButton.new(), Vector3(-6, 0, 5)) as PadButton
	silver_button.pressed.connect(_start_silver)
	_sign("Step on the button, then find eight silver coins before time runs out.", Vector3(-8, 0, 6.5))
	if found_stars.has("sunny/silver"):
		_star("sunny/silver", Vector3(-6, 1.2, 5))
		silver_button.down = true
	# Crabs.
	add(Crab.make(Vector3(4, 0, 0), 3.5), Vector3(2, 0, -1))
	add(Crab.make(Vector3(0, 0, 3), 3.0, 0.5), Vector3(-9, 0, -3))
	add(Pickup.make("heart"), Vector3(10.5, 0, 10.5))
	# Truffle the hog knows a thing or two.
	var truffle := Islander.make("animal-hog", "Truffle", [
		"Psst. Stars hide in odd places. Have you looked over the edge of the north cliff?",
		"The old tower? Kick off one wall, then the other. Up you go.",
		"The crabs here are grumpy. Jump on them and they pop right into coins.",
	], 0.4)
	truffle.facing = Vector3(0.5, 0, 1).normalized()
	add(truffle, Vector3(6, 0, -7.5))


# --- The north terrace and the course door -----------------------------------

func _terrace() -> void:
	land(-8, -22, 10, -10, 2, 5)
	_checkpoint(Vector3(-5, 2, -13), Vector3.BACK)
	var door := CourseDoor.new()
	door.course_id = "sawmill"
	door.facing = Vector3.BACK
	add(door, Vector3(3, 2, -18))
	_coin_line(Vector3(-6, 2, -19), Vector3(0, 2, -19), 4)
	# The secret ledge under the north cliff, with a spring back up.
	_sign("Something sparkles down below the cliff...", Vector3(6.5, 2, -21), Vector3.BACK)
	ledge(2, -26, 6, -23, -1.5)
	_star("sunny/ledge", Vector3(4.5, -1.3, -24.5))
	add(Spring.new(), Vector3(2.7, -1.5, -23.6))
	camera_zone(Vector3(1, -6, -27), Vector3(7, 0.2, -22.5), 180.0, 26.0, 8.0, false, 2)


# --- Pebble's hollow, to the west --------------------------------------------

func _hollow() -> void:
	land(-22, -6, -12, 10, -1, 3)
	_checkpoint(Vector3(-14, -1, 7), Vector3.LEFT)
	pebble = Islander.make("animal-penguin", "Pebble", [], 0.42)
	pebble.facing = Vector3.RIGHT
	pebble.on_talk = _talk_pebble
	add(pebble, Vector3(-18, -1, 2))
	var nest := Vector3(-18.6, -1, 3.2)
	var chick_spots := [Vector3(8, 2, -20), Vector3(9, 2, 6), Vector3(-26, 0, -1)]
	for i in 3:
		var c := Chick.new()
		c.home = nest + Vector3(i * 0.5, 0, 0.3 * i)
		if found_stars.has("sunny/chicks"):
			c.position = c.home
			c.is_home = true
		else:
			c.position = chick_spots[i]
		c.level = self
		add_child(c)
		c.found.connect(_on_chick_home)
		chicks.append(c)
	if found_stars.has("sunny/chicks"):
		chicks_home = 3
	# A floating rock out west where one chick got stuck.
	ledge(-27, -2, -25, 0, 0)
	# A crate pile with a hidden gem in the strong one.
	for at in [Vector3(-20.5, -1, -4.5), Vector3(-19.5, -1, -4.5), Vector3(-20.5, -1, -3.5)]:
		add(Breakable.make("crate", "coins:2"), at)
	add(Breakable.make("crate-strong", "gem:sunny/gem_crates"), Vector3(-21, -1, -2))
	# Far out to the south-west, a gem for long jumpers.
	ledge(-20, 14, -18, 16, -1)
	_gem("sunny/gem_far", Vector3(-19, -0.8, 15))
	_coin_line(Vector3(-19, -0.9, 10.5), Vector3(-19, -0.9, 13.5), 3)


func _talk_pebble() -> void:
	if chicks_home >= 3:
		speak("Pebble", ["My chicks are staying right here from now on. Thank you again!"])
	elif chicks_home == 0:
		speak("Pebble", [
			"Oh, my chicks! Three of them wandered off while I was napping.",
			"One went up the hill to the north, one is up on the big rocks, and one... out past the cliffs to the west.",
			"Could you find them? Just touch them and they'll hop home.",
		])
	else:
		speak("Pebble", ["%d of 3 home. Please find the rest!" % chicks_home])


func _on_chick_home(_c: Chick) -> void:
	chicks_home += 1
	if chicks_home < 3:
		say("%d of 3 chicks home" % chicks_home)
		return
	pebble.cheer()
	speak("Pebble", ["All three, safe and sound! Here, this was shining in the nest."], _give_chick_star)


func _give_chick_star() -> void:
	_star("sunny/chicks", pebble.position + Vector3(1.2, 0.4, 0.6))


# --- The old tower, to the east ----------------------------------------------

func _tower() -> void:
	# The tower, and a wall one square from it: kick between them to climb.
	land(13, -6, 15, -4, 7, 10)
	land(16, -6, 17, -4, 6.5, 9)
	_star("sunny/tower", Vector3(14, 7.2, -5))
	_sign("Jump at a wall, then jump again to kick off it.", Vector3(14, 0, -2.2))
	_coin_line(Vector3(15.5, 1.5, -5), Vector3(15.5, 5.5, -5), 4)
	camera_zone(Vector3(11, -1, -9), Vector3(19, 12, -1), 0.0, 16.0, 11.0, false, 1)


# --- Lookout Islet, across the Skyway ----------------------------------------

func _lookout() -> void:
	bridge = SkywayBridge.new()
	bridge.to = Vector3(10, 0, 0)
	add(bridge, Vector3(12, 0, 8))
	land(22, 2, 32, 14, 0, 3)
	_checkpoint(Vector3(23.5, 0, 6), Vector3.RIGHT)
	add(Crab.make(Vector3(0, 0, 4), 2.6), Vector3(26, 0, 4))
	add(Crab.make(Vector3(3, 0, 0), 2.2, 0.3), Vector3(25, 0, 11))
	for at in [Vector3(29.5, 0, 4), Vector3(30.3, 0, 5), Vector3(30.3, 0, 3.2)]:
		add(Breakable.make("crate", "coins:2"), at)
	add(Breakable.make("crate-item-strong", "star:sunny/crates"), Vector3(29, 0, 10.5))
	_sign("A crate too strong to break? Crouch in the air to ground pound.", Vector3(27, 0, 12.5), Vector3.LEFT)
	add(Pickup.make("heart"), Vector3(31, 0, 13))
	_coin_ring(Vector3(27, 0, 8), 1.4, 6)


# --- Silver Rush -------------------------------------------------------------

const SILVER_SPOTS := [
	Vector3(-10, 0, 10), Vector3(10, 0, -8), Vector3(-7, 2, -20), Vector3(9, 2, -12),
	Vector3(-21, -1, 9), Vector3(-15, -1, -5), Vector3(16, 0, -2), Vector3(2, 0, -8),
]


func _start_silver() -> void:
	if found_stars.has("sunny/silver") or not _silver.is_empty():
		return
	silver_left = SILVER_TIME
	_silver_got = 0
	for at in SILVER_SPOTS:
		var p := Pickup.make("silver")
		add(p, at + Vector3.UP * 0.2)
		p.collected.connect(_on_silver)
		_silver.append(p)
	say("Find eight silver coins!")


func _on_silver() -> void:
	_silver_got += 1
	if _silver_got >= SILVER_SPOTS.size():
		_silver.clear()
		silver_left = 0.0
		countdown.emit("", -1.0)
		_star("sunny/silver", silver_button.position + Vector3.UP * 1.2)
	else:
		say("%d of 8 silver coins" % _silver_got)


func _physics_process(delta: float) -> void:
	if _silver.is_empty():
		return
	silver_left -= delta
	countdown.emit("Silver coins %d/8" % _silver_got, maxf(silver_left, 0.0))
	if silver_left <= 0.0:
		for p in _silver:
			if is_instance_valid(p):
				p.queue_free()
		_silver.clear()
		countdown.emit("", -1.0)
		silver_button.release()
		say("Out of time. Step on the button to try again.")


# --- Scenery -----------------------------------------------------------------

func _scenery() -> void:
	for at in [Vector3(-10, 0, -8), Vector3(-9, 0, 0), Vector3(10, 0, 0), Vector3(-6, 2, -12), Vector3(8, 2, -14), Vector3(-16, -1, -4), Vector3(-21, -1, 8), Vector3(30, 0, 13)]:
		tree(at, "tree")
	for at in [Vector3(-11, 0, 4), Vector3(6, 2, -21), Vector3(-7, 2, -21), Vector3(11, 0, -9.0), Vector3(31, 0, 3)]:
		tree(at, "tree-pine")
	for at in [Vector3(-4, 0, 8), Vector3(5, 0, 10), Vector3(9, 0, 3), Vector3(-15, -1, 3), Vector3(25, 0, 9), Vector3(0, 2, -14)]:
		deco("flowers", at, fmod(at.x * 20.0, 360.0))
	for at in [Vector3(-8, 0, 9), Vector3(7, 0, 8), Vector3(-3, 0, 2), Vector3(-17, -1, 7), Vector3(4, 2, -12), Vector3(28, 0, 7)]:
		deco("grass", at, fmod(at.z * 33.0, 360.0), 1.4)
	for at in [Vector3(11, 0, 11), Vector3(-11.3, 0, -9.3), Vector3(-21, -1, -5.5)]:
		deco("rocks", at, 30.0, 1.5)
	for at in [Vector3(-5, 0, -1), Vector3(-17.5, -1, 0)]:
		deco("mushrooms", at, 0.0, 1.4)
	for x in range(-11, 12, 1):
		if absi(x) > 2:
			deco("fence-low-straight", Vector3(x + 0.5, 0, 11.9 - 0.3), 0.0)
