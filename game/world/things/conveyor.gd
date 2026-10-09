class_name Conveyor
extends StaticBody3D
## A run of conveyor belts that carries whoever stands on it.

var level: Level
var length := 4
## Which way it carries, flat and unit length.
var direction := Vector3.BACK
var speed := 2.5


static func make(p_length: int, p_direction: Vector3, p_speed := 2.5) -> Conveyor:
	var c := Conveyor.new()
	c.length = p_length
	c.direction = p_direction.normalized()
	c.speed = p_speed
	return c


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	set_meta("push", direction * speed)
	var turn := atan2(direction.x, direction.z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 0.35, float(length))
	shape.shape = box
	shape.position = direction * (length / 2.0) + Vector3.UP * 0.175
	shape.rotation.y = turn
	add_child(shape)
	for i in length:
		for s in [-0.5, 0.5]:
			var m := Kit.model("conveyor-belt")
			m.position = direction * (i + 0.5) + direction.cross(Vector3.UP) * s
			m.rotation.y = turn
			add_child(m)
