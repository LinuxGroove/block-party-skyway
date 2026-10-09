class_name StarFan
extends Node3D
## A big fan in a frame, its cog blades spinning, facing the way it blows:
## the look of a WindZone (scenery; the wind itself is the zone).
##
##   add(StarFan.make(Vector3.UP, 1.4), foot)
##
## An updraft's fan can show snowflakes rising up the column (`rise`).

## Which way it blows, along a grid axis.
var facing := Vector3.UP
var radius := 1.4
var speed := 360.0
## For an updraft: how high snowflakes rise above the fan, to show the
## column of air.
var rise := 0.0

var _blades: Node3D
var _flakes: Array[Node3D] = []


static func make(p_facing: Vector3, p_radius := 1.4) -> StarFan:
	var f := StarFan.new()
	f.facing = p_facing.normalized()
	f.radius = p_radius
	return f


func _ready() -> void:
	# The cogs lie flat; tip them to face along `facing`.
	var mount := Node3D.new()
	if absf(facing.x) > 0.5:
		mount.rotation_degrees.z = -90.0 * signf(facing.x)
	elif absf(facing.z) > 0.5:
		mount.rotation_degrees.x = 90.0 * signf(facing.z)
	add_child(mount)
	var frame := Kit.model("factory:cog-e", radius * 2.4)
	mount.add_child(frame)
	_blades = Node3D.new()
	_blades.position.y = 0.22 * radius * 2.4
	mount.add_child(_blades)
	var blades := Kit.model("factory:cog-b", radius * 1.9)
	_blades.add_child(blades)
	# Bright flakes, so they show against the night.
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(0.92, 0.96, 1.0)
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in int(rise * 1.5):
		var f := Kit.model("holiday:snowflake-%s" % ["a", "b", "c"][i % 3], 0.8)
		for m in f.find_children("*", "MeshInstance3D", true, false):
			(m as MeshInstance3D).material_override = white
		var turn := TAU * i * 0.382
		f.position = Vector3(cos(turn) * radius * 0.8, fmod(i * 0.67, rise), sin(turn) * radius * 0.8)
		add_child(f)
		_flakes.append(f)


func _process(delta: float) -> void:
	_blades.rotation_degrees.y += speed * delta
	for f in _flakes:
		f.position.y += 4.0 * delta
		if f.position.y > rise:
			f.position.y -= rise
		f.rotation.y += 2.0 * delta
