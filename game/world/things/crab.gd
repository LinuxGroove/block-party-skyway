class_name Crab
extends Area3D
## A grumpy crab that scuttles back and forth. Jump on it, ground pound it or
## dive into it and it pops into coins; walk into it and it pinches.

var level: Level
var travel := Vector3(3, 0, 0)
var period := 4.0
var phase := 0.0
var defeated := false

var _start := Vector3.ZERO
var _t := 0.0
var _model: Node3D
var _rig: RigCharacter


static func make(p_travel: Vector3, p_period := 4.0, p_phase := 0.0) -> Crab:
	var c := Crab.new()
	c.travel = p_travel
	c.period = p_period
	c.phase = p_phase
	return c


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	_start = position
	_t = phase * period
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.75, 0.5, 0.5)
	shape.shape = box
	shape.position.y = 0.25
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene("animal-crab"), 0.34)
	_model = _rig
	add_child(_rig)
	_rig.play("walk")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if defeated:
		return
	_t += delta
	var u := (1.0 - cos(TAU * _t / period)) / 2.0
	var before := position
	position = _start + travel * u
	var moved := position - before
	if moved.length() > 0.0005:
		# Crabs walk sideways.
		_model.rotation.y = atan2(moved.x, moved.z) + PI / 2.0
	if level.hero and overlaps_body(level.hero):
		_touch(level.hero)


func _on_body_entered(body: Node3D) -> void:
	if body == level.hero:
		_touch(level.hero)


func _touch(hero: Hero) -> void:
	if defeated:
		return
	var above := hero.global_position.y > global_position.y + 0.25
	if hero.is_pounding() or hero.is_diving() or (above and hero.velocity.y < 0.5):
		defeat()
		if not hero.is_diving():
			hero.bounce(11.0)
	else:
		level.hurt_hero(global_position)


func defeat() -> void:
	if defeated:
		return
	defeated = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_bump.ogg", -2.0, 0.1)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.4, 0.2, 1.4), 0.1)
	tw.tween_interval(0.25)
	tw.tween_callback(_drop_coins)
	tw.tween_callback(queue_free)


func _drop_coins() -> void:
	for i in 2:
		var c := Pickup.make("coin")
		level.add(c, position + Vector3(0.5 if i == 0 else -0.5, 0.3, 0.0))
