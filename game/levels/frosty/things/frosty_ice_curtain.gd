class_name FrostyIceCurtain
extends Node3D
## A sheet of thin ice hanging over a hollow in a cliff, with icicles along
## its top. It looks like a wall, but there's nothing to bump into: the hero
## walks straight through.

## Width (along x, before `turn`), height and thickness.
var size := Vector3(4, 2, 0.3)
## Degrees about y.
var turn := 0.0


func _ready() -> void:
	rotation_degrees.y = turn
	var sheet := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	sheet.mesh = box
	sheet.position.y = size.y / 2.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.88, 1.0, 0.62)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic_specular = 0.9
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.4, 0.6)
	mat.emission_energy_multiplier = 0.3
	sheet.material_override = mat
	add_child(sheet)
	# Icicles hanging in front of it.
	var ice := StandardMaterial3D.new()
	ice.albedo_color = Color(0.85, 0.95, 1.0, 0.85)
	ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.roughness = 0.1
	var n := int(size.x / 0.45)
	for i in n:
		var cone := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var long := 0.35 + 0.3 * absf(sin(i * 2.3))
		cm.top_radius = 0.09
		cm.bottom_radius = 0.0
		cm.height = long
		cm.radial_segments = 6
		cone.mesh = cm
		cone.material_override = ice
		cone.position = Vector3(-size.x / 2.0 + (i + 0.5) * size.x / n, size.y - long / 2.0, size.z / 2.0 + 0.08)
		add_child(cone)
