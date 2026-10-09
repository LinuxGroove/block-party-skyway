class_name StationIsle
extends Island
## Star Station, King Thud's home above the clouds, for Adventure: the main
## deck where the hero lands, the moon deck to the west (moon gravity), the
## garden to the south-west, the comms mast and a guarded catwalk to the
## east, the terrace with two course doors to the north, and King
## Thud's door up the stairs beyond it. A hangar hides under the deck.
##
## Stars: Sprocket's fuses (a request), the Star Dust Rush (silver coins
## against the clock), the top of the comms mast (a vent, then wall kicks),
## the hidden hangar under the deck (a secret), and catching Comet the
## runaway bunny (a chase). Two hidden gems: in a strong crate by King
## Thud's door, and on an asteroid far off the moon deck.

const DUST_TIME := 40.0
const FUSE_HOME := Vector3(6.2, 0.66, 5.4)

var sprocket: Islander
var fuses: Array[StationFuse] = []
var fuses_home := 0
var comet: StationRunaway
var dust: SilverRush
var boss_door: BossDoor
var moon: StationGravity


func _init() -> void:
	super()
	title = "Star Station"
	spawn = Vector3(0, 0, 15)
	spawn_facing = Vector3.FORWARD


func build() -> void:
	_main_deck()
	_hangar()
	_terrace()
	_throne_deck()
	_moon_deck()
	_garden()
	_east_deck()
	_scenery()
	StationDeco.space(self)
	finish()


## Extra views for the screenshots.
func shots() -> Array:
	return [
		{"name": "mast", "at": Vector3(17, 0, -1), "face": Vector3(0.6, 0, -1)},
		{"name": "moon", "at": Vector3(-16, -1, 2), "face": Vector3.LEFT},
		{"name": "throne", "at": Vector3(0, 2, -20), "face": Vector3.FORWARD},
	]


# --- The main deck (where the hero lands) ------------------------------------

func _main_deck() -> void:
	# In strips, to leave the hangar's hatch (x 10..12, z 10..12) and the
	# notch its vent blows out of (x 12..14, z 16..18).
	land(-14, -14, 14, 10, 0, 3)
	land(-14, 10, 10, 12, 0, 3)
	land(12, 10, 14, 12, 0, 3)
	land(-14, 12, 14, 16, 0, 3)
	land(-14, 16, 12, 18, 0, 3)
	StationDeco.panels(self, -12, -12, 8, 8, 0.0)
	add_checkpoint(Vector3(-2.5, 0, 16), Vector3.FORWARD)
	add_sign("Welcome to Star Station, King Thud's home in the sky. His door is up the stairs to the north.", Vector3(2.5, 0, 15.5))
	coin_ring(Vector3(0, 0, 9), 1.8, 8)
	coin_line(Vector3(0, 0.4, -6), Vector3(0, 1.9, -13), 4)
	# Sprocket the engineer and his fuse box.
	sprocket = Islander.make("animal-koala", "Sprocket", [], 0.42)
	sprocket.facing = Vector3(-0.4, 0, 1).normalized()
	sprocket.on_talk = _talk_sprocket
	add(sprocket, Vector3(4.6, 0, 6.2))
	StationDeco.prop(self, "table", Vector3(6.8, 0, 5.4), 0.0, 1.6, Vector3(1.8, 0.64, 1.0))
	StationDeco.prop(self, "computer-wide", Vector3(4.2, 0, 4.4), 0.0, 1.6, Vector3(1.3, 0.8, 0.8))
	StationDeco.prop(self, "computer-screen", Vector3(8.6, 0, 5.0), -90.0, 1.6, Vector3(0.8, 1.0, 1.3))
	_fuses()
	# Star Dust Rush: step on the button, grab the silver coins in time.
	dust = add_silver_rush("station/dust", Vector3(-6, 0, 13), DUST_SPOTS, DUST_TIME)
	add_sign("Step on the button, then find eight silver coins all over the station before time runs out.", Vector3(-8.5, 0, 14), Vector3(0.5, 0, 1).normalized())
	# The galley, with Dumpling the cook.
	var dumpling := Islander.make("animal-panda", "Dumpling", [
		"Hungry? The galley's always open. Well, the kettle is.",
		"I dropped a spoon down a hatch behind the cargo by the east edge. It clanged a long way down...",
		"The comms mast? Ride the vent up to the balcony, then kick between the walls to the top.",
	], 0.42)
	dumpling.facing = Vector3(1, 0, 0.3).normalized()
	add(dumpling, Vector3(-10, 0, -1))
	for at in [Vector3(-8.5, 0, -3.5), Vector3(-8.5, 0, 1.5)]:
		StationDeco.prop(self, "table-large", at, 0.0, 1.6, Vector3(2.2, 0.64, 1.4))
		for s in [-1.0, 1.0]:
			piece("station:chair-cushion-headrest", at + Vector3(0, 0, s * 1.15), 0.0 if s > 0 else 180.0, 1.6)
	# Space monkeys.
	add(Critter.make("animal-monkey", Vector3(6, 0, 0), 4.0), Vector3(-4, 0, -9))
	add(Critter.make("animal-monkey", Vector3(0, 0, 5), 3.5, 0.5), Vector3(10.5, 0, -10))
	add_heart(Vector3(-12, 0, 16.5))


