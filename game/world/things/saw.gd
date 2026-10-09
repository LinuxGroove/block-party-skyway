class_name Saw
extends Area3D
## A spinning saw blade that slides back and forth along a slot. Touching it
## hurts.

var level: Level
var travel := Vector3(4, 0, 0)
var period := 3.0
var phase := 0.0

var _start := Vector3.ZERO
var _t := 0.0
var _blade: Node3D


static func make(p_travel: Vector3, p_period := 3.0, p_phase := 0.0) -> Saw:
	var s := Saw.new()
	s.travel = p_travel
	s.period = p_period
	s.phase = p_phase
	return s


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	_start = position
	_t = phase * period
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.55
	cyl.height = 0.4
	shape.shape = cyl
	shape.rotation_degrees.x = 90
	shape.position.y = 0.55
	add_child(shape)
	_blade = Kit.model("saw", 1.6)
	_blade.position.y = 0.55
	# The blade runs along its slot.
	_blade.rotation.y = atan2(travel.x, travel.z) + PI / 2.0
	add_child(_blade)
	var slot := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.04, travel.length() + 0.6)
	slot.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3d3f4a")
	slot.material_override = mat
	slot.position = travel / 2.0 + Vector3.UP * 0.02
	slot.rotation.y = atan2(travel.x, travel.z)
	slot.top_level = false
	add_child(slot)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_t += delta
	var u := (1.0 - cos(TAU * _t / period)) / 2.0
	var at := travel * u
	for c in get_children():
		if c is CollisionShape3D or c == _blade:
			c.position = Vector3(at.x, c.position.y, at.z)
	_blade.rotate_object_local(Vector3.FORWARD, -9.0 * delta)
	if level.hero and overlaps_body(level.hero):
		level.hurt_hero(global_position + at + Vector3.UP * 0.55)


func _on_body_entered(body: Node3D) -> void:
	if body == level.hero:
		level.hurt_hero(_blade.global_position)
