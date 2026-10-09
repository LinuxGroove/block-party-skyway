class_name GearsBigCog
extends Node3D
## A giant cog stood on its edge, turning slowly: scenery for Gear Works,
## off the path (it has no collision).
##
##   add(GearsBigCog.make(6.0, 90.0), at)    # 6 m across, its face turned to look east

## Metres across.
var size := 6.0
## Which way its face looks, in degrees (0 looks south, 90 east).
var turn := 0.0
## Degrees a second it turns; negative turns the other way.
var speed := 12.0
var model_name := "factory:cog-a"

var _wheel: Node3D


static func make(p_size := 6.0, p_turn := 0.0, p_speed := 12.0, p_model := "factory:cog-a") -> GearsBigCog:
	var c := GearsBigCog.new()
	c.size = p_size
	c.turn = p_turn
	c.speed = p_speed
	c.model_name = p_model
	return c


func _ready() -> void:
	rotation_degrees.y = turn
	_wheel = Node3D.new()
	_wheel.position.y = size / 2.0
	add_child(_wheel)
	var m := Kit.model(model_name)
	m.scale = Vector3(size, size * 0.8, size)
	m.rotation_degrees.x = 90.0
	_wheel.add_child(m)
	var hub := Kit.model("factory:piston-round")
	hub.scale = Vector3(size * 0.18, size * 0.3, size * 0.18)
	hub.rotation_degrees.x = 90.0
	hub.position.z = -size * 0.15
	_wheel.add_child(hub)


func _process(delta: float) -> void:
	_wheel.rotation_degrees.z += speed * delta