## The three fuses Sprocket lost: on the moon deck's top asteroid, on a
## stack of cargo on the terrace, and out on the catwalk past the east deck.
func _fuses() -> void:
	var done := found_stars.has("station/fuses")
	var spots := [Vector3(-30, 6.5, 0), Vector3(10.5, 4.1, -17.5), Vector3(42, 0, 4.8)]
	for i in 3:
		var f := StationFuse.new()
		f.home = FUSE_HOME + Vector3(i * 0.55, 0, 0)
		if done:
			f.position = f.home
			f.is_home = true
		else:
			f.position = spots[i]
		f.level = self
		add_child(f)
		f.found.connect(_on_fuse_home)
		fuses.append(f)
	if done:
		fuses_home = 3


func _talk_sprocket() -> void:
	if fuses_home >= 3:
		speak("Sprocket", ["Every light on the station is on again. Thanks to you!"])
	elif fuses_home == 0:
		speak("Sprocket", [
			"Oh no, oh no. King Thud pulled the station's three fuses and threw them about!",
			"One's up on the asteroids over the moon deck, one's on the cargo on the terrace, and one's out on the catwalk past the east deck.",
			"Touch them and they'll zip straight back here.",
		])
	else:
		speak("Sprocket", ["%d of 3 fuses back. Two more lights to go... well, %d." % [fuses_home, 3 - fuses_home]])


func _on_fuse_home(_f: StationFuse) -> void:
	fuses_home += 1
	if fuses_home < 3:
		say("%d of 3 fuses back" % fuses_home)
		return
	sprocket.cheer()
	speak("Sprocket", ["All three! The lights are back on. And look what was stuck in the fuse box..."], _give_fuse_star)


func _give_fuse_star() -> void:
	add_star("station/fuses", sprocket.position + Vector3(-1.2, 0.4, 0.8))


# --- The hidden hangar, under the deck ---------------------------------------

