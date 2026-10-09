class_name PirateMortar
extends Node3D
## A mortar: a cannon pointed at the sky that lobs a shell every `period`
## seconds at wherever the hero is standing (when they're in reach), or at
## a list of spots in turn. Each shell shows its landing ring as it's fired
## (see PirateShell), so keep moving and nothing lands on you.

var level: Level
var period := 2.2
var phase := 0.0
## How far it can reach, flat, from where it stands.
var reach := 15.0
var flight := 1.3
var radius := 1.0
## Spots to aim at in turn instead of the hero (level coordinates).
var targets: Array = []
## Shells in the air.
var shells: Array[PirateShell] = []

var _t := 0.0
var _next := 0
var _model: Node3D


static func make(p_period := 2.2, p_phase := 0.0, p_reach := 15.0) -> PirateMortar:
	var m := PirateMortar.new()
	m.period = p_period
	m.phase = p_phase
	m.reach = p_reach
	return m


func _ready() -> void:
	_t = phase * period
	_model = Kit.model("pirate:cannon-mobile", 0.9)
	_model.rotation_degrees.x = -35.0
	_model.position.y = 0.3
	add_child(_model)


func _physics_process(delta: float) -> void:
	_t += delta
	if _t >= period:
		_t -= period
		fire()
	shells = shells.filter(is_instance_valid)


## Seconds until the next shell.
func until_shot() -> float:
	return period - _t


func fire() -> PirateShell:
	var to: Vector3
	if not targets.is_empty():
		to = targets[_next % targets.size()]
		_next += 1
	else:
		var h := level.hero if level else null
		if h == null:
			return null
		var flat := h.global_position - global_position
		flat.y = 0.0
		if flat.length() > reach:
			return null
		# Where they stand, or last stood if they're in the air.
		to = Vector3(h.global_position.x, h.last_floor_y, h.global_position.z) - level.global_position
	var muzzle := position + Vector3.UP * 1.2
	var s := PirateShell.make(muzzle, flight, radius)
	level.add(s, to)
	shells.append(s)
	var tw := create_tween()
	tw.tween_property(_model, "position:y", 0.1, 0.08)
	tw.tween_property(_model, "position:y", 0.3, 0.3)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", -14.0, 0.1)
	return s
