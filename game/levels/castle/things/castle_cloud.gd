class_name CastleCloud
extends AnimatableBody3D
## A puffy cloud solid enough to stand on, bobbing gently in the sunset.
## Its top is flat at its origin.

var level: Level
## How big it is across (x and z), and how far it bobs.
var size := Vector2(2.4, 2.4)
var bob := 0.15
var period := 4.0
var phase := 0.0

var _home := Vector3.ZERO
var _t := 0.0


static func make(p_size := Vector2(2.4, 2.4), p_phase := 0.0) -> CastleCloud:
	var c := CastleCloud.new()
	c.size = p_size
	c.phase = p_phase
	return c


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase * period
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 0.5, size.y)
	shape.shape = box
	shape.position.y = -0.25
	add_child(shape)
	add_child(puffs(size, int(position.x * 7.0 + position.z * 3.0)))
	_place()


## A cluster of white puffs about `across` wide, its top near y = 0.
static func puffs(across: Vector2, seed_value: int) -> Node3D:
	var root := Node3D.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var mat := cloud_material()
	var n := 4 + int(across.x * across.y / 3.0)
	for i in n:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		var r := rng.randf_range(0.45, 0.7) * minf(across.x, across.y) * 0.55
		s.radius = r
		s.height = r * 1.6
		s.radial_segments = 10
		s.rings = 5
		m.mesh = s
		m.material_override = mat
		m.position = Vector3(rng.randf_range(-0.35, 0.35) * across.x, -r * 0.55 + rng.randf_range(-0.05, 0.05), rng.randf_range(-0.35, 0.35) * across.y)
		root.add_child(m)
	return root


static var _material: StandardMaterial3D


static func cloud_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_color = Color("fff6ee")
		_material.roughness = 1.0
		_material.rim_enabled = true
		_material.rim = 0.4
		_material.rim_tint = 0.6
	return _material


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	position = _home + Vector3.UP * sin(TAU * _t / period) * bob
