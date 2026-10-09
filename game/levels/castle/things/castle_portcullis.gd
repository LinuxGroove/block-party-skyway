class_name CastlePortcullis
extends Crusher
## An iron portcullis in a gateway: it rises slowly, waits, and slams down.
## Dash under while it's up; caught underneath, it's back to the last flag.
## Down, it shuts the way like a wall.
##
##   add(CastlePortcullis.make_gate(3.0, 3.0, Vector3.FORWARD), at)   # at: the gateway's foot

const MODEL := "castle:metal-gate"

## Which way the way through runs (the gate stands across it).
var through := Vector3.FORWARD
## Thin iron posts either side and a bar over the top, which stay put while
## the gate moves.
var frame := true


static func make_gate(p_width := 3.0, p_height := 3.0, p_through := Vector3.FORWARD, p_phase := 0.0) -> CastlePortcullis:
	var p := CastlePortcullis.new()
	p.through = Vector3(p_through.x, 0, p_through.z).normalized()
	p.size = Vector3(p_width, p_height, 0.35)
	p.lift = p_height - 0.2
	p.phase = p_phase
	p.down_time = 1.2
	p.rise_time = 1.0
	p.up_time = 1.6
	p.fall_time = 0.22
	return p


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase * cycle()
	var turn := atan2(through.x, through.z)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = size.y / 2.0
	shape.rotation.y = turn
	add_child(shape)
	# The kit's gate is thin along x and 0.7 wide along z.
	var m := Kit.model(MODEL)
	m.scale = Vector3(3.0, size.y / 0.73, size.x / 0.7)
	m.rotation.y = turn + PI / 2.0
	add_child(m)
	# The way under it: caught here as it slams, it's back to the flag.
	_under = Area3D.new()
	_under.collision_layer = 0
	_under.collision_mask = Kit.LAYER_HERO
	_under.monitorable = false
	var us := CollisionShape3D.new()
	var ub := BoxShape3D.new()
	ub.size = Vector3(size.x - 0.3, 0.6, 0.9)
	us.shape = ub
	us.position.y = -0.3
	us.rotation.y = turn
	_under.add_child(us)
	add_child(_under)
	if frame:
		_add_frame(turn)
	_place()


func _add_frame(turn: float) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("4a4c58")
	mat.metallic = 0.3
	var across := Basis(Vector3.UP, turn) * Vector3.RIGHT
	var tall := size.y + lift + 0.4
	for s in [-1.0, 1.0]:
		_frame_bar(Vector3(0.2, tall, 0.2), _home + across * s * (size.x / 2.0 + 0.12) + Vector3.UP * (tall / 2.0 - 0.3), turn, mat)
	_frame_bar(Vector3(size.x + 0.5, 0.25, 0.25), _home + Vector3.UP * (tall - 0.3), turn, mat)


## One piece of the frame, placed in the level (it doesn't ride the gate).
func _frame_bar(box_size: Vector3, at: Vector3, turn: float, mat: Material) -> void:
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = box_size
	bar.mesh = box
	bar.material_override = mat
	bar.top_level = true
	add_child(bar)
	bar.global_transform = Transform3D(Basis(Vector3.UP, turn), get_parent().global_transform * at if get_parent() is Node3D else at)


## True while it's up high enough to run under, and will be for `seconds`.
func is_open_for(seconds: float) -> bool:
	var u := fposmod(_t, cycle())
	var open_from := down_time + rise_time * 0.6
	var open_to := down_time + rise_time + up_time
	return u >= open_from and u + seconds <= open_to
