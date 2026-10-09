class_name GearsBigPress
extends Boss
## The Big Press, Gear Works' boss: a huge press head hung from a gantry
## over the arena. It follows you while a warning glows on the floor under
## it, holds still when the warning turns red, then slams down there. After
## a few slams it lifts high over the middle for its big slam: a ring of
## force runs out across the floor (jump it), and the press is left stuck
## in the floor with its hatch open. Jump on top or ground pound it. Each
## hit makes it follow faster, slam more and stay stuck for less time.

enum Phase { INTRO, AIM, SLAM, DOWN, RISE, BIG_AIM, BIG_SLAM, STUCK, SHUDDER }

## The head's footprint and height.
const HEAD := Vector3(4, 1.6, 4)
## How high the head's bottom hovers while aiming, and for the big slam.
const HOVER := 5.5
const BIG_HOVER := 7.5
## How far the big slam drives it into the floor.
const SINK := 0.5
## Where the gantry runs, above the arena.
const GANTRY_Y := 11.0
## Seconds the warning holds still (red) before a slam: time to get out.
const LOCK := 0.45
const SLAM_TIME := 0.15
const DOWN_TIME := 0.45
const RISE_TIME := 0.6
## Seconds of warning before the big slam.
const BIG_WARN := 1.6
const BIG_SLAM_TIME := 0.2
const SHUDDER_TIME := 0.7
## The ring of force from the big slam: how fast it runs out, how far, and
## how high it reaches.
const RING_SPEED := 7.0
const RING_END := 16.0
const RING_HIGH := 0.45
## Per round (three hits left, two, one): seconds following, follow speed,
## slams before the big one, and seconds stuck.
const AIM_TIMES := [1.6, 1.3, 1.05]
const FOLLOW := [6.0, 7.5, 9.0]
const SLAMS := [3, 4, 5]
const STUCK_TIMES := [4.2, 3.6, 3.0]

## How far from the middle the head may go.
var reach := 9.0
var phase := Phase.INTRO
var phase_time := 0.0
## Height of the head's bottom above the floor.
var head_y := HOVER
## Small slams since the last big one.
var slams_done := 0
## The ring's radius, or below zero when there's none.
var ring_radius := -1.0

var _rise_from := 0.0
var _head: Node3D
var _lid: Node3D
var _button: Node3D
var _warning: MeshInstance3D
var _warn_mat: StandardMaterial3D
var _solid: StaticBody3D
var _solid_shape: CollisionShape3D
var _ring: Node3D
var _ring_bits: Array[MeshInstance3D] = []
var _bridge: Node3D
var _trolley: Node3D
var _shaft: MeshInstance3D
var _steam: Array[MeshInstance3D] = []


func _ready() -> void:
	super()
	boss_name = "The Big Press"
	make_body(HEAD + Vector3(0.3, 0.2, 0.3))
	_build_head()
	_build_gantry()
	_build_warning()
	_build_ring()
	_build_solid()
	_place()


func round_index() -> int:
	return clampi(max_health - health, 0, 2)


## True while the press sits jammed in the floor, open to a hit.
func is_stuck() -> bool:
	return phase == Phase.STUCK


