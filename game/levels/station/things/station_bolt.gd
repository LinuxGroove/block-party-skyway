class_name StationBolt
extends Projectile
## A turret's laser bolt: a short glowing streak that flies straight and
## hurts on touch.


func _init() -> void:
	super()
	model_name = ""
	radius = 0.28


func _ready() -> void:
	super()
	var dir := velocity.normalized() if velocity.length() > 0.01 else Vector3.FORWARD
	var core := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.8)
	core.mesh = box
	core.material_override = StationDeco.glow(Color("ffd6e0"))
	var halo := MeshInstance3D.new()
	var hb := BoxMesh.new()
	hb.size = Vector3(0.26, 0.26, 0.95)
	halo.mesh = hb
	halo.material_override = StationDeco.glow(Color("ff3d6e"), 0.55)
	for m in [core, halo]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if absf(dir.dot(Vector3.UP)) < 0.99:
			m.basis = Basis.looking_at(dir, Vector3.UP)
		add_child(m)
