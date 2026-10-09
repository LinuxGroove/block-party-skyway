class_name StarBridge
extends SkywayBridge
## A rainbow path that is always there: the Star Road's bridges, walked on
## like any floor (or just looked at, with `solid` off).

var solid := true


static func make(p_to: Vector3, p_width := 2.4) -> StarBridge:
	var b := StarBridge.new()
	b.to = p_to
	b.width = p_width
	return b


func _ready() -> void:
	super()
	show_bridge(false)
	if not solid:
		_body.collision_layer = 0
