class_name FinishFlag
extends Area3D
## The end of a course: a big flag between two poles. Run through it.

var level: Level
var facing := Vector3.FORWARD
var _done := false


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 3.0, 0.8)
	shape.shape = box
	shape.position.y = 1.5
	shape.rotation.y = atan2(facing.x, facing.z)
	add_child(shape)
	var side := facing.cross(Vector3.UP).normalized()
	for s in [-1.5, 1.5]:
		var pole := Kit.model("flag", 3.4)
		pole.position = side * s
		pole.rotation.y = atan2(facing.x, facing.z) + PI / 2.0
		add_child(pole)
	var banner := Kit.model("poles", 2.6)
	banner.position = Vector3.UP * 0.0
	banner.rotation.y = atan2(facing.x, facing.z)
	add_child(banner)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body != level.hero or _done:
		return
	_done = true
	level.finish_course()
