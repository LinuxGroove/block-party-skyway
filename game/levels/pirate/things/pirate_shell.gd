class_name PirateShell
extends Node3D
## A cannonball lobbed high onto a spot, with fair warning: a red ring shows
## where it will land from the moment it's fired, filling in as it comes
## down. Anyone on the ring when it lands is hit. Placed at the landing
## spot; `from` is where it was fired.

var level: Level
var from := Vector3.ZERO
## Seconds in the air, and how high it arcs above a straight line.
var flight := 1.3
var height := 5.0
## How close to the landing spot counts as a hit.
var radius := 1.0
## Where a hit knocks the hero toward (level coordinates), to keep them off
## the walls of a deck; unset, it knocks them away from the landing spot.
var knock_to := Vector3.INF
var landed := false

var _t := 0.0
var _ball: Node3D
var _ring: MeshInstance3D
var _fill: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _fill_mat: StandardMaterial3D


static func make(p_from: Vector3, p_flight := 1.3, p_radius := 1.0) -> PirateShell:
	var s := PirateShell.new()
	s.from = p_from
	s.flight = p_flight
	s.radius = p_radius
	return s


func _ready() -> void:
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.albedo_color = Color(0.95, 0.15, 0.1, 0.85)
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius - 0.12
	torus.outer_radius = radius
	torus.rings = 24
	torus.ring_segments = 4
	_ring.mesh = torus
	_ring.material_override = _ring_mat
	_ring.position.y = 0.06
	_ring.scale = Vector3(1, 0.3, 1)
	add_child(_ring)
	_fill_mat = _ring_mat.duplicate()
	_fill_mat.albedo_color = Color(0.95, 0.2, 0.1, 0.0)
	_fill = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius - 0.1
	disc.bottom_radius = radius - 0.1
	disc.height = 0.02
	disc.radial_segments = 24
	_fill.mesh = disc
	_fill.material_override = _fill_mat
	_fill.position.y = 0.05
	_fill.scale = Vector3.ONE * 0.05
	add_child(_fill)
	_ball = Kit.model("pirate:cannon-ball", 1.1)
	add_child(_ball)
	_place_ball()


func _physics_process(delta: float) -> void:
	if landed:
		return
	_t += delta
	var u := clampf(_t / flight, 0.0, 1.0)
	_fill.scale = Vector3(maxf(u, 0.05), 1, maxf(u, 0.05))
	_fill_mat.albedo_color.a = 0.15 + 0.35 * u
	_ring_mat.albedo_color.a = 0.6 + 0.35 * absf(sin(_t * 9.0))
	_place_ball()
	if _t >= flight:
		_land()


## Seconds until it lands.
func time_left() -> float:
	return maxf(flight - _t, 0.0)


func _place_ball() -> void:
	var u := clampf(_t / flight, 0.0, 1.0)
	var start := from - position
	# Along the straight line from the start, lifted into an arc.
	_ball.position = start * (1.0 - u) + Vector3.UP * (4.0 * height * u * (1.0 - u) + 0.3)
	_ball.rotation.x = _t * 5.0


func _land() -> void:
	landed = true
	_ball.visible = false
	_ring.visible = false
	_fill.visible = false
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", -8.0, 0.1)
	var h := level.hero if level else null
	if h:
		var d := h.global_position - global_position
		if Vector2(d.x, d.z).length() < radius + 0.25 and d.y > -0.6 and d.y < 1.4:
			var away := global_position
			if knock_to != Vector3.INF:
				var to := level.global_position + knock_to - h.global_position
				to.y = 0.0
				if to.length() > 0.1:
					away = h.global_position - to.normalized()
			level.hurt_hero(away)
	_burst()


func _burst() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.95, 0.85, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in 6:
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.5
		s.radial_segments = 8
		s.rings = 4
		m.mesh = s
		m.material_override = mat
		add_child(m)
		var a := TAU * i / 6.0
		m.position = Vector3(cos(a) * 0.3, 0.2, sin(a) * 0.3)
		var tw := m.create_tween()
		tw.set_parallel()
		tw.tween_property(m, "position", Vector3(cos(a) * 1.1, 0.7, sin(a) * 1.1), 0.4).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "scale", Vector3.ONE * 0.05, 0.45)
	var done := create_tween()
	done.tween_interval(0.5)
	done.tween_callback(queue_free)
