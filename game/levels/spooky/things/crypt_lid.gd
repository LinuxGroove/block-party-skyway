class_name SpookyCryptLid
extends Crusher
## A heavy stone crypt lid that rises slowly and slams down: wait for it to
## lift, then dash under, or hop on top and ride it up.


static func slab(p_size := Vector3(4, 1, 2), p_lift := 2.4, p_phase := 0.0) -> SpookyCryptLid:
	var c := SpookyCryptLid.new()
	c.size = p_size
	c.lift = p_lift
	c.phase = p_phase
	c.model_name = "block-snow-large"
	return c


func _ready() -> void:
	super()
	for c in get_children():
		if c is CollisionShape3D or c is Area3D:
			continue
		# The kit's large block is 2 by 1 by 2.
		(c as Node3D).scale = size / Vector3(2, 1, 2)
		if level:
			SpookyProps.paint(level, c)
	var cross := Kit.model("grave:cross", 1.8)
	cross.rotation_degrees = Vector3(-90, 90, 0)
	cross.position = Vector3(0, size.y + 0.02, 0.6)
	add_child(cross)
