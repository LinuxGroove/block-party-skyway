class_name SnackSoda
extends MeshInstance3D
## The surface of a soda lake: orange with bubbles that swell and pop and
## slow swirls, so it reads as something fizzy to keep out of rather than
## ground to walk on. Only a look; lake() also lays the water that sends
## the hero back to the flag.
##
##   SnackSoda.lake(self, -38, -13, -12, 14, -0.5)

const SURFACE := """
shader_type spatial;
render_mode cull_disabled, depth_draw_always;
uniform vec4 tint : source_color = vec4(0.96, 0.45, 0.1, 0.9);
uniform vec4 foam : source_color = vec4(1.0, 0.88, 0.66, 1.0);
void fragment() {
	vec2 p = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 g = p * 0.8;
	vec2 cell = floor(g);
	vec2 f = fract(g) - 0.5;
	float h = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	vec2 off = vec2(h - 0.5, fract(h * 7.13) - 0.5) * 0.55;
	float grow = fract(TIME * (0.35 + h * 0.4) + h);
	float r = 0.04 + 0.16 * grow;
	float d = length(f - off);
	float ring = smoothstep(r + 0.03, r, d) * smoothstep(r - 0.07, r - 0.02, d) * (1.0 - grow) * step(0.3, fract(h * 13.7));
	float swirl = 0.5 + 0.5 * sin(p.x * 0.55 + TIME * 0.7) * sin(p.y * 0.45 - TIME * 0.5);
	ALBEDO = mix(tint.rgb * (0.86 + 0.22 * swirl), foam.rgb, ring);
	ALPHA = mix(tint.a, 1.0, ring);
	ROUGHNESS = 0.12;
	SPECULAR = 0.75;
}
"""

var size := Vector2(10, 10)
var tint := Color(0.96, 0.45, 0.1, 0.9)


static func make(p_size: Vector2, p_tint := Color(0.96, 0.45, 0.1, 0.9)) -> SnackSoda:
	var s := SnackSoda.new()
	s.size = p_size
	s.tint = p_tint
	return s


## A soda lake over x0..x1, z0..z1 with its surface at `y`: the water that
## sends the hero back, under this surface.
static func lake(level: Level, x0: float, z0: float, x1: float, z1: float, y: float, p_tint := Color(0.96, 0.45, 0.1, 0.9)) -> SnackSoda:
	level.water(x0, z0, x1, z1, y, Color(p_tint.r, p_tint.g, p_tint.b, 0.0))
	return level.add(SnackSoda.make(Vector2(x1 - x0, z1 - z0), p_tint), Vector3((x0 + x1) / 2.0, y + 0.01, (z0 + z1) / 2.0)) as SnackSoda


func _ready() -> void:
	var plane := PlaneMesh.new()
	plane.size = size
	mesh = plane
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = SURFACE
	mat.shader = shader
	mat.set_shader_parameter("tint", tint)
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
