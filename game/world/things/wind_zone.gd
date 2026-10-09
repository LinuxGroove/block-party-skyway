class_name WindZone
extends Area3D
## A box of moving air (a fan's updraft, a gust, a vent) that pushes the
## hero while they're in it. Shows a few drifting streaks so it reads.
##
##   add(WindZone.make(Vector3(2, 6, 2), Vector3.UP * 40.0), at)   # at is the box's foot

var level: Level
var size := Vector3(2, 6, 2)
## Acceleration in m/s²: about 40 up beats gravity and lifts.
var push := Vector3.UP * 40.0
var show_streaks := true

var _streaks: Array[MeshInstance3D] = []
var _t := 0.0


static func make(p_size: Vector3, p_push: Vector3) -> WindZone:
	var w := WindZone.new()
	w.size = p_size
	w.push = p_push
	return w


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	add_child(shape)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	if show_streaks:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1, 1, 1, 0.35)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var mesh := BoxMesh.new()
		var along := push.normalized()
		mesh.size = Vector3(0.05, 0.05, 0.05) + along.abs() * 0.8
		for i in 10:
			var m := MeshInstance3D.new()
			m.mesh = mesh
			m.material_override = mat
			m.position = Vector3(randf_range(-0.5, 0.5) * size.x, randf() * size.y, randf_range(-0.5, 0.5) * size.z)
			add_child(m)
			_streaks.append(m)


func _process(delta: float) -> void:
	_t += delta
	var along := push.normalized()
	for m in _streaks:
		m.position += along * delta * 6.0
		var half := size / 2.0
		if m.position.y > size.y or m.position.y < 0.0 or absf(m.position.x) > half.x or absf(m.position.z) > half.z:
			m.position = Vector3(randf_range(-0.5, 0.5) * size.x, randf() * size.y, randf_range(-0.5, 0.5) * size.z)
			if along.y > 0.5:
				m.position.y = 0.0


func _on_enter(body: Node3D) -> void:
	if body is Hero:
		(body as Hero).add_force(self, push)


func _on_exit(body: Node3D) -> void:
	if body is Hero:
		(body as Hero).remove_force(self)


func _exit_tree() -> void:
	if level and level.hero:
		level.hero.remove_force(self)
