class_name SpookyFlame
extends Projectile
## A slow ball of lantern fire, thrown by the Night Keeper and spat by the
## flame lanterns on the courses. It hurts to touch, and goes out when it
## hits the ground or a wall.

var _ball: MeshInstance3D
var _t := 0.0


func _init() -> void:
	super()
	model_name = ""
	radius = 0.3


func _ready() -> void:
	super()
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	_ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.5, 0.12, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ball.material_override = mat
	add_child(_ball)
	var core := MeshInstance3D.new()
	var small := SphereMesh.new()
	small.radius = 0.17
	small.height = 0.34
	core.mesh = small
	var hot := StandardMaterial3D.new()
	hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hot.albedo_color = Color("fff0a0")
	core.material_override = hot
	core.position = Vector3(0, 0.05, 0)
	add_child(core)
	var light := OmniLight3D.new()
	light.light_color = Color("ff9a3c")
	light.light_energy = 1.6
	light.omni_range = 3.5
	add_child(light)


func _process(delta: float) -> void:
	_t += delta
	if _ball:
		_ball.scale = Vector3.ONE * (1.0 + sin(_t * 18.0) * 0.1)
