class_name StationGravity
extends Area3D
## A patch of moon gravity on the station: inside it the hero's jumps go
## higher and float longer (Hero.gravity_scale), and slow sparkles drift up
## so it reads. Leaving it puts the level's own gravity back.
##
##   add(StationGravity.make(Vector3(20, 12, 20), 0.5), at)   # at is the box's foot

var level: Level
var size := Vector3(10, 10, 10)
## The hero's gravity inside, as a share of normal.
var pull := 0.5
## How far above the box's foot the sparkles start (the floor).
var motes_from := 0.0

var _motes: Array[MeshInstance3D] = []


static func make(p_size: Vector3, p_gravity := 0.5) -> StationGravity:
	var g := StationGravity.new()
	g.size = p_size
	g.pull = p_gravity
	return g


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
	var mat := StationDeco.glow(Color("9fe3f0"), 0.55)
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * 0.08
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(position.x * 13.0 + position.z * 7.0))
	var n := clampi(int(size.x * size.z / 14.0), 8, 40)
	for i in n:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(rng.randf_range(-0.5, 0.5) * size.x, motes_from + rng.randf() * 4.0, rng.randf_range(-0.5, 0.5) * size.z)
		add_child(m)
		_motes.append(m)


func _process(delta: float) -> void:
	for m in _motes:
		m.position.y += delta * 0.5
		if m.position.y > motes_from + 4.0:
			m.position.y = motes_from


func _on_enter(body: Node3D) -> void:
	if body is Hero:
		(body as Hero).gravity_scale = pull


func _on_exit(body: Node3D) -> void:
	if body is Hero:
		(body as Hero).gravity_scale = level.gravity_scale if level else 1.0


func _exit_tree() -> void:
	if level and level.hero:
		level.hero.gravity_scale = level.gravity_scale
