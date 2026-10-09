class_name SunnyWindmill
extends Node3D
## A windmill for Sunny Isles' hills: a round wooden body, a little roof and
## four sails that turn slowly in the breeze. Scenery with a solid body; the
## sails turn high out of reach.

var level: Level
## Which way the sails face.
var facing := Vector3.BACK
## Degrees a second the sails turn.
var speed := 28.0

var _sails: Node3D


func _ready() -> void:
	var turn := atan2(facing.x, facing.z)
	for i in 2:
		var part := Kit.model("barrel", 5.0)
		part.position.y = i * 2.4
		part.rotation.y = i * 0.6
		add_child(part)
	var roof := Kit.model("block-snow-low-hexagon", 1.0)
	roof.scale = Vector3(2.6, 2.2, 2.3)
	roof.position.y = 4.8
	add_child(roof)
	var door := Kit.model("door-rotate", 1.6)
	door.position = facing * 1.32
	door.rotation.y = turn
	add_child(door)
	# The sails: a hub on the front with four long planks.
	_sails = Node3D.new()
	_sails.position = Vector3.UP * 4.0 + facing * 1.5
	_sails.rotation.y = turn
	add_child(_sails)
	var hub := Kit.model("barrel", 0.9)
	hub.rotation.x = PI / 2.0
	hub.position.z = -0.2
	_sails.add_child(hub)
	for a in 4:
		var arm := Node3D.new()
		arm.rotation.z = TAU * a / 4.0
		_sails.add_child(arm)
		for i in 3:
			var plank := Kit.model("platform", 1.0)
			plank.scale = Vector3(0.7, 0.5, 0.85)
			plank.rotation.x = PI / 2.0
			plank.position = Vector3(0, 0.9 + i * 0.85, 0.05)
			arm.add_child(plank)
	if level:
		level.solid(global_position + Vector3(-1.2, 0, -1.2), global_position + Vector3(1.2, 5.2, 1.2))


func _process(delta: float) -> void:
	_sails.rotate_object_local(Vector3.BACK, deg_to_rad(speed) * delta)
