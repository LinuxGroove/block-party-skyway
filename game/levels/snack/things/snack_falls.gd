class_name SnackFalls
extends Node3D
## A curtain of melted chocolate pouring off a ledge, facing `facing`, with
## a puddle where it lands. Only a look: the hero walks straight through
## it (and finds what's behind).

var level: Level
var width := 4.0
var height := 3.0
var facing := Vector3.BACK
var color := Color(0.42, 0.22, 0.12, 0.84)

const FLOW := """
shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform vec4 tint : source_color = vec4(0.42, 0.22, 0.12, 0.93);
uniform float speed = 1.4;
uniform float flat_flow = 0.0;
void fragment() {
	float band = sin(UV.x * 37.0 + sin(UV.x * 9.0) * 3.0) * 0.5 + 0.5;
	float along = mix(UV.y, UV.x, flat_flow);
	float flow = fract(along * 3.0 - TIME * speed + band * 0.5);
	float streak = smoothstep(0.0, 0.3, flow) * smoothstep(1.0, 0.55, flow);
	ALBEDO = tint.rgb * (0.78 + 0.4 * streak);
	ALPHA = tint.a;
	ROUGHNESS = 0.25;
	SPECULAR = 0.7;
}
"""


func _ready() -> void:
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = FLOW
	mat.shader = shader
	mat.set_shader_parameter("tint", color)
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	sheet.mesh = quad
	sheet.material_override = mat
	sheet.position.y = height / 2.0
	sheet.rotation.y = atan2(facing.x, facing.z)
	add_child(sheet)
	var puddle := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = width * 0.55
	disc.bottom_radius = width * 0.6
	disc.height = 0.06
	puddle.mesh = disc
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(color.r, color.g, color.b)
	pm.roughness = 0.2
	pm.metallic_specular = 0.8
	puddle.material_override = pm
	puddle.position = facing * width * 0.45 + Vector3.UP * 0.03
	puddle.scale = Vector3(1.0, 1.0, 0.7)
	puddle.rotation.y = atan2(facing.x, facing.z)
	add_child(puddle)


## A flat stream of chocolate over a ledge's top, flowing towards `dir`.
static func stream(level: Level, from: Vector3, to: Vector3, wide: float, tint := Color(0.42, 0.22, 0.12, 1.0)) -> MeshInstance3D:
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = FLOW
	mat.shader = shader
	mat.set_shader_parameter("tint", tint)
	mat.set_shader_parameter("flat_flow", 1.0)
	var m := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var along := to - from
	plane.size = Vector2(along.length(), wide)
	m.mesh = plane
	m.material_override = mat
	m.position = (from + to) / 2.0 + Vector3.UP * 0.03
	m.rotation.y = atan2(-along.z, along.x)
	level.add_child(m)
	return m
