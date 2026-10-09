class_name Launcher
extends Node3D
## Fires a Projectile along `direction` every `period` seconds: a cannon, a
## snowball thrower, a turret. The launcher's own model is optional (a
## cannon from the Pirate Kit, say); it's solid if it has one.
##
##   add(Launcher.make("pirate:cannon", Vector3.LEFT, 2.5), at)

var level: Level
var model_name := "pirate:cannon"
var model_scale := 1.0
var direction := Vector3.FORWARD
var period := 3.0
var phase := 0.0
var speed := 7.0
## The projectile's look and how it falls.
var shot_model := "pirate:cannon-ball"
var shot_scale := 1.2
var shot_gravity := 0.0
var shot_life := 5.0
## Where shots leave from, above the launcher's feet.
var muzzle := Vector3(0, 0.45, 0)

var _t := 0.0


static func make(p_model: String, p_direction: Vector3, p_period := 3.0, p_phase := 0.0) -> Launcher:
	var l := Launcher.new()
	l.model_name = p_model
	l.direction = p_direction.normalized()
	l.period = p_period
	l.phase = p_phase
	return l


func _ready() -> void:
	_t = phase * period
	if model_name != "":
		var m := Kit.model(model_name, model_scale)
		var flat := Vector3(direction.x, 0, direction.z)
		if flat.length() > 0.01:
			m.rotation.y = atan2(flat.x, flat.z)
		add_child(m)
		if level:
			level.solid(global_position + Vector3(-0.4, 0, -0.4), global_position + Vector3(0.4, 0.8, 0.4))


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= period:
		_t -= period
		fire()


func fire() -> Projectile:
	var p := Projectile.new()
	p.model_name = shot_model
	p.model_scale = shot_scale
	p.velocity = direction * speed
	p.fall = shot_gravity
	p.life = shot_life
	# Out past the launcher's own solid box, so the shot doesn't hit it.
	level.add(p, global_position + muzzle + direction * 1.0)
	return p