func _hangar() -> void:
	# Cargo hides the hatch on three sides; the east side is open.
	for at in [Vector3(9.5, 0, 9.5), Vector3(9.5, 0, 11), Vector3(9.5, 0, 12.5), Vector3(11, 0, 9.5), Vector3(11, 0, 12.5)]:
		StationDeco.cargo(self, at, 2)
	# The hangar floor, its walls, a little ship and some lights.
	land(4, 8, 14, 18, -7, 1)
	StationDeco.wall(self, Vector3(4, -7, 8.15), Vector3(14, -7, 8.15), Vector3.BACK, ["wall", "wall-window", "wall-pillar"], 2.0, true)
	StationDeco.wall(self, Vector3(4, -5, 8.15), Vector3(14, -5, 8.15), Vector3.BACK, ["wall"], 2.0, false)
	StationDeco.wall(self, Vector3(4.15, -7, 8), Vector3(4.15, -7, 18), Vector3.RIGHT, ["wall", "wall-door", "wall"], 2.0, true)
	StationDeco.wall(self, Vector3(4.15, -5, 8), Vector3(4.15, -5, 18), Vector3.RIGHT, ["wall"], 2.0, false)
	add_star("station/hangar", Vector3(6, -6.8, 10.5))
	piece("station:container-flat", Vector3(8, -7, 14.5), 90.0, 2.4)
	piece("station:structure-barrier", Vector3(8, -7, 14.5), 0.0, 1.8)
	StationDeco.prop(self, "computer-system", Vector3(5.2, -7, 15.5), 180.0, 1.6, Vector3(1.0, 1.0, 1.2))
	coin_line(Vector3(11, -6.9, 14), Vector3(11, -6.9, 16.5), 3)
	add_heart(Vector3(6, -7, 16.5))
	for at in [Vector3(7, -4, 12), Vector3(11, -4, 15)]:
		var lamp := OmniLight3D.new()
		lamp.light_color = Color("ffe0b0")
		lamp.light_energy = 1.4
		lamp.omni_range = 7.0
		lamp.position = at
		add_child(lamp)
	# The vent back up, through the notch in the deck's corner.
	add(WindZone.make(Vector3(2, 6.5, 2), Vector3.UP * 55.0), Vector3(13, -7, 17))
	piece("station:structure-panel", Vector3(13, -7, 17), 0.0, 2.2)
	camera_zone(Vector3(3, -8, 7), Vector3(15, -3.2, 19), 0.0, 12.0, 7.0, false, 2)


# --- The north terrace and two course doors ----------------------------------

func _terrace() -> void:
	land(-12, -28, 12, -14, 2, 5)
	StationDeco.panels(self, -10, -26, 10, -16, 2.0, "floor-panel-straight")
	# Stairs up from the main deck.
	ramp(Vector3(0, 0, -9), Vector3.FORWARD)
	land(-1, -14, 1, -10, 1, 1)
	ramp(Vector3(0, 1, -13), Vector3.FORWARD)
	for x in [-1.25, 1.25]:
		for z in [-9.0, -11.0, -13.0]:
			piece("station:stairs-handrail-single", Vector3(x, 0.0 if z > -10.0 else 1.0, z), 0.0, 2.0)
	add_checkpoint(Vector3(-3, 2, -16), Vector3.FORWARD)
	add_course_door("laserhall", Vector3(-7, 2, -25))
	add_course_door("orbitring", Vector3(7, 2, -25))
	coin_line(Vector3(-4, 2, -20), Vector3(4, 2, -20), 5)
	# The cargo the second fuse sits on: a step, then the tall stack.
	StationDeco.cargo(self, Vector3(8.5, 2, -16.5), 1)
	StationDeco.cargo(self, Vector3(10.5, 2, -17.5), 2)
	StationDeco.cargo(self, Vector3(-10.5, 2, -16), 2)
	add(Critter.make("animal-monkey", Vector3(0, 0, -5), 3.6), Vector3(-10, 2, -20))
	var tusk := Islander.make("animal-elephant", "Commander Tusk", [
		"King Thud has locked himself in his throne room up those stairs, with every star in the sky.",
		"His door opens for five of this station's stars. Then it's you and him.",
		"He hops, he slams, he gets dizzy. That's when you strike. Good luck, astronaut.",
	], 0.42)
	tusk.facing = Vector3.BACK
	add(tusk, Vector3(2.6, 2, -23.5))


# --- King Thud's deck and door -----------------------------------------------