func think(delta: float) -> void:
	phase_time += delta
	_tick_ring(delta)
	var r := round_index()
	match phase:
		Phase.INTRO:
			if phase_time > 0.6 and phase_time - delta <= 0.6:
				level.say("When the press gets stuck, jump on top or ground pound it!")
			_warning.visible = false
			if phase_time > 2.6:
				_go(Phase.AIM)
		Phase.AIM:
			var aim: float = AIM_TIMES[r]
			var locked := phase_time > aim - LOCK
			if not locked:
				_follow(_hero_spot(), FOLLOW[r], delta)
			_show_warning(1.0, locked)
			if locked and phase_time - delta <= aim - LOCK:
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/error_004.ogg", -8.0)
			if phase_time >= aim:
				_go(Phase.SLAM)
		Phase.SLAM:
			var u := minf(phase_time / SLAM_TIME, 1.0)
			head_y = lerpf(HOVER, 0.0, u * u)
			_show_warning(1.0, true)
			if u >= 1.0:
				_landed(false)
				_go(Phase.DOWN)
		Phase.DOWN:
			_warning.visible = false
			if phase_time >= DOWN_TIME:
				slams_done += 1
				_lift_off()
		Phase.RISE:
			var u := minf(phase_time / RISE_TIME, 1.0)
			head_y = lerpf(_rise_from, HOVER, smoothstep(0.0, 1.0, u))
			if u >= 1.0:
				_go(Phase.BIG_AIM if slams_done >= SLAMS[r] else Phase.AIM)
		Phase.BIG_AIM:
			_follow(Vector3.ZERO, 9.0, delta)
			head_y = lerpf(head_y, BIG_HOVER, minf(delta * 3.0, 1.0))
			_show_warning(1.6, phase_time > BIG_WARN - LOCK)
			if phase_time >= BIG_WARN and Vector2(position.x, position.z).length() < 0.05:
				_go(Phase.BIG_SLAM)
		Phase.BIG_SLAM:
			var u := minf(phase_time / BIG_SLAM_TIME, 1.0)
			head_y = lerpf(BIG_HOVER, -SINK, u * u)
			_show_warning(1.6, true)
			if u >= 1.0:
				_landed(true)
				_go(Phase.STUCK)
				open = true
				_open_hatch(true)
		Phase.STUCK:
			_warning.visible = false
			_tick_steam(delta)
			_check_stomp()
			if beaten or phase != Phase.STUCK:
				return
			if phase_time >= STUCK_TIMES[r]:
				open = false
				_open_hatch(false)
				slams_done = 0
				_lift_off()
		Phase.SHUDDER:
			_head.position.x = sin(phase_time * 70.0) * 0.06
			if phase_time >= SHUDDER_TIME:
				_head.position.x = 0.0
				slams_done = 0
				_lift_off()
	_tick_solid()
	_place()


## Where the hero stands, kept within the press's reach.
func _hero_spot() -> Vector3:
	var at := hero().global_position - level.global_position
	return Vector3(clampf(at.x, -reach, reach), 0, clampf(at.z, -reach, reach))


func _follow(target: Vector3, speed: float, delta: float) -> void:
	var flat := Vector3(position.x, 0, position.z)
	var to := target - flat
	var step := speed * delta
	if to.length() <= step:
		flat = target
	else:
		flat += to.normalized() * step
	position.x = flat.x
	position.z = flat.z
	# Turn the face towards the hero, slowly.
	var look := hero().global_position - global_position
	if Vector2(look.x, look.z).length() > 0.5:
		_head.rotation.y = lerp_angle(_head.rotation.y, atan2(look.x, look.z), minf(delta * 3.0, 1.0))


func _go(p: Phase) -> void:
	phase = p
	phase_time = 0.0


func _lift_off() -> void:
	_rise_from = head_y
	_set_solid(false)
	_go(Phase.RISE)


## The head hits the floor: anyone under it is knocked away.
func _landed(big: bool) -> void:
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactSoft_heavy_000.ogg", 2.0 if big else -1.0, 0.05)
	if _under(0.3) and hero().global_position.y < level.global_position.y + 1.8:
		level.hurt_hero(global_position)
	if big:
		ring_radius = HEAD.x * 0.55
		_ring.visible = true


## True when the hero stands within the head's footprint (plus `pad`).
func _under(pad: float) -> bool:
	var at := hero().global_position - global_position
	return absf(at.x) < HEAD.x / 2.0 + pad and absf(at.z) < HEAD.z / 2.0 + pad


## Landing on the stuck press's top counts as a stomp, even before its
## body notices the touch.
func _check_stomp() -> void:
	var h := hero()
	if not open or invulnerable > 0.0 or not h.is_on_floor() or not _under(0.0):
		return
	if h.global_position.y > global_position.y + head_y + HEAD.y - 0.2:
		h.bounce(13.0)
		hit()


func _on_touched(body: Node3D) -> void:
	if beaten or body != level.hero:
		return
	var h := level.hero
	if phase == Phase.STUCK:
		var above := _above <= 3 and h.velocity.y < 1.0
		if open and invulnerable <= 0.0 and (h.is_pounding() or above):
			h.bounce(13.0)
			hit()
		return
	# Only a falling head hurts; resting, rising or hanging, it's just steel.
	if phase in [Phase.SLAM, Phase.BIG_SLAM]:
		level.hurt_hero(global_position)


