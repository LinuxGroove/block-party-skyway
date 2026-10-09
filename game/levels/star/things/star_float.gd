class_name StarFloat
extends MovingPlatform
## A giant sweet (a stack of pancakes, a waffle, a pie) drifting on soda: a
## moving platform that wears one big food model instead of the kit's
## platform tiles.
##
##   add(StarFloat.make_float("food:pancakes", 5.0, 0.12, Vector3(0, 0, -6), 5.0), at)

## The model and its scale; it's placed with its top level with the
## platform's top.
var look := "food:pancakes"
var look_scale := 5.0
## The model's height before scaling, to sit its top at the platform's top.
var look_height := 0.12


static func make_float(p_look: String, p_scale: float, p_height: float, p_travel: Vector3, p_period := 4.0, p_phase := 0.0, p_size := Vector3(2.4, 0.5, 2.4)) -> StarFloat:
	var f := StarFloat.new()
	f.look = p_look
	f.look_scale = p_scale
	f.look_height = p_height
	f.travel = p_travel
	f.period = p_period
	f.phase = p_phase
	f.size = p_size
	return f


func _ready() -> void:
	super()
	# Swap the kit's platform tiles for the sweet.
	for c in get_children():
		if not c is CollisionShape3D:
			c.queue_free()
	var m := Kit.model(look, look_scale)
	m.position.y = -look_height * look_scale
	add_child(m)