func _throne_deck() -> void:
	# A bridge of stairs over the gap up to his deck.
	ramp(Vector3(0, 2, -27), Vector3.FORWARD)
	land(-1, -32, 1, -28, 3, 1)
	ramp(Vector3(0, 3, -31), Vector3.FORWARD)
	land(-7, -44, 7, -32, 4, 4)
	StationDeco.panels(self, -6, -42, 6, -34, 4.0, "floor-detail")
	StationDeco.wall(self, Vector3(-7, 4, -43.7), Vector3(7, 4, -43.7), Vector3.BACK, ["wall-window-banner", "wall-banner", "wall-pillar-banner", "wall-banner", "wall-window-banner"], 2.8, true)
	boss_door = add_boss_door(Vector3(0, 4, -40))
	add_checkpoint(Vector3(3.5, 4, -34), Vector3.FORWARD)
	# A strong crate with a gem, and some easy ones.
	add(Breakable.make("crate-strong", "gem:station/gem_crate"), Vector3(-5.6, 4, -42.3))
	for at in [Vector3(-5.6, 4, -40.8), Vector3(-4.3, 4, -42.3)]:
		add(Breakable.make("crate", "coins:2"), at)
	add_sign("A crate too strong to break? Crouch in the air to ground pound it.", Vector3(-3.5, 4, -37.5), Vector3(0.5, 0, 1).normalized())
	add_heart(Vector3(5.6, 4, -42.5))
	for x in [-6.0, 6.0]:
		piece("station:structure-barrier-high", Vector3(x, 4, -34.5), 0.0, 2.0)


# --- The moon deck, to the west (moon gravity) -------------------------------

func _moon_deck() -> void:
	land(-34, -12, -14, 10, -1, 3, "snow")
	moon = StationGravity.make(Vector3(38, 20, 23), 0.5)
	moon.motes_from = 5.0
	add(moon, Vector3(-33, -6, -1.5))
	add_sign("Moon gravity on this deck: jumps go higher and float longer.", Vector3(-15.8, -1, 4), Vector3.RIGHT)
	add_checkpoint(Vector3(-17, -1, 7), Vector3.LEFT)
	add_course_door("moonhop", Vector3(-24, -1, -10.5))
	# Asteroids rising to the first fuse.
	ledge(-22, 3, -19, 6, 1.5)
	ledge(-27, 2, -24, 5, 4.0)
	ledge(-31, -1, -29, 1, 6.5)
	for at in [Vector3(-20.5, 1.5, 4.5), Vector3(-25.5, 4.0, 3.5), Vector3(-30, 6.5, 0)]:
		piece("station:rocks", at + Vector3(0.6, 0, -0.4), 30.0, 1.2)
	coin_line(Vector3(-20.5, 2.0, 4.5), Vector3(-25.5, 4.5, 3.5), 3)
	# Far out west, an asteroid with a gem, for a moon long jump.
	ledge(-48, -6, -45, -2, 0.5)
	add_gem("station/gem_asteroid", Vector3(-46.5, 0.7, -4))
	piece("station:rocks", Vector3(-46, 0.5, -5.2), 70.0, 1.3)
	coin_line(Vector3(-37, 1.5, -4), Vector3(-42.5, 2.5, -4), 3)
	# Craters and moon rocks.
	for at in [Vector3(-30, -1, 6), Vector3(-19, -1, -6), Vector3(-26, -1, -3)]:
		piece("station:skip-rocks", at, fmod(at.x * 40.0, 360.0), 1.6)
	for at in [Vector3(-32, -1, -9), Vector3(-17, -1, -10), Vector3(-29, -1, 8.5), Vector3(-22, -1, 8)]:
		piece("station:rocks", at, fmod(at.z * 30.0, 360.0), 1.5)
	# Space fish, floating.
	for spec in [[Vector3(-27, -1, -6), Vector3(5, 0, 0), 5.0], [Vector3(-22, -1, 1), Vector3(0, 0, -5), 4.5]]:
		var fish := Critter.make("animal-fish", spec[1], spec[2], 0.0, 0.34)
		fish.bob = 0.4
		add(fish, spec[0])
	add_heart(Vector3(-33, -1, 8.5))


