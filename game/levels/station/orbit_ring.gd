class_name OrbitRing
extends Level
## Course 4 of Star Station: platforms circling hubs in open space. Ride a
## ring across the first gap, a wheel up the face of a tower, then two
## rings that turn like gears: hop from one to the other where they meet,
## and over falling platforms to the flag.
##
## Adventure: coins, a heart, a hidden gem on the wheel's hub (drop onto it
## from the top instead of going on) and checkpoints; the flag gives the
## star. Speedrun: just the course and the clock.

const STAR := "station/orbitring"
const GEM := "station/gem_orbitring"
## The hubs: the first ring, the wheel, and the two gears.
const RING := Vector3(0, 0, -11)
const WHEEL := Vector3(0, 4.5, -26.5)
const GEAR_A := Vector3(0, 7.5, -41.5)
const GEAR_B := Vector3(0, 8.5, -51.5)
## Seconds for a lap of each.
const RING_LAP := 8.0
const WHEEL_LAP := 8.0
const GEAR_LAP := 7.0


func _init() -> void:
	super()
	title = "Orbit Ring"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 30.0, 10.0, false]


func build() -> void:
	# The start pad.
	land(-3, -4, 3, 4, 0, 3)
	StationDeco.panels(self, -3, -4, 3, 4, 0.0)
	add_sign("Platforms circle the hubs. Hop on, ride round, and jump off on the far side.", Vector3(-2, 0, 1.5))
	StationDeco.prop(self, "computer-system", Vector3(2.2, 0, 2.5), -90.0, 1.4)
	StationDeco.rail(self, Vector3(-3, 0, -3.8), Vector3(-1.6, 0, -3.8))
	StationDeco.rail(self, Vector3(1.6, 0, -3.8), Vector3(3, 0, -3.8))

	# The first ring: two big platforms, south to north across the gap.
	for ph in [0.55, 0.05]:
		add(StationOrbiter.make(4.0, RING_LAP, ph, Vector3(3, 0.4, 3)), RING)
	_hub(RING)
	coin_ring(RING + Vector3(0, 1.0, 0), 4.0, 8)

	# A deck, with a turret firing across it.
	land(-3, -24, 3, -18, 1.0, 3)
	StationDeco.panels(self, -3, -24, 3, -18, 1.0, "floor-panel-straight")
	add_checkpoint(Vector3(-2, 1.0, -18.8), Vector3.FORWARD)
	add(StationTurret.laser(Vector3.RIGHT, 1.8), Vector3(-2.4, 1.0, -21))
	add_coin(Vector3(0.5, 2.6, -21))

	# The wheel, up the face of the tower.
	for ph in [0.8, 0.3]:
		add(StationOrbiter.make_wheel(3.5, WHEEL_LAP, ph), WHEEL)
	_hub(WHEEL, true)
	_axle(WHEEL, -29.0)
	add_sign("The wheel carries you up. Jump off at the top!", Vector3(2.3, 1.0, -22.8), Vector3(-1, 0, 1).normalized())
	if not is_speedrun():
		# Off the racing line: drop onto the hub from the top.
		add_gem(GEM, WHEEL + Vector3(0, 0.75, 0))

	# The tower's top deck.
	land(-3, -36, 3, -29, 7.5, 10)
	StationDeco.panels(self, -3, -36, 3, -30, 7.5)
	add_checkpoint(Vector3(-2, 7.5, -30.5), Vector3.FORWARD)
	add_heart(Vector3(2, 7.5, -31))
	StationDeco.cargo(self, Vector3(-2.2, 7.5, -34.5), 2)
	StationDeco.prop(self, "computer-wide", Vector3(2.3, 7.5, -34.6), -90.0, 1.4)
	add_sign("These two turn like gears. Hop across where they meet.", Vector3(-2.2, 7.5, -32.5), Vector3(1, 0, 1).normalized())

	# The gears: they meet in the middle, both heading the same way.
	for ph in [0.2, 0.7]:
		add(StationOrbiter.make(4.0, GEAR_LAP, ph), GEAR_A)
		add(StationOrbiter.make(4.0, -GEAR_LAP, 1.0 - ph), GEAR_B)
	_hub(GEAR_A)
	_hub(GEAR_B)
	coin_line(Vector3(0, 9.0, -45.5), Vector3(0, 10.0, -47.5), 2)
	camera_zone(Vector3(-6, 4, -57), Vector3(6, 16, -36.5), 0.0, 44.0, 11.0)

	# Falling platforms to the flag.
	for z in [-59.0, -62.5]:
		add(FallingPlatform.make(Vector3(2, 0.4, 2), "platform", 0.7), Vector3(0, 8.5, z))
		add_coin(Vector3(0, 9.9, z))
	land(-4, -73, 4, -65, 8.5, 3)
	StationDeco.panels(self, -4, -73, 4, -65, 8.5, "floor-detail")
	add_flag(Vector3(0, 8.5, -69))
	for x in [-3.0, 3.0]:
		StationDeco.prop(self, "structure-barrier-high", Vector3(x, 8.5, -71.5), 0.0, 1.8)
	StationDeco.space(self)
	finish()


## A hub: a metal block with a glowing core, for the platforms to circle.
## A wheel's hub is solid (something to land on); a ring's sits below the
## platforms.
func _hub(at: Vector3, is_wheel := false) -> void:
	var ball := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.45
	s.height = 0.9
	ball.mesh = s
	ball.material_override = StationDeco.glow(Color("9fe3f0"))
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if is_wheel:
		piece("block-grass", at + Vector3(0, -0.5, 0))
		solid(at + Vector3(-0.5, -0.5, -0.5), at + Vector3(0.5, 0.5, 0.5))
		ball.position = at + Vector3(0, 0, 0.55)
	else:
		piece("block-grass", at + Vector3(0, -2.4, 0))
		ball.position = at + Vector3(0, -1.0, 0)
	add_child(ball)


## A thick bar from a wheel's hub north to the tower face at `z`.
func _axle(at: Vector3, z: float) -> void:
	var m := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = 0.3
	c.bottom_radius = 0.3
	c.height = absf(z - at.z)
	m.mesh = c
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("8b93a8")
	mat.metallic = 0.5
	mat.roughness = 0.4
	m.material_override = mat
	m.rotation_degrees = Vector3(90, 0, 0)
	m.position = Vector3(at.x, at.y, (at.z + z) / 2.0)
	add_child(m)
