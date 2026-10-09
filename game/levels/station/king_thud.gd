class_name StationKingThud
extends Boss
## King Thud, the grumpiest crusher block in the sky and the Adventure's
## last boss: a giant block in a crown. He hops after the hero, then leaps
## high and hangs there while a red shadow marks where he'll land, and
## slams down. After a big slam he's dizzy for a few seconds with his lid
## open: jump on top and ground pound it. Touch him any other time and it
## hurts. Three hits; each one makes him quicker.

enum Step { WAIT, HOP, PAUSE, LEAP, HANG, SLAM, DAZED, WAKE }

const SIZE := Vector3(2.8, 2.4, 2.8)
const HANG_HEIGHT := 7.0
const LEAP_TIME := 0.55
const SLAM_TIME := 0.24
const HOP_HEIGHT := 1.3
const HOP_REACH := 2.8
## By hits taken: seconds per hop, rest between hops, hops before a slam,
## seconds the shadow shows before the slam, and seconds he stays dizzy.
const HOP_TIME := [0.62, 0.52, 0.45]
const REST := [0.45, 0.35, 0.28]
const HOPS := [3, 3, 4]
const WARNING := [1.25, 1.1, 0.95]
const DIZZY := [3.4, 3.0, 2.7]

## The middle of the arena, and how far from it he goes.
var home := Vector3.ZERO
var reach := 8.0
var step := Step.WAIT
var step_time := 0.0
var hops_left := 3
## Where the next slam lands (the shadow shows it).
var target := Vector3.ZERO
## Hits taken so far.
var rage := 0

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _hop_time := 0.6
var _floor_y := 0.0
var _solid: AnimatableBody3D
var _want_solid := true
var _body: Node3D
var _lid: Node3D
var _dizzy: Node3D
var _shadow: MeshInstance3D
var _shadow_mat: StandardMaterial3D
var _told := false
var _hinted := false
var _face_turn := 0.0


func _ready() -> void:
	super()
	_floor_y = position.y
	if home == Vector3.ZERO:
		home = position
	make_body(SIZE + Vector3(0.5, 0.4, 0.5))
	_solid = AnimatableBody3D.new()
	_solid.collision_layer = Kit.LAYER_WORLD
	_solid.collision_mask = 0
	_solid.sync_to_physics = true
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE
	shape.shape = box
	shape.position.y = SIZE.y / 2.0
	_solid.add_child(shape)
	add_child(_solid)
	_build_look()
	_shadow = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.04
	disc.radial_segments = 32
	_shadow.mesh = disc
	_shadow_mat = StationDeco.glow(Color("ff2d55"), 0.5)
	_shadow.material_override = _shadow_mat
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shadow.top_level = true
	_shadow.visible = false
	add_child(_shadow)


## The look: two crusher blocks with a cross face, and a lid with a crown
## of stars that swings open when he's dizzy, showing a glowing core.
func _build_look() -> void:
	_body = Node3D.new()
	add_child(_body)
	for i in 2:
		var block := Kit.model("block-moving-large")
		block.scale = Vector3(SIZE.x, SIZE.y / 2.0 / 0.5, SIZE.z)
		block.position.y = i * SIZE.y / 2.0
		_body.add_child(block)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color("fffaf0")
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color("2a2233")
	var front := SIZE.z / 2.0 + 0.03
	for s in [-1.0, 1.0]:
		_box(Vector3(0.62, 0.52, 0.06), Vector3(s * 0.62, 1.5, front), white)
		_box(Vector3(0.24, 0.3, 0.06), Vector3(s * 0.55, 1.45, front + 0.04), dark)
		var brow := _box(Vector3(0.85, 0.16, 0.08), Vector3(s * 0.62, 1.92, front + 0.05), dark)
		brow.rotation.z = s * deg_to_rad(-18.0)
	_box(Vector3(1.1, 0.14, 0.06), Vector3(0, 0.82, front), dark)
	for s in [-1.0, 1.0]:
		var corner := _box(Vector3(0.3, 0.14, 0.06), Vector3(s * 0.66, 0.74, front), dark)
		corner.rotation.z = s * deg_to_rad(30.0)
	var core := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(SIZE.x - 0.7, 0.12, SIZE.z - 0.7)
	core.mesh = cb
	core.material_override = StationDeco.glow(Color("ff4d8a"))
	core.position.y = SIZE.y + 0.02
	_body.add_child(core)
	# The lid swings up from its back edge.
	_lid = Node3D.new()
	_lid.position = Vector3(0, SIZE.y, -SIZE.z / 2.0)
	_body.add_child(_lid)
	var plate := Kit.model("block-moving")
	plate.scale = Vector3(SIZE.x - 0.2, 1.0, SIZE.z - 0.2)
	plate.position = Vector3(0, 0, SIZE.z / 2.0)
	_lid.add_child(plate)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffc93c")
	gold.metallic = 0.6
	gold.roughness = 0.35
	var band := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 0.95
	ring.bottom_radius = 0.95
	ring.height = 0.4
	ring.radial_segments = 10
	band.mesh = ring
	band.material_override = gold
	band.position = Vector3(0, 0.5, SIZE.z / 2.0)
	_lid.add_child(band)
	for i in 5:
		var a := TAU * i / 5.0
		var point := Kit.model("star", 2.4)
		point.position = Vector3(sin(a) * 0.85, 0.62, SIZE.z / 2.0 + cos(a) * 0.85)
		point.rotation.y = a
		_lid.add_child(point)
	var jewel := Kit.model("jewel", 2.0)
	jewel.position = Vector3(0, 0.45, SIZE.z / 2.0 + 0.95)
	_lid.add_child(jewel)
	_dizzy = Node3D.new()
	_dizzy.position.y = SIZE.y + 1.6
	_dizzy.visible = false
	add_child(_dizzy)
	for i in 3:
		var star := Kit.model("star", 1.6)
		var a := TAU * i / 3.0
		star.position = Vector3(cos(a), 0, sin(a)) * 1.0
		_dizzy.add_child(star)


