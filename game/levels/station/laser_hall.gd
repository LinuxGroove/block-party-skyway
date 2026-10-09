class_name LaserHall
extends Level
## Course 2 of Star Station: a hall through the station. Three laser gates
## that blink in a wave, turrets firing bolts across the floor, crushers
## slamming down, then round the corner east past two more gates and a
## wave of spikes to the flag. The camera turns east with the hall.
##
## Adventure: coins, a heart, a hidden gem on a ledge outside the west wall
## (hop off a turret and over; a spring comes back) and checkpoints; the
## flag gives the star. Speedrun: just the course and the clock.

const STAR := "station/laserhall"
const GEM := "station/gem_laserhall"
## Every gate is on for ON and off for OFF seconds.
const ON := 1.0
const OFF := 1.5


func _init() -> void:
	super()
	title = "Laser Hall"
	spawn = Vector3(0, 0, 2)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 42.0, 10.0, false]


func build() -> void:
	# The hall's floor, north then east.
	land(-3, -46, 3, 4, 0, 3)
	land(3, -46, 42, -40, 0, 3)
	StationDeco.panels(self, -3, -46, 3, 4, 0.0, "floor-panel-straight")
	StationDeco.panels(self, 3, -46, 41, -40, 0.0, "floor-panel-straight")
	var walls := ["wall", "wall-window", "wall", "wall-pillar"]
	StationDeco.wall(self, Vector3(-3, 0, 4), Vector3(-3, 0, -46), Vector3.RIGHT, walls)
	StationDeco.wall(self, Vector3(3, 0, 4), Vector3(3, 0, -40), Vector3.LEFT, walls)
	StationDeco.wall(self, Vector3(-3, 0, -46), Vector3(42, 0, -46), Vector3.BACK, walls)
	StationDeco.wall(self, Vector3(3, 0, -40), Vector3(42, 0, -40), Vector3.FORWARD, walls)
	# The hall's open end, so the camera can see in.
	StationDeco.rail(self, Vector3(-3, 0, 3.8), Vector3(3, 0, 3.8))
	solid(Vector3(-3, 0, 3.8), Vector3(3, 1.2, 4.0))
	add_sign("Laser gates blink on and off. Wait until they're off, then run through!", Vector3(-2, 0, 1.2))
	StationDeco.prop(self, "computer-wide", Vector3(2.2, 0, 2.6), -90.0, 1.4)

	# Three gates, one after another in a wave: run with it.
	for i in 3:
		add(StationLaserGate.make(6.0, ON, OFF, fposmod(-i * 0.222, 1.0)), Vector3(0, 0, -8.0 - i * 4.0))
	for z in [-10.0, -14.0]:
		add_coin(Vector3(0.5, 0.6, z))
	add_checkpoint(Vector3(-2, 0, -18.5), Vector3.FORWARD)

	# Turrets fire bolts across the floor: jump them.
	for z in [-23.0, -27.0]:
		add(StationTurret.laser(Vector3.RIGHT, 1.6, 0.5 if z < -25.0 else 0.0), Vector3(-2.1, 0, z))
	add_sign("Turrets fire bolts across the hall. Jump over them!", Vector3(2.2, 0, -19.5), Vector3(-1, 0, 1).normalized())
	for z in [-23.0, -27.0]:
		add_coin(Vector3(0.5, 1.8, z))
	if not is_speedrun():
		# Off the racing line: a ledge outside the west wall. Hop off a
		# turret and over; the spring comes back.
		ledge(-7, -27, -3, -22, -1.0)
		add_gem(GEM, Vector3(-5.6, -0.8, -24.5))
		add_heart(Vector3(-5.6, -1.0, -26))
		add(Spring.new(), Vector3(-4.2, -1.0, -23))

	# Crushers slam down across the hall: wait, then dash under.
	for i in 2:
		var c := Crusher.make(2.6, Vector3(6, 1, 2), i * 0.18)
		add(c, Vector3(0, 0, -33.0 - i * 3.5))
	add_sign("Crushers! Wait for them to go up, then dash underneath.", Vector3(-2.2, 0, -30.2), Vector3(1, 0, 1).normalized())

	# The corner, then east.
	camera_zone(Vector3(-4, -4, -50), Vector3(46, 12, -38.5), 270.0, 40.0, 10.0)
	add_checkpoint(Vector3(-2, 0, -44.5), Vector3.RIGHT)
	for i in 2:
		add(StationLaserGate.make(6.0, 0.9, 1.3, fposmod(-i * 0.25, 1.0), Vector3.BACK), Vector3(9.0 + i * 5.0, 0, -43))
	add_coin(Vector3(11.5, 0.6, -43))
	for row in 3:
		for k in 5:
			add(SpikeTrap.make(row * 0.18), Vector3(20.0 + row * 2.0, 0, -45.0 + k))
	add_coin(Vector3(22, 2.2, -43))
	add_heart(Vector3(16.5, 0, -45.2))

	# The finish.
	add_flag(Vector3(36, 0, -43), Vector3.RIGHT)
	for z in [-45.3, -40.7]:
		StationDeco.prop(self, "computer-system", Vector3(40, 0, z + (0.4 if z < -43 else -0.4)), 180.0, 1.4)
	StationDeco.space(self)
	finish()