# --- The garden, to the south-west -------------------------------------------

func _garden() -> void:
	land(-30, 10, -14, 26, 0, 3)
	StationDeco.panels(self, -28, 12, -16, 24, 0.0, "floor")
	# Low walls round Comet's patch, open to the east.
	var low := ["wall", "wall-window"]
	StationDeco.wall(self, Vector3(-28, 0, 12), Vector3(-16, 0, 12), Vector3.BACK, low, 1.2, true)
	StationDeco.wall(self, Vector3(-28, 0, 24), Vector3(-16, 0, 24), Vector3.FORWARD, low, 1.2, true)
	StationDeco.wall(self, Vector3(-28, 0, 12), Vector3(-28, 0, 24), Vector3.RIGHT, low, 1.2, true)
	StationDeco.wall(self, Vector3(-16, 0, 12), Vector3(-16, 0, 15.6), Vector3.LEFT, low, 1.2, true)
	StationDeco.wall(self, Vector3(-16, 0, 20.4), Vector3(-16, 0, 24), Vector3.LEFT, low, 1.2, true)
	for at in [Vector3(-25, 0, 15), Vector3(-25, 0, 21), Vector3(-19.5, 0, 21.5)]:
		StationDeco.prop(self, "table-inset", at, 0.0, 1.6, Vector3(1.9, 0.6, 1.1))
		for dx in [-0.5, 0.0, 0.5]:
			deco("flowers-tall", at + Vector3(dx, 0.62, 0), fmod(at.x * 50.0 + dx * 90.0, 360.0), 0.9)
	for at in [Vector3(-27, 0, 18), Vector3(-21, 0, 13.3), Vector3(-17, 0, 23)]:
		deco("plant", at, fmod(at.z * 40.0, 360.0), 1.6)
	comet = StationRunaway.new()
	comet.bounds = AABB(Vector3(-27, 0, 13), Vector3(10, 1, 10))
	comet.level = self
	comet.position = Vector3(-21, 0, 18)
	add_child(comet)
	comet.caught.connect(_on_comet_caught)
	if found_stars.has("station/comet"):
		comet.is_caught = true
	var clover := Islander.make("animal-cow", "Clover", [
		"Comet, my bunny, hopped out of her hutch again. She's ever so quick!",
		"You'll never catch her walking. Run, and corner her against the wall.",
	], 0.42)
	clover.facing = Vector3.LEFT
	add(clover, Vector3(-14.8, 0, 22))
	add_checkpoint(Vector3(-15, 0, 24.6), Vector3.LEFT)


func _on_comet_caught() -> void:
	if found_stars.has("station/comet"):
		return
	speak("Clover", ["You caught her! She'd been carrying this about in her pouch."], _give_comet_star)


func _give_comet_star() -> void:
	add_star("station/comet", comet.position + Vector3(0, 0.6, 0))


# --- The east deck: the comms mast and the catwalk ---------------------------

