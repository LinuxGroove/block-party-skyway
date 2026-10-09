class_name FrostyPingo
extends Area3D
## Pingo, a penguin chick who won't come in off the ice. He waddles about
## inside `bounds` (a flat box), scoots away when the hero comes close,
## stops now and then to catch his breath, and once caught hops home to his
## mother.

signal caught

var level: Level
## Where he may go: x and z of this box (its y is ignored).
var bounds := AABB(Vector3(-4, 0, -4), Vector3(8, 1, 8))
var home := Vector3.ZERO
var speed := 4.6
var scare_range := 5.0
## Seconds he can run before he has to stop, and how long he stops.
var stamina := 2.4
var rest_time := 1.1
var is_home := false

var _rig: RigCharacter
var _run := 0.0
var _rest := 0.0
var _wander := Vector3.ZERO
var _wander_t := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	_rng.seed = 7
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.8, 0.9)
	shape.shape = box
	shape.position.y = 0.4
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene("animal-penguin"), 0.26)
	add_child(_rig)
	_wander = position
	body_entered.connect(_on_body_entered)


## True while he's stopped for a breather.
func is_resting() -> bool:
	return _rest > 0.0


func _physics_process(delta: float) -> void:
	if is_home or level == null:
		return
	var h := level.hero
	var move := Vector3.ZERO
	var fast := false
	if _rest > 0.0:
		_rest -= delta
		_rig.play("idle")
	elif h and _flat(h.global_position - global_position).length() < scare_range:
		var away := _flat(global_position - h.global_position)
		move = away.normalized() if away.length() > 0.01 else Vector3.RIGHT
		fast = true
		_run += delta
		if _run >= stamina:
			_run = 0.0
			_rest = rest_time
	else:
		_run = maxf(_run - delta, 0.0)
		_wander_t -= delta
		if _wander_t <= 0.0 or _flat(_wander - position).length() < 0.3:
			_wander_t = _rng.randf_range(2.0, 4.0)
			_wander = Vector3(_rng.randf_range(bounds.position.x, bounds.end.x), position.y, _rng.randf_range(bounds.position.z, bounds.end.z))
		move = _flat(_wander - position).normalized() * 0.35
	if move.length() > 0.01:
		var next := position + move * speed * delta
		next.x = clampf(next.x, bounds.position.x, bounds.end.x)
		next.z = clampf(next.z, bounds.position.z, bounds.end.z)
		var went := next - position
		position = next
		if went.length() > 0.001:
			_rig.rotation.y = atan2(went.x, went.z)
		_rig.play("run" if fast else "walk")
	elif _rest <= 0.0:
		_rig.play("idle")
	if h and overlaps_body(h):
		_on_body_entered(h)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


func _on_body_entered(body: Node3D) -> void:
	if is_home or body != level.hero:
		return
	is_home = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", 0.0)
	_rig.play("run")
	var tw := create_tween()
	var mid := (position + home) / 2.0 + Vector3.UP * 3.0
	tw.tween_property(self, "position", mid, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", home, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(_arrived)


## Puts him straight home (for a visit after he's been caught).
func place_home() -> void:
	is_home = true
	monitoring = false
	position = home


func _arrived() -> void:
	_rig.play("dance")
	caught.emit()
