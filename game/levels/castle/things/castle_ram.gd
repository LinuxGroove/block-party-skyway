class_name CastleRam
extends Node3D
## One of King Thud's battering rams: it waits, charges out across the way,
## and rolls slowly back. Touching it hurts. Run past while it's back.
##
##   add(CastleRam.make(Vector3.RIGHT, 4.4, 2.85), at)   # at: where it waits

const MODEL := "castle:siege-ram"

var level: Level
## Which way it charges, and how far.
var facing := Vector3.RIGHT
var travel := 4.4
## Seconds waiting, charging, holding out and rolling back.
var wait_time := 1.3
var charge_time := 0.35
var hold_time := 0.3
var back_time := 0.9
var phase := 0.0
var model_scale := 1.6

var _home := Vector3.ZERO
var _t := 0.0
var _model: Node3D
var _wheels: Array[Node3D] = []
var _hit: Area3D
var _last := 0.0


static func make(p_facing: Vector3, p_travel := 4.4, p_phase := 0.0) -> CastleRam:
	var r := CastleRam.new()
	r.facing = Vector3(p_facing.x, 0, p_facing.z).normalized()
	r.travel = p_travel
	r.phase = p_phase
	return r


func cycle() -> float:
	return wait_time + charge_time + hold_time + back_time


func _ready() -> void:
	_home = position
	_t = phase * cycle()
	# The kit's ram faces +x.
	var turn := atan2(-facing.z, facing.x)
	_model = Kit.model(MODEL, model_scale)
	_model.rotation.y = turn
	add_child(_model)
	for n in _model.find_children("wheel*", "Node3D", true, false):
		_wheels.append(n as Node3D)
	_hit = Area3D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = Kit.LAYER_HERO
	_hit.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 0.9, 0.9) * model_scale
	shape.shape = box
	shape.position.y = 0.45 * model_scale
	shape.rotation.y = turn
	_hit.add_child(shape)
	add_child(_hit)
	_hit.body_entered.connect(_on_body)
	_place()


## How far out it is at time t, 0 (waiting) to 1 (all the way out).
func out_at(t: float) -> float:
	var u := fposmod(t, cycle())
	if u < wait_time:
		return 0.0
	u -= wait_time
	if u < charge_time:
		var k := u / charge_time
		return k * k
	u -= charge_time
	if u < hold_time:
		return 1.0
	u -= hold_time
	return 1.0 - smoothstep(0.0, 1.0, u / back_time)


## True while it's back and will stay back for at least `seconds`.
func is_back_for(seconds: float, ahead := 0.0) -> bool:
	var u := fposmod(_t + ahead, cycle())
	return u + seconds <= wait_time


func _physics_process(delta: float) -> void:
	_t += delta
	_place()
	if level and level.hero and _hit.overlaps_body(level.hero):
		level.hurt_hero(global_position)


func _place() -> void:
	var out := out_at(_t) * travel
	position = _home + facing * out
	# Wheels turn as it rolls.
	var roll := (out - _last) / (0.2 * model_scale)
	_last = out
	for w in _wheels:
		w.rotation.z -= roll


func _on_body(body: Node3D) -> void:
	if level and body == level.hero:
		level.hurt_hero(global_position)
