class_name SnackDonut
extends Area3D
## A runaway donut that rolls about a square of the island and rolls off
## whenever the hero comes close. It's a little slower than a run, so chase
## it into a corner (or dive at it) and touch it to catch it.

signal caught(donut: SnackDonut)

var level: Level
## The square it keeps to: corners in x and z.
var area := Rect2(-5, -5, 10, 10)
var speed := 5.6
## It rolls off when the hero is nearer than this.
var wary := 6.0
var model_name := "food:donut-sprinkles"
var diameter := 1.4
var is_caught := false

var _wheel: Node3D
var _spin: Node3D
var _heading := Vector3.FORWARD
var _t := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = diameter * 0.55
	shape.shape = sphere
	shape.position.y = diameter / 2.0
	add_child(shape)
	var b := SnackFood.bounds(model_name)
	var s := diameter / maxf(b.size.x, b.size.z)
	_wheel = Node3D.new()
	_wheel.position.y = diameter / 2.0
	add_child(_wheel)
	_spin = Node3D.new()
	_wheel.add_child(_spin)
	# Stood on its edge like a wheel: the ring faces sideways.
	var m := Kit.model(model_name, s)
	m.position = -b.get_center() * s
	var upright := Node3D.new()
	upright.rotation.z = PI / 2.0
	upright.add_child(m)
	_spin.add_child(upright)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	if is_caught:
		return
	_t += delta
	var h := level.hero if level else null
	var want := Vector3.ZERO
	if h:
		var away := global_position - h.global_position
		away.y = 0.0
		if away.length() < wary:
			want = away.normalized() * (1.0 - away.length() / wary + 0.4)
	# Keep off the edges of the square.
	var p := Vector2(position.x, position.z)
	var edge := 2.5
	want.x += _push(p.x - area.position.x, edge) - _push(area.end.x - p.x, edge)
	want.z += _push(p.y - area.position.y, edge) - _push(area.end.y - p.y, edge)
	var moving := want.length() > 0.05
	if moving:
		_heading = _heading.slerp(want.normalized(), clampf(6.0 * delta, 0.0, 1.0)).normalized()
		position += _heading * speed * delta
	else:
		# Rocks gently while it waits.
		_wheel.rotation.z = sin(_t * 3.0) * 0.08
	position.x = clampf(position.x, area.position.x, area.end.x)
	position.z = clampf(position.z, area.position.y, area.end.y)
	_wheel.rotation.y = atan2(_heading.x, _heading.z)
	if moving:
		_spin.rotate_x(speed / (diameter / 2.0) * delta)
	if h and overlaps_body(h):
		_on_body(h)


## Pushes back from a wall `d` away, harder the closer it is.
func _push(d: float, edge: float) -> float:
	return clampf(1.0 - d / edge, 0.0, 1.0) * 1.6


func _on_body(body: Node3D) -> void:
	if is_caught or level == null or body != level.hero:
		return
	is_caught = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", 0.0)
	var tw := create_tween()
	tw.tween_property(self, "position", position + Vector3.UP * 1.2, 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.25)
	tw.tween_callback(_done)


func _done() -> void:
	caught.emit(self)
	hide()
