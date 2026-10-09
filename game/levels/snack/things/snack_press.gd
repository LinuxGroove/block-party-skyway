class_name SnackPress
extends Crusher
## A giant pot turned upside down over a kitchen belt: it lifts slowly and
## slams down, over and over, like a Crusher. Wait for it to go up, then
## dash under; its top is solid, so it doubles as a lift.
##
##   add(SnackPress.pot(2.4, 0.0), at)

var food := "food:pot"
var food_scale := 4.5


static func pot(p_lift := 2.4, p_phase := 0.0, p_food := "food:pot", p_scale := 4.5) -> SnackPress:
	var p := SnackPress.new()
	p.lift = p_lift
	p.phase = p_phase
	p.food = p_food
	p.food_scale = p_scale
	var b := SnackFood.bounds(p_food)
	# The pot's body, without the handles sticking out.
	p.size = Vector3(b.size.x, b.size.y, b.size.x) * p_scale
	return p


func _ready() -> void:
	super()
	# Swap the block the Crusher made for the pot, upside down, handles across.
	for c in get_children():
		if not (c is CollisionShape3D or c is Area3D):
			c.queue_free()
	var b := SnackFood.bounds(food)
	var m := Kit.model(food, food_scale)
	m.basis = Basis(Vector3.RIGHT, PI) * Basis(Vector3.UP, PI / 2.0) * Basis.from_scale(Vector3.ONE * food_scale)
	m.position = Vector3(0, b.end.y * food_scale, 0)
	add_child(m)