func _on_hit() -> void:
	_open_hatch(false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_bump.ogg", 0.0)
	_go(Phase.SHUDDER)
	if health == 1:
		level.say("It's nearly done for. Once more!")


func _on_beaten() -> void:
	open = false
	_open_hatch(false)
	_set_solid(false)
	if _touch:
		_touch.set_deferred("monitoring", false)
	_warning.visible = false
	_ring.visible = false
	ring_radius = -1.0
	for s in _steam:
		s.visible = false
	# Shake, then haul the head up into the gantry and away.
	var tw := create_tween()
	tw.tween_method(_shake, 0.0, 1.0, 0.6)
	tw.tween_method(_haul, head_y, GANTRY_Y + 4.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_head.hide)


func _shake(u: float) -> void:
	_head.position.x = sin(u * 60.0) * 0.08 * (1.0 - u)


func _haul(y: float) -> void:
	head_y = y
	_place()


# --- The pieces -----------------------------------------------------------------

func _build_head() -> void:
	_head = Node3D.new()
	add_child(_head)
	var block := Kit.model("block-moving-large")
	block.scale = HEAD / Vector3(1, 0.5, 1)
	_head.add_child(block)
	# A face: a wide screen on the front, and warning lights either side.
	var face := Kit.model("factory:screen-wide", 1.6)
	face.position = Vector3(0, 0.15, HEAD.z / 2.0 + 0.2)
	_head.add_child(face)
	for x in [-1.6, 1.6]:
		var lamp := Kit.model("factory:warning-orange", 0.9)
		lamp.position = Vector3(x, HEAD.y, HEAD.z / 2.0 - 0.3)
		_head.add_child(lamp)
	# The hatch on top, hinged at the back, over a big red button.
	_button = Kit.model("button-round", 3.0)
	_button.position = Vector3(0, HEAD.y - 0.5, 0)
	_head.add_child(_button)
	var hinge := Node3D.new()
	hinge.position = Vector3(0, HEAD.y + 0.02, -1.7)
	_head.add_child(hinge)
	var plate := Kit.model("factory:top-large-checkerboard")
	plate.scale = Vector3(1.7, 1, 1.7)
	plate.position = Vector3(0, 0, 1.7)
	hinge.add_child(plate)
	_lid = hinge


func _open_hatch(on: bool) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(_lid, "rotation:x", -1.9 if on else 0.0, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_button, "position:y", HEAD.y - (0.02 if on else 0.5), 0.3)
	if on:
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/open_001.ogg", -2.0)


## The bridge, the trolley and the shaft the head hangs from. They're
## top-level, so they keep to the gantry while the boss moves.
func _build_gantry() -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color("#4b5563")
	steel.roughness = 0.6
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color("#e2b33c")
	yellow.roughness = 0.7
	_bridge = Node3D.new()
	_bridge.top_level = true
	add_child(_bridge)
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.7, 24.6)
	beam.mesh = bm
	beam.material_override = yellow
	_bridge.add_child(beam)
	_trolley = Node3D.new()
	_trolley.top_level = true
	add_child(_trolley)
	var cart := Kit.model("factory:machine", 1.4)
	cart.position.y = -0.9
	_trolley.add_child(cart)
	_shaft = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.4
	cyl.height = 1.0
	_shaft.mesh = cyl
	_shaft.material_override = steel
	_shaft.top_level = true
	add_child(_shaft)


func _build_warning() -> void:
	_warn_mat = StandardMaterial3D.new()
	_warn_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_warn_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_warn_mat.albedo_color = Color(1, 0.6, 0.1, 0.5)
	_warning = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HEAD.x + 0.4, HEAD.z + 0.4)
	_warning.mesh = plane
	_warning.material_override = _warn_mat
	_warning.top_level = true
	_warning.visible = false
	add_child(_warning)


