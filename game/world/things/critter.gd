class_name Critter
extends Area3D
## An enemy: any Cube Pet or theme kit model that patrols back and forth,
## or chases the hero when they come near. Jump on it, ground pound it or
## dive into it and it pops into coins; walk into it and it hurts. Spiky
## critters (ghosts, anything with spines) can't be jumped on: only a ground
## pound beats them. Cube Pets and the Graveyard Kit's characters walk with
## their clips; other models just turn to face where they go.
##
##   add(Critter.make("animal-bee", Vector3(0, 0, 4)), at)          # patrols
##   add(Critter.chaser("grave:character-zombie", 5.0), at)          # chases
##   var c := Critter.make("grave:character-ghost", Vector3(3, 0, 0))
##   c.spiky = true; c.bob = 0.3                                       # floats

var level: Level
var model_name := "animal-crab"
var model_scale := 0.34
## A patroller goes from where it's placed to `travel` and back.
var travel := Vector3(3, 0, 0)
var period := 4.0
var phase := 0.0
## Chasers walk at the hero within this range (0 for a patroller), and
## wander back home past twice it.
var chase_range := 0.0
var speed := 2.4
## Can't be stomped or dived into; only a ground pound beats it.
var spiky := false
## Floats up and down this far (ghosts, bees).
var bob := 0.0
## Size of the body the hero touches.
var size := Vector3(0.75, 0.6, 0.6)
var coins := 2
var defeated := false

var _start := Vector3.ZERO
var _t := 0.0
## Ticks since the hero was last above it: touches show up a tick or two
## late, by when a fast fall has already sunk in.
var _above := 99
var _model: Node3D
var _rig: RigCharacter


static func make(p_model: String, p_travel: Vector3, p_period := 4.0, p_phase := 0.0, p_scale := 0.34) -> Critter:
	var c := Critter.new()
	c.model_name = p_model
	c.travel = p_travel
	c.period = p_period
	c.phase = p_phase
	c.model_scale = p_scale
	return c


static func chaser(p_model: String, p_range := 5.0, p_speed := 2.4, p_scale := 0.34) -> Critter:
	var c := Critter.make(p_model, Vector3.ZERO, 4.0, 0.0, p_scale)
	c.chase_range = p_range
	c.speed = p_speed
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
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	add_child(shape)
	var scene := Kit.scene(model_name)
	if model_name.begins_with("animal-") or model_name.contains("character-"):
		_rig = RigCharacter.create(scene, model_scale)
		_model = _rig
		add_child(_rig)
		_rig.play("walk")
	else:
		_model = scene.instantiate()
		_model.scale = Vector3.ONE * model_scale
		add_child(_model)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if defeated:
		return
	_t += delta
	var before := position
	if chase_range > 0.0:
		_chase(delta)
	else:
		var u := (1.0 - cos(TAU * _t / period)) / 2.0
		position = _start + travel * u
	if bob > 0.0:
		position.y = _start.y + sin(_t * 2.2) * bob + bob
	if level.hero and level.hero.global_position.y > global_position.y + size.y * 0.45:
		_above = 0
	else:
		_above += 1
	var moved := position - before
	moved.y = 0.0
	if moved.length() > 0.0005:
		var turn := atan2(moved.x, moved.z)
		# Crabs walk sideways.
		_model.rotation.y = turn + (PI / 2.0 if model_name == "animal-crab" else 0.0)
	if level.hero and overlaps_body(level.hero):
		_touch(level.hero)


func _chase(delta: float) -> void:
	var h := level.hero
	var target := _start
	if h:
		var to_hero := h.global_position - global_position
		to_hero.y = 0.0
		var from_home := Vector3(position.x - _start.x, 0, position.z - _start.z)
		if to_hero.length() < chase_range and from_home.length() < chase_range * 2.0:
			target = position + to_hero
	var flat := Vector3(target.x - position.x, 0, target.z - position.z)
	if flat.length() > 0.1:
		position += flat.normalized() * minf(speed * delta, flat.length())
	if _rig:
		_rig.play("walk" if flat.length() > 0.1 else "idle")


func _on_body_entered(body: Node3D) -> void:
	if body == level.hero:
		_touch(level.hero)


func _touch(hero: Hero) -> void:
	if defeated:
		return
	var above := _above <= 3
	if hero.is_pounding() or (not spiky and (hero.is_diving() or (above and hero.velocity.y < 0.5))):
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
	tw.tween_property(_model, "scale", _model.scale * Vector3(1.4, 0.2, 1.4), 0.1)
	tw.tween_interval(0.25)
	tw.tween_callback(_drop_coins)
	tw.tween_callback(queue_free)


func _drop_coins() -> void:
	for i in coins:
		var a := TAU * i / maxf(coins, 1)
		level.add_coin(position + Vector3(cos(a) * 0.5, 0.3, sin(a) * 0.5))
