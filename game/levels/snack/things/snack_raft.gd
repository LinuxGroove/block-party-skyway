class_name SnackRaft
extends AnimatableBody3D
## A giant piece of food to stand on that moves: a donut bobbing on soda, a
## pancake gliding back and forth, a wafer that drops when stood on, or a
## cookie that slowly sinks into the soda while you're on it. Its top is at
## its position; moved on the physics tick, so riders keep their footing.
##
##   add(SnackRaft.make("food:donut", 12.0), at)                     # bobs in place
##   add(SnackRaft.glide("food:pancakes", 8.0, Vector3(4, 0, 0)), at)
##   add(SnackRaft.wafer("food:waffle", 6.0), at)                    # drops

var level: Level
var model_name := "food:donut"
var model_scale := 10.0
## A round body (donuts, cookies, pancakes) or a square one (waffles).
var round := true
var travel := Vector3.ZERO
var period := 4.0
## Where in its cycle it starts, 0 to 1.
var phase := 0.0
## Seconds it waits at each end of its travel (0 glides smoothly through).
var dwell := 0.0
## Bobs up and down this far, gently, like something floating.
var bob := 0.0
## Shakes when stood on, drops a moment later, and comes back.
var falls := false
var delay := 0.55
var comeback := 3.0
## Sinks this fast (m/s) while stood on, and floats back up when left.
var sinks := 0.0
var sink_depth := 1.2

var _start := Vector3.ZERO
var _t := 0.0
var _visual: Node3D
var _size := Vector3.ONE
var _state := 0  # 0 still, 1 shaking, 2 falling, 3 gone
var _fall_t := 0.0
var _drop := 0.0
var _speed := 0.0
var _sunk := 0.0


static func make(p_model: String, p_scale := 10.0, p_bob := 0.0) -> SnackRaft:
	var r := SnackRaft.new()
	r.model_name = p_model
	r.model_scale = p_scale
	r.bob = p_bob
	return r


static func glide(p_model: String, p_scale: float, p_travel: Vector3, p_period := 4.0, p_phase := 0.0, p_dwell := 0.0) -> SnackRaft:
	var r := SnackRaft.make(p_model, p_scale)
	r.travel = p_travel
	r.period = p_period
	r.phase = p_phase
	r.dwell = p_dwell
	return r


static func wafer(p_model: String, p_scale: float, p_delay := 0.55) -> SnackRaft:
	var r := SnackRaft.make(p_model, p_scale)
	r.falls = true
	r.delay = p_delay
	r.round = false
	return r


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_start = position
	_t = phase * period
	var b := SnackFood.bounds(model_name)
	_size = b.size * model_scale
	var thick := clampf(_size.y, 0.3, 1.2)
	var shape := CollisionShape3D.new()
	if round:
		var cyl := CylinderShape3D.new()
		cyl.radius = maxf(_size.x, _size.z) / 2.0 * 0.92
		cyl.height = thick
		shape.shape = cyl
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(_size.x * 0.96, thick, _size.z * 0.96)
		shape.shape = box
	shape.position.y = -thick / 2.0
	add_child(shape)
	_visual = Node3D.new()
	add_child(_visual)
	var m := Kit.model(model_name, model_scale)
	m.position = Vector3(-b.get_center().x, -b.end.y, -b.get_center().z) * model_scale
	_visual.add_child(m)
	_place()


## Half the width of its top, for tests and the autopilot.
func reach() -> float:
	return minf(_size.x, _size.z) / 2.0


## Where its top is at a moment (ignoring falling and sinking).
func top_at(t: float) -> Vector3:
	var y := sin(t * 1.7) * bob if bob > 0.0 else 0.0
	return _start + travel * travel_at(t) + Vector3.UP * y


## How far along its travel it is at a moment, 0 to 1.
func travel_at(t: float) -> float:
	if travel == Vector3.ZERO:
		return 0.0
	if dwell <= 0.0:
		return (1.0 - cos(TAU * t / period)) / 2.0
	var half := period / 2.0
	var move := maxf(half - dwell, 0.01)
	var p := fposmod(t, period)
	if p < dwell:
		return 0.0
	if p < half:
		return smoothstep(0.0, 1.0, (p - dwell) / move)
	if p < half + dwell:
		return 1.0
	return 1.0 - smoothstep(0.0, 1.0, (p - half - dwell) / move)


## Where its top will be `ahead` seconds from now.
func top_ahead(ahead: float) -> Vector3:
	return top_at(_t + ahead)


func _physics_process(delta: float) -> void:
	_t += delta
	if falls:
		_fall(delta)
	if sinks > 0.0:
		if _hero_on():
			_sunk = minf(_sunk + sinks * delta, sink_depth)
		else:
			_sunk = maxf(_sunk - sinks * 1.5 * delta, 0.0)
	_place()


func _fall(delta: float) -> void:
	match _state:
		0:
			if _hero_on():
				_state = 1
				_fall_t = 0.0
		1:
			_fall_t += delta
			_visual.position.x = sin(_fall_t * 60.0) * 0.05
			if _fall_t >= delay:
				_state = 2
				_speed = 0.0
				_visual.position.x = 0.0
		2:
			_speed = minf(_speed + 30.0 * delta, 20.0)
			_drop += _speed * delta
			if _drop > 30.0:
				_state = 3
				_fall_t = 0.0
				visible = false
				collision_layer = 0
		3:
			_fall_t += delta
			if _fall_t >= comeback:
				_drop = 0.0
				visible = true
				collision_layer = Kit.LAYER_WORLD
				_state = 0


func _place() -> void:
	position = top_at(_t) + Vector3.DOWN * (_drop + _sunk)


func _hero_on() -> bool:
	var h := level.hero if level else null
	if h == null or not h.is_on_floor():
		return false
	var p := h.global_position - global_position
	var r := maxf(_size.x, _size.z) / 2.0 + 0.3
	return Vector2(p.x, p.z).length() < r and absf(p.y) < 0.35