## Shows the warning under the head: orange and pulsing while it follows,
## red and quick once it holds still.
func _show_warning(size: float, locked: bool) -> void:
	_warning.visible = true
	_warning.scale = Vector3(size, 1, size)
	var pulse := 0.5 + 0.5 * sin(time * (22.0 if locked else 9.0))
	var c := Color(0.95, 0.15, 0.1) if locked else Color(1, 0.6, 0.1)
	c.a = 0.35 + 0.35 * pulse
	_warn_mat.albedo_color = c


func _build_ring() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 0.8, 0.3, 0.75)
	_ring = Node3D.new()
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, RING_HIGH * 0.8, 1.0)
	for i in 40:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = mat
		_ring.add_child(m)
		_ring_bits.append(m)
	var puff := StandardMaterial3D.new()
	puff.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.albedo_color = Color(1, 1, 1, 0.5)
	var ball := SphereMesh.new()
	ball.radius = 0.25
	ball.height = 0.5
	for i in 8:
		var s := MeshInstance3D.new()
		s.mesh = ball
		s.material_override = puff
		s.visible = false
		_head.add_child(s)
		_steam.append(s)


## Runs the ring outwards; jump it, or it knocks you over.
func _tick_ring(delta: float) -> void:
	if ring_radius < 0.0:
		return
	ring_radius += RING_SPEED * delta
	if ring_radius > RING_END:
		ring_radius = -1.0
		_ring.visible = false
		return
	var centre := global_position
	_ring.global_position = Vector3(centre.x, level.global_position.y + RING_HIGH * 0.4, centre.z)
	var n := _ring_bits.size()
	for i in n:
		var a := TAU * i / n
		var m := _ring_bits[i]
		m.position = Vector3(sin(a), 0, cos(a)) * ring_radius
		m.rotation.y = a + PI / 2.0
		m.scale.z = TAU * ring_radius / n
	var h := hero()
	var off := h.global_position - centre
	var d := Vector2(off.x, off.z).length()
	if absf(d - ring_radius) < 0.5 and h.global_position.y < level.global_position.y + RING_HIGH:
		level.hurt_hero(centre)


func _tick_steam(_delta: float) -> void:
	for i in _steam.size():
		var s := _steam[i]
		s.visible = true
		var u := fposmod(phase_time * 0.9 + i / float(_steam.size()), 1.0)
		var a := TAU * i / _steam.size()
		s.position = Vector3(sin(a) * 2.3, HEAD.y * 0.5 + u * 2.0, cos(a) * 2.3)
		s.scale = Vector3.ONE * (0.6 + u)
	if phase_time + 0.05 >= STUCK_TIMES[round_index()]:
		for s in _steam:
			s.visible = false


## A solid box where the head rests, so it can be stood on.
func _build_solid() -> void:
	_solid = StaticBody3D.new()
	_solid.collision_layer = 0
	_solid.collision_mask = 0
	_solid_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = HEAD
	_solid_shape.shape = box
	_solid.add_child(_solid_shape)
	add_child(_solid)


func _set_solid(on: bool) -> void:
	_solid.collision_layer = Kit.LAYER_WORLD if on else 0


## While the head rests on the floor it's solid, once the hero is clear.
func _tick_solid() -> void:
	var resting := phase in [Phase.DOWN, Phase.STUCK, Phase.SHUDDER]
	if not resting:
		if _solid.collision_layer != 0:
			_set_solid(false)
	elif _solid.collision_layer == 0 and not _under(0.35):
		_set_solid(true)


func _place() -> void:
	var base := level.global_position.y if level else 0.0
	_head.position.y = head_y
	if _touch:
		_touch.position.y = head_y
	_solid.position.y = head_y + HEAD.y / 2.0
	var at := global_position
	_bridge.global_position = Vector3(at.x, base + GANTRY_Y + 0.6, 0)
	_trolley.global_position = Vector3(at.x, base + GANTRY_Y, at.z)
	var top := at.y + head_y + HEAD.y
	var bottom := base + GANTRY_Y - 0.9
	var length := maxf(bottom - top, 0.05)
	_shaft.global_position = Vector3(at.x, top + length / 2.0, at.z)
	_shaft.scale = Vector3(1, length, 1)
	_warning.global_position = Vector3(at.x, base + 0.04, at.z)
