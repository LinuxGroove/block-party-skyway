class_name Crusher
extends AnimatableBody3D
## A heavy block that rises slowly and slams down, over and over: wait for
## it to go up, then dash under. Getting caught underneath sends the hero
## back to the last flag. The top is solid, so it doubles as a lift.

var level: Level
var model_name := "block-moving-large"
var size := Vector3(2, 1, 2)
## How far it lifts, and the seconds spent down, rising, up and falling.
var lift := 3.0
var down_time := 1.0
var rise_time := 1.4
var up_time := 1.2
var fall_time := 0.25
var phase := 0.0

var _home := Vector3.ZERO
var _t := 0.0
var _under: Area3D


static func make(p_lift := 3.0, p_size := Vector3(2, 1, 2), p_phase := 0.0, p_model := "block-moving-large") -> Crusher:
	var c := Crusher.new()
	c.lift = p_lift
	c.size = p_size
	c.phase = p_phase
	c.model_name = p_model
	return c


func cycle() -> float:
	return down_time + rise_time + up_time + fall_time


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase * cycle()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	add_child(shape)
	var m := Kit.model(model_name)
	var natural := Vector3(1, 0.5, 1) if model_name.begins_with("block-moving") else Vector3.ONE
	m.scale = size / natural
	add_child(m)
	# What it would land on: a thin box just under its bottom while falling.
	_under = Area3D.new()
	_under.collision_layer = 0
	_under.collision_mask = Kit.LAYER_HERO
	_under.monitorable = false
	var us := CollisionShape3D.new()
	var ub := BoxShape3D.new()
	ub.size = Vector3(size.x - 0.3, 0.5, size.z - 0.3)
	us.shape = ub
	us.position.y = -0.25
	_under.add_child(us)
	add_child(_under)
	_place()


## Height above home at time t.
func offset_at(t: float) -> float:
	var u := fposmod(t, cycle())
	if u < down_time:
		return 0.0
	u -= down_time
	if u < rise_time:
		return lift * smoothstep(0.0, 1.0, u / rise_time)
	u -= rise_time
	if u < up_time:
		return lift
	u -= up_time
	return lift * (1.0 - u / fall_time)


func is_falling() -> bool:
	return fposmod(_t, cycle()) > down_time + rise_time + up_time


func _physics_process(delta: float) -> void:
	_t += delta
	_place()
	if is_falling() and level and level.hero and _under.overlaps_body(level.hero) and level.hero.is_on_floor():
		level.fall_off()


func _place() -> void:
	position = _home + Vector3.UP * offset_at(_t)
