class_name SnackRoller
extends Area3D
## Giant fruit rolling down a lane, over and over: it pops up at the start,
## rolls to the end, sinks away and comes round again after a pause. Jump
## over it or wait for a gap; touching it hurts, but landing on top just
## bounces off. Snack Valley's own hazard.
##
##   add(SnackRoller.make("food:orange", Vector3(0, 0, 10), 4.0), at)

var level: Level
var model_name := "food:orange"
## The fruit's height across, in metres.
var diameter := 1.0
## From the start to the end of the lane.
var travel := Vector3(0, 0, 10)
var speed := 4.0
## Seconds between sinking at the end and popping up at the start.
var pause := 1.0
var phase := 0.0

var _start := Vector3.ZERO
var _t := 0.0
var _pivot: Node3D
var _spin: Node3D
var _shape: CollisionShape3D
var _above := 99


static func make(p_model: String, p_travel: Vector3, p_speed := 4.0, p_diameter := 1.0, p_phase := 0.0) -> SnackRoller:
	var r := SnackRoller.new()
	r.model_name = p_model
	r.travel = p_travel
	r.speed = p_speed
	r.diameter = p_diameter
	r.phase = p_phase
	return r


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func cycle() -> float:
	return travel.length() / speed + pause


func _ready() -> void:
	_start = position
	_t = phase * cycle()
	var b := SnackFood.bounds(model_name)
	var s := diameter / maxf(b.size.x, b.size.y)
	_pivot = Node3D.new()
	_pivot.position.y = diameter / 2.0
	add_child(_pivot)
	_spin = Node3D.new()
	_pivot.add_child(_spin)
	var m := Kit.model(model_name, s)
	m.position = -b.get_center() * s
	_spin.add_child(m)
	_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = diameter * 0.42
	_shape.shape = sphere
	_shape.position.y = diameter / 2.0
	add_child(_shape)
	body_entered.connect(_on_body)
	_place(0.0)


## Where along the lane it is at time t (0 to 1), or -1 while it's away.
func along_at(t: float) -> float:
	var u := fposmod(t, cycle())
	var roll := travel.length() / speed
	return u / roll if u < roll else -1.0


## True while it's rolling (not sunk away between runs).
func is_out() -> bool:
	return along_at(_t) >= 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_place(delta)
	var h := level.hero if level else null
	if h == null or not is_out():
		_above = 99
		return
	if h.global_position.y > global_position.y + diameter * 0.6:
		_above = 0
	else:
		_above += 1
	if overlaps_body(h):
		_touch(h)


func _place(delta: float) -> void:
	var a := along_at(_t)
	if a < 0.0:
		visible = false
		position = _start
		return
	visible = true
	position = _start + travel * a
	# Grows out of the ground at the start and sinks at the end.
	var grow := clampf(minf(a, 1.0 - a) * travel.length() / (diameter * 0.8), 0.0, 1.0)
	_pivot.scale = Vector3.ONE * maxf(grow, 0.05)
	_pivot.position.y = diameter / 2.0 * grow
	var dir := travel.normalized()
	var axis := Vector3.UP.cross(dir).normalized()
	if axis.length() > 0.5 and delta > 0.0:
		_spin.global_rotate(axis, speed / (diameter / 2.0) * delta)


func _on_body(body: Node3D) -> void:
	if level and body == level.hero and is_out():
		_touch(level.hero)


func _touch(h: Hero) -> void:
	if _above <= 3 and h.velocity.y < 0.5:
		h.bounce(9.0)
	else:
		level.hurt_hero(global_position + Vector3.UP * diameter / 2.0)
