class_name FallingPlatform
extends AnimatableBody3D
## A platform that shakes when stood on, falls a moment later, and comes
## back after a while.

var level: Level
var model_name := "platform"
var size := Vector3(2, 0.4, 2)
## Seconds of shaking before it drops, and before it's back.
var delay := 0.6
var comeback := 3.0

var _home := Vector3.ZERO
var _t := 0.0
var _state := 0  # 0 still, 1 shaking, 2 falling, 3 gone
var _speed := 0.0
var _visual: Node3D


static func make(p_size := Vector3(2, 0.4, 2), p_model := "platform", p_delay := 0.6) -> FallingPlatform:
	var f := FallingPlatform.new()
	f.size = p_size
	f.model_name = p_model
	f.delay = p_delay
	return f


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = -size.y / 2.0
	add_child(shape)
	_visual = Node3D.new()
	add_child(_visual)
	var nx := int(roundf(size.x))
	var nz := int(roundf(size.z))
	for x in nx:
		for z in nz:
			var m := Kit.model(model_name)
			m.position = Vector3(x - (nx - 1) / 2.0, -size.y, z - (nz - 1) / 2.0)
			m.scale.y = size.y / 0.2 if model_name == "platform" else 1.0
			_visual.add_child(m)


func _physics_process(delta: float) -> void:
	match _state:
		0:
			if _hero_on():
				_state = 1
				_t = 0.0
		1:
			_t += delta
			_visual.position.x = sin(_t * 60.0) * 0.04
			if _t >= delay:
				_state = 2
				_speed = 0.0
				_visual.position.x = 0.0
		2:
			_speed = minf(_speed + 30.0 * delta, 20.0)
			position.y -= _speed * delta
			if position.y < _home.y - 30.0:
				_state = 3
				_t = 0.0
				visible = false
				collision_layer = 0
		3:
			_t += delta
			if _t >= comeback:
				position = _home
				visible = true
				collision_layer = Kit.LAYER_WORLD
				_state = 0


func _hero_on() -> bool:
	var h := level.hero if level else null
	if h == null or not h.is_on_floor():
		return false
	var p := h.global_position - global_position
	return absf(p.x) < size.x / 2.0 + 0.3 and absf(p.z) < size.z / 2.0 + 0.3 and absf(p.y) < 0.3
