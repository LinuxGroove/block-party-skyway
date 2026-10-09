class_name SpookyCoffin
extends FallingPlatform
## A coffin floating over the dark: stand on it and it rattles, then drops
## away, and comes back a while later.

const SCALE := 2.6

## Which way it lies: 0 runs north and south, 90 east and west.
var turn := 0.0


static func floating(p_delay := 0.5, p_turn := 0.0) -> SpookyCoffin:
	var c := SpookyCoffin.new()
	c.turn = p_turn
	var size := Vector3(0.57, 0.32, 0.84) * SCALE
	c.size = Vector3(size.z, 0.4, size.x) if absf(p_turn - 90.0) < 1.0 else Vector3(size.x, 0.4, size.z)
	c.delay = p_delay
	return c


func _ready() -> void:
	super()
	# One coffin in place of the tiled platform pieces, its lid level with
	# the top.
	for n in _visual.get_children():
		n.queue_free()
	var m := Kit.model("grave:coffin", SCALE)
	m.position.y = -0.32 * SCALE
	m.rotation_degrees.y = turn
	_visual.add_child(m)
