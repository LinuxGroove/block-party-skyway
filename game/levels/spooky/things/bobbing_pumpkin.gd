class_name SpookyBobbingPumpkin
extends MovingPlatform
## A giant pumpkin bobbing in the swamp. Its top is a platform that sinks
## under the murk and comes back up: hop off before it goes under.

var pumpkin_scale := 7.0


## A pumpkin whose top sinks `sink` metres and back every `p_period`
## seconds.
static func bob(p_sink := 2.1, p_period := 4.0, p_phase := 0.0, p_scale := 7.0) -> SpookyBobbingPumpkin:
	var p := SpookyBobbingPumpkin.new()
	p.pumpkin_scale = p_scale
	var top := 0.28 * p_scale
	p.size = Vector3(top, 0.5, top)
	p.travel = Vector3(0, -p_sink, 0)
	p.period = p_period
	p.phase = p_phase
	p.model_name = "grave:pumpkin"
	return p


func _ready() -> void:
	super()
	# One big pumpkin in place of the tiled pieces.
	for c in get_children():
		if c is Node3D and not c is CollisionShape3D:
			c.queue_free()
	var m := Kit.model("grave:pumpkin", pumpkin_scale)
	m.position.y = -0.29 * pumpkin_scale
	m.rotation.y = fposmod(position.x * 1.7, TAU)
	add_child(m)


## The top's height `ahead` seconds from now.
func top_at(ahead: float) -> float:
	return _start.y + offset_at(_t + ahead).y
