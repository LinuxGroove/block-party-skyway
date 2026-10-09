class_name GearsFan
extends Node3D
## A floor fan in Gear Works: a spinning cog in a low ring that blows an
## updraft (a WindZone) straight up. Step over it and the air lifts you;
## steer out of the top onto a ledge.
##
##   add(GearsFan.make(6.0), at)    # at is the fan's foot, on the floor

var level: Level
## How high the air column reaches, and how wide it is.
var height := 6.0
var width := 2.0
## Upward push in m/s² (about 40 beats gravity and lifts).
var power := 42.0

var wind: WindZone
var _blades: Node3D


static func make(p_height := 6.0, p_power := 42.0, p_width := 2.0) -> GearsFan:
	var f := GearsFan.new()
	f.height = p_height
	f.power = p_power
	f.width = p_width
	return f


func _ready() -> void:
	var ring := Kit.model("pipe")
	ring.scale = Vector3(width * 1.1, 0.5, width * 1.1)
	add_child(ring)
	_blades = Kit.model("factory:cog-c", width * 0.95)
	_blades.position.y = 0.16
	add_child(_blades)
	wind = WindZone.make(Vector3(width, height, width), Vector3.UP * power)
	wind.level = level
	add_child(wind)


func _process(delta: float) -> void:
	_blades.rotation.y += delta * 9.0
