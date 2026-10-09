class_name StationLaserGate
extends Area3D
## A gate of laser beams across a walkway, between two posts, that switches
## on and off on a beat. The beams flicker for a moment before they come
## on, and hurt only while on: wait for them to go off, then run through.
##
##   add(StationLaserGate.make(6.0, 1.0, 1.4), at)   # across x, at is the middle

## The flicker before the beams come on, in seconds.
const WARN := 0.4
const BEAMS := [0.25, 0.7, 1.15, 1.6, 2.05]

var level: Level
var width := 6.0
## The beams run this way.
var across := Vector3.RIGHT
var on_time := 1.0
var off_time := 1.4
## Where in its beat it starts, 0 to 1 (0 is the start of the off time).
var phase := 0.0

var _t := 0.0
var _on := false
var _beams: Node3D
var _mat: StandardMaterial3D


static func make(p_width: float, p_on := 1.0, p_off := 1.4, p_phase := 0.0, p_across := Vector3.RIGHT) -> StationLaserGate:
	var g := StationLaserGate.new()
	g.width = p_width
	g.on_time = p_on
	g.off_time = p_off
	g.phase = p_phase
	g.across = p_across.normalized()
	return g


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	monitorable = false


func cycle() -> float:
	return on_time + off_time


func _ready() -> void:
	_t = phase * cycle()
	var turn := atan2(-across.z, across.x)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, 2.3, 0.3)
	shape.shape = box
	shape.position.y = 1.15
	shape.rotation.y = turn
	add_child(shape)
	for s in [-0.5, 0.5]:
		var post := Kit.model("station:wall-pillar", 1.0)
		post.scale = Vector3(0.7, 2.4, 0.7)
		post.position = across * (width * s + signf(s) * 0.25)
		post.rotation.y = turn + PI / 2.0
		add_child(post)
	_beams = Node3D.new()
	_beams.rotation.y = turn
	add_child(_beams)
	_mat = StationDeco.glow(Color("ff3d6e"))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(width, 0.07, 0.07)
	for y in BEAMS:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = _mat
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position.y = y
		_beams.add_child(m)
	_show()


## True while the beams are on (and hurt).
func is_on() -> bool:
	return fposmod(_t, cycle()) >= off_time


## Seconds until the beams next come on (0 while they're on).
func time_to_on() -> float:
	var u := fposmod(_t, cycle())
	return 0.0 if u >= off_time else off_time - u


## Seconds until the beams next go off (0 while they're off).
func time_to_off() -> float:
	var u := fposmod(_t, cycle())
	return cycle() - u if u >= off_time else 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	var on := is_on()
	if on != _on:
		_on = on
		if on:
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_disappear.ogg", -16.0, 0.05)
	_show()
	if _on and level and level.hero and overlaps_body(level.hero):
		level.hurt_hero(global_position - across.cross(Vector3.UP) * 0.5 * signf(across.cross(Vector3.UP).dot(level.hero.global_position - global_position)))


func _show() -> void:
	if is_on():
		_beams.visible = true
		_mat.albedo_color.a = 1.0
		_beams.scale = Vector3.ONE
	else:
		var warn := time_to_on() < WARN
		_beams.visible = warn and int(_t * 20.0) % 2 == 0
		_beams.scale = Vector3(1, 0.35, 0.35)
