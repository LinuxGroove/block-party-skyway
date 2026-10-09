class_name FrostySnowball
extends Projectile
## A snowball: a white ball that rolls (or flies) straight and bursts on
## whatever it hits. Snowmen throw them (see FrostyThrower).

static var _mat: StandardMaterial3D


func _init() -> void:
	super()
	model_name = ""
	radius = 0.35


func _ready() -> void:
	super()
	var m := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = radius
	ball.height = radius * 2.0
	ball.radial_segments = 16
	ball.rings = 8
	m.mesh = ball
	m.material_override = _snow()
	add_child(m)
	_model = m


static func _snow() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color("f4f9ff")
		_mat.roughness = 0.9
	return _mat
