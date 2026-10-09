class_name CastleBolt
extends Projectile
## A ballista's bolt: flies straight and level until it hits something.

## The ballista's own arrow mesh, for the look, and its scale.
var arrow_mesh: Mesh
var arrow_scale := 1.0


func _init() -> void:
	super()
	model_name = ""
	radius = 0.28


func _ready() -> void:
	super()
	var m := MeshInstance3D.new()
	if arrow_mesh:
		m.mesh = arrow_mesh
		m.scale = Vector3.ONE * arrow_scale
	else:
		var box := BoxMesh.new()
		box.size = Vector3(1.4, 0.15, 0.15)
		m.mesh = box
	# The kit's arrow points along +x.
	var flat := Vector3(velocity.x, 0, velocity.z)
	m.rotation.y = atan2(-flat.z, flat.x)
	add_child(m)