func _box(size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	m.mesh = b
	m.material_override = mat
	m.position = at
	_body.add_child(m)
	return m


func is_dazed() -> bool:
	return step == Step.DAZED


## True while he's up high, about to slam down on the shadow.
func is_slamming() -> bool:
	return step in [Step.LEAP, Step.HANG, Step.SLAM]


func think(delta: float) -> void:
	step_time += delta
	if not _told and time > 1.0:
		_told = true
		level.say("After a big slam King Thud gets dizzy: jump on top and ground pound!")
	var h := hero()
	match step:
		Step.WAIT:
			if step_time > 1.8:
				hops_left = HOPS[rage]
				_start_hop(false)
		Step.HOP:
			var u := clampf(step_time / _hop_time, 0.0, 1.0)
			position = _from.lerp(_to, u) + Vector3.UP * sin(PI * u) * HOP_HEIGHT
			if u >= 1.0:
				position.y = _floor_y
				_go(Step.PAUSE)
				_want_solid = true
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactSoft_heavy_000.ogg", -4.0, 0.08)
		Step.PAUSE:
			if step_time > REST[rage]:
				if hops_left > 0:
					_start_hop(false)
				else:
					_start_leap()
		Step.LEAP:
			var u := clampf(step_time / LEAP_TIME, 0.0, 1.0)
			var flat := _from.lerp(target, u)
			position = Vector3(flat.x, _floor_y + HANG_HEIGHT * (1.0 - (1.0 - u) * (1.0 - u)), flat.z)
			_show_shadow(0.4 + 0.3 * u)
			if u >= 1.0:
				_go(Step.HANG)
		Step.HANG:
			var warn: float = WARNING[rage]
			# Follows the hero for the first part, then the spot is set.
			if h and step_time < warn * 0.45:
				target = _clamp(_local(h.global_position))
			position.x = lerpf(position.x, target.x, 1.0 - exp(-10.0 * delta))
			position.z = lerpf(position.z, target.z, 1.0 - exp(-10.0 * delta))
			position.y = _floor_y + HANG_HEIGHT + sin(step_time * 18.0) * 0.06
			_show_shadow(0.7 + 0.3 * clampf(step_time / warn, 0.0, 1.0))
			if step_time > warn:
				_from = position
				_go(Step.SLAM)
		Step.SLAM:
			var u := clampf(step_time / SLAM_TIME, 0.0, 1.0)
			position = Vector3(target.x, _floor_y + HANG_HEIGHT * (1.0 - u * u), target.z)
			if u >= 1.0:
				position.y = _floor_y
				_shadow.visible = false
				_want_solid = true
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", 2.0, 0.05)
				_go(Step.DAZED)
				open = true
		Step.DAZED:
			_lid.rotation.x = lerpf(_lid.rotation.x, deg_to_rad(-55.0), 1.0 - exp(-8.0 * delta))
			_dizzy.visible = true
			_dizzy.rotation.y += delta * 4.0
			if step_time > DIZZY[rage]:
				open = false
				_go(Step.WAKE)
		Step.WAKE:
			_close_lid(delta)
			_body.position.x = sin(step_time * 50.0) * 0.06
			if step_time > 0.55:
				_body.position.x = 0.0
				hops_left = HOPS[rage]
				_start_hop(false)
	if step != Step.DAZED and step != Step.WAKE:
		_close_lid(delta)
	_turn_to_hero(delta)
	_update_solid()
	_check_pound()


func _go(s: Step) -> void:
	step = s
	step_time = 0.0


func _start_hop(home_hop: bool) -> void:
	var h := hero()
	_from = Vector3(position.x, _floor_y, position.z)
	_hop_time = HOP_TIME[rage]
	if home_hop or h == null:
		_to = home
		_hop_time *= 1.4
	else:
		var to_hero := _local(h.global_position) - _from
		to_hero.y = 0.0
		var dist := minf(to_hero.length(), HOP_REACH)
		_to = _clamp(_from + (to_hero.normalized() * dist if to_hero.length() > 0.1 else Vector3.ZERO))
		hops_left -= 1
	_want_solid = false
	_go(Step.HOP)


func _start_leap() -> void:
	var h := hero()
	_from = Vector3(position.x, _floor_y, position.z)
	target = _clamp(_local(h.global_position)) if h else home
	_want_solid = false
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_jump-high.ogg", -2.0)
	_go(Step.LEAP)


## A point in the arena's own space.
func _local(p: Vector3) -> Vector3:
	return p - (get_parent() as Node3D).global_position


## Keeps a spot on the arena, within `reach` of the middle.
func _clamp(p: Vector3) -> Vector3:
	var flat := Vector3(p.x - home.x, 0, p.z - home.z)
	if flat.length() > reach:
		flat = flat.normalized() * reach
	return Vector3(home.x + flat.x, _floor_y, home.z + flat.z)


func _show_shadow(grow: float) -> void:
	_shadow.visible = true
	var r := SIZE.x * 0.62 * grow
	_shadow.global_position = (get_parent() as Node3D).global_position + Vector3(target.x, _floor_y + 0.05, target.z)
	_shadow.scale = Vector3(r, 1, r)
	_shadow_mat.albedo_color.a = 0.35 + 0.25 * absf(sin(time * 9.0))


func _close_lid(delta: float) -> void:
	_lid.rotation.x = lerpf(_lid.rotation.x, 0.0, 1.0 - exp(-12.0 * delta))
	if _dizzy.visible and step != Step.DAZED:
		_dizzy.visible = false


## Turns his face towards the hero, a quarter turn at a time.
func _turn_to_hero(delta: float) -> void:
	var h := hero()
	if h == null or step == Step.DAZED:
		return
	var d := h.global_position - global_position
	var want := roundf(atan2(d.x, d.z) / (PI / 2.0)) * (PI / 2.0)
	_face_turn = lerp_angle(_face_turn, want, 1.0 - exp(-6.0 * delta))
	_body.rotation.y = _face_turn


## Solid on the ground, so the hero can stand on him (and can't walk
## through); not while he's in the air, or while the hero is inside.
func _update_solid() -> void:
	var on := _want_solid and not beaten
	if on and _solid.collision_layer == 0:
		var h := hero()
		if h:
			var d := h.global_position - global_position
			if absf(d.x) < SIZE.x / 2.0 + 0.3 and absf(d.z) < SIZE.z / 2.0 + 0.3 and d.y < SIZE.y - 0.1:
				return
	_solid.collision_layer = Kit.LAYER_WORLD if on else 0


func _check_pound() -> void:
	var h := hero()
	if h and open and h.state in [Hero.State.POUND_FALL, Hero.State.POUND_LAND]:
		_try_pound(h)


## A ground pound on his open lid is a hit.
func _try_pound(h: Hero) -> void:
	if not open or invulnerable > 0.0 or beaten:
		return
	var d := h.global_position - global_position
	if absf(d.x) > SIZE.x / 2.0 + 0.35 or absf(d.z) > SIZE.z / 2.0 + 0.35:
		return
	if d.y < SIZE.y - 0.5 or d.y > SIZE.y + 1.2:
		return
	h.bounce(13.0)
	var away := Vector3(d.x, 0, d.z)
	away = away.normalized() if away.length() > 0.1 else Vector3.BACK
	h.velocity += away * 5.0
	hit()


func _on_touched(body: Node3D) -> void:
	if beaten or level == null or body != level.hero:
		return
	var h := level.hero
	if invulnerable > 0.0:
		return
	if open:
		if h.is_pounding() or h.state == Hero.State.POUND_LAND:
			_try_pound(h)
		elif not _hinted and h.global_position.y > global_position.y + SIZE.y - 0.3:
			_hinted = true
			level.say("Now crouch in the air to ground pound!")
		return
	level.hurt_hero(global_position)


func _on_hit() -> void:
	rage = mini(rage + 1, HOP_TIME.size() - 1)
	_dizzy.visible = false
	level.say(["King Thud: \"Ouch, my crown!\"", "King Thud: \"Grr! Stand still!\""][mini(rage - 1, 1)])
	hops_left = HOPS[rage]
	_start_hop(true)


func _on_beaten() -> void:
	_want_solid = false
	_solid.collision_layer = 0
	_shadow.visible = false
	_dizzy.visible = false
	super()
