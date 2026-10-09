class_name GearsPressArena
extends BossArena
## The Big Press's arena: a square steel deck under a gantry, with
## The Big Press hanging from it. Hearts in the corners; fall off the edge
## and you're back at the flag by the entrance.

const SIZE := 12

var press: GearsBigPress


func _init() -> void:
	super()
	title = "The Big Press"
	spawn = Vector3(0, 0, 9.5)
	spawn_facing = Vector3.FORWARD
	star_spot = Vector3(0, 1.2, 0)
	# Further back and lower than most arenas, so the press shows overhead.
	camera_base = [0.0, 30.0, 14.0, true]


func build() -> void:
	land(-SIZE, -SIZE, SIZE, SIZE, 0, 4)
	add_checkpoint(Vector3(-1.5, 0, 10.5), Vector3.FORWARD)
	for at in [Vector3(-9.5, 0, -9.5), Vector3(9.5, 0, -9.5), Vector3(-9.5, 0, 9.5), Vector3(9.5, 0, 9.5)]:
		add_heart(at)
	_gantry()
	_floor_marks()
	press = add_boss(GearsBigPress.new(), Vector3(0, 0, 0)) as GearsBigPress
	press.reach = SIZE - 3.0
	finish()


## Four yellow posts at the corners hold two rails the press's bridge runs
## along.
func _gantry() -> void:
	var top := GearsBigPress.GANTRY_Y
	for x in [-SIZE, SIZE - 1]:
		for z in [-SIZE, SIZE - 1]:
			land(x, z, x + 1, z + 1, top, int(top), "snow")
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("#4b5563")
	steel.roughness = 0.6
	for z in [-SIZE + 0.5, SIZE - 0.5]:
		var rail := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(SIZE * 2.0, 0.6, 0.7)
		rail.mesh = bm
		rail.material_override = steel
		rail.position = Vector3(0, top + 0.3, z)
		add_child(rail)


## Dark plates and hazard marks on the deck, and machines round the edge.
func _floor_marks() -> void:
	for x in range(-SIZE + 2, SIZE - 1, 4):
		for z in range(-SIZE + 2, SIZE - 1, 4):
			deco("factory:top-large", Vector3(x, 0.01, z), 0.0, 1.0)
	for x in [-6.0, 6.0]:
		add(GearsBigCog.make(6.0, 90.0, 8.0), Vector3(-SIZE - 0.7 if x < 0 else SIZE + 0.7, -3.0, x))
		add(GearsBigCog.make(5.0, 0.0, -10.0, "factory:cog-b"), Vector3(x, -2.5, -SIZE - 0.7))
	for at in [Vector3(-11.2, 0, -4), Vector3(-11.2, 0, 4), Vector3(11.2, 0, -4), Vector3(11.2, 0, 4)]:
		piece("factory:machine", at, 90.0 if at.x < 0 else -90.0, 1.2)
	for at in [Vector3(-4, 0, -11.3), Vector3(4, 0, -11.3)]:
		piece("factory:hopper-high-round", at, 0.0, 1.2)
	for x in [-3.0, 3.0]:
		deco("factory:warning-traffic", Vector3(x, 0, 11.4), 0.0, 1.3)
