class_name CameraZone
extends Area3D
## A box of the level that sets the camera's angle while the hero is inside:
## its heading, how far it looks down, how far back it sits, and whether the
## right stick may turn it all the way round (open areas).

## Heading in degrees: 0 looks north (towards -z), 90 looks west (towards -x).
var yaw := 0.0
## Degrees the camera looks down.
var pitch := 32.0
var distance := 8.5
var free := false
## When zones overlap, the higher rank wins, then the one entered last.
var rank := 0


static func make(box: AABB, p_yaw: float, p_pitch := 32.0, p_distance := 8.5, p_free := false, p_rank := 0) -> CameraZone:
	var z := CameraZone.new()
	z.yaw = p_yaw
	z.pitch = p_pitch
	z.distance = p_distance
	z.free = p_free
	z.rank = p_rank
	z.position = box.get_center()
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = box.size
	shape.shape = b
	z.add_child(shape)
	return z


func _init() -> void:
	collision_layer = 0
	collision_mask = 2
	monitorable = false