func _east_deck() -> void:
	land(14, -12, 30, 6, 0, 3)
	StationDeco.panels(self, 16, -12, 30, -2, 0.0, "floor-panel-straight")
	add_checkpoint(Vector3(16, 0, -3), Vector3.RIGHT)
	add_course_door("ventclimb", Vector3(16.5, 0, -10.5))
	# The comms mast: a vent up to the balcony, then kick up between the mast
	# and the wall beside it.
	land(23, -9, 25, -7, 10, 13)
	land(26, -9, 27, -7, 11.5, 14.5)
	ledge(22, -7, 27, -5, 5.5)
	ledge(25, -9, 26, -7, 5.5)
	add(WindZone.make(Vector3(2, 5, 2), Vector3.UP * 50.0), Vector3(20, 0, -6))
	piece("station:structure-panel", Vector3(20, 0, -6), 0.0, 2.2)
	add_star("station/mast", Vector3(24, 10.2, -8))
	for y in [2.0, 4.0, 7.0, 9.0]:
		piece("station:structure", Vector3(24, y, -8), 0.0, 2.0)
	add_sign("Vents blow you upwards. Step in, ride up, then steer to a ledge.", Vector3(18.5, 0, -3.5), Vector3(0.3, 0, 1).normalized())
	coin_line(Vector3(20, 1.5, -6), Vector3(20, 4.5, -6), 3)
	camera_zone(Vector3(18, -1, -12), Vector3(30, 14, -3), 0.0, 16.0, 11.0, false, 1)
	var chaser := Critter.chaser("animal-monkey", 4.0, 2.6)
	add(chaser, Vector3(27, 0, -1))
	# The catwalk out to the third fuse, past a laser gate and a turret.
	ledge(30, 2, 40, 4, 0)
	land(40, 0, 45, 6, 0, 2)
	StationDeco.rail(self, Vector3(30, 0, 1.9), Vector3(40, 0, 1.9))
	add(StationLaserGate.make(2.0, 1.1, 1.5, 0.0, Vector3.BACK), Vector3(33.5, 0, 3))
	add(StationTurret.laser(Vector3.LEFT, 2.0), Vector3(44, 0, 3))
	add_sign("Laser gates blink. Wait until they're off, then run through. Jump the turret's bolts.", Vector3(28.8, 0, 1.2), Vector3(1, 0, 1).normalized())
	add_heart(Vector3(44, 0, 5))


# --- Star Dust Rush ----------------------------------------------------------

const DUST_SPOTS := [
	Vector3(-12, 0, -12), Vector3(12.5, 0, 6), Vector3(-24, -1, 6), Vector3(-32, -1, -10),
	Vector3(10, 2, -26), Vector3(-10, 2, -20), Vector3(21, 0, -2), Vector3(-20, 0, 20.5),
]


# --- Scenery -----------------------------------------------------------------

func _scenery() -> void:
	add_skyway_gate("castle", Vector3(-9, 0, 16.6), Vector3.FORWARD)
	StationDeco.rail(self, Vector3(-14, 0, 17.8), Vector3(-11, 0, 17.8))
	StationDeco.rail(self, Vector3(-7, 0, 17.8), Vector3(12, 0, 17.8))
	for at in [Vector3(-12.5, 0, -12.5), Vector3(12.5, 0, -12.5), Vector3(12.5, 0, 2)]:
		StationDeco.cargo(self, at, 2)
	for at in [Vector3(-12.6, 0, 6), Vector3(12.6, 0, -5)]:
		StationDeco.prop(self, "computer-system", at, 90.0 if at.x < 0 else -90.0, 1.6, Vector3(1.0, 1.0, 1.2))
	for at in [Vector3(-13, 0, 10), Vector3(13, 0, -1)]:
		piece("station:structure-barrier-high", at, 0.0, 2.0)
	for at in [Vector3(-11, 2, -27), Vector3(11, 2, -27)]:
		piece("station:structure-barrier-high", at, 0.0, 2.4)
	for at in [Vector3(-3, 0, 4), Vector3(3, 0, -4)]:
		deco("station:display-wall-wide", at, 0.0, 1.6)
	# The station's planet globe in the middle of the main deck.
	StationDeco.prop(self, "table-display", Vector3(0, 0, 0.5), 0.0, 2.4, Vector3(2.8, 0.8, 1.8))
	var globe := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.55
	ball.height = 1.1
	globe.mesh = ball
	globe.material_override = StationDeco.glow(Color("8f7bf0"), 0.85)
	globe.position = Vector3(0, 1.35, 0.5)
	add_child(globe)
	# Masts with lamps round the decks.
	for at in [Vector3(-13.5, 0, -13.5), Vector3(13.5, 0, -13.5), Vector3(13.5, 0, 15.5), Vector3(-11.5, 2, -27.5), Vector3(11.5, 2, -22), Vector3(29.5, 0, -11.5), Vector3(-29, 0, 25.3)]:
		StationDeco.beacon(self, at, 7 if at.y > 1.0 else 6)
