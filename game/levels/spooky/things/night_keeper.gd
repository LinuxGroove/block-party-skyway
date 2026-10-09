class_name SpookyNightKeeper
extends Boss
## The Night Keeper, Spooky Hollow's boss: the graveyard's old keeper grown
## huge, with a lantern in one hand and a shovel in the other.
##
## His pattern: he stomps after the hero, stops and lobs slow lantern
## flames, then lifts his shovel high while a glowing ring marks the ground
## where he means to strike. He leaps and slams the shovel down there, and
## it sticks fast. While he tugs at it, bent over, he's open: jump on him,
## ground pound him or dive into him. Three hits, and each one makes him a
## little quicker and adds a flame to his volleys.

enum Phase { WAIT, WALK, THROW, WINDUP, LEAP, STUCK, RECOVER }

const SCALE := 2.9
## The body the hero touches, standing and bent over the stuck shovel.
const STANDING := Vector3(1.6, 2.4, 1.4)
const BENT := Vector3(1.7, 1.4, 1.7)
## How far in front of him the shovel lands, and how wide the slam is.
const REACH := 2.0
const SLAM_RADIUS := 1.8
const FLAME_SPEED := 5.0

var phase := Phase.WAIT
var phase_time := 0.0
## How far from the arena's middle he goes, and where its floor is.
var arena_radius := 8.5
var floor_y := 0.0
var facing := Vector3.BACK
## Hits taken so far: he speeds up with each.
var hits := 0
## Where the shovel will come down (shown by the ring).
var slam_at := Vector3.ZERO
## Seconds his shovel stays stuck, before hits.
var stuck_time := 3.0

var rig: RigCharacter
var _body: Node3D
var _shovel: Node3D
var _lantern: Node3D
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _leap_from := Vector3.ZERO
var _leap_to := Vector3.ZERO
var _thrown := 0
var _next_throw := 0.0
var _told := false


func _ready() -> void:
	super()
	max_health = 3
	health = max_health
	_body = Node3D.new()
	add_child(_body)
	rig = RigCharacter.create(Kit.scene("grave:character-keeper"), SCALE)
	_body.add_child(rig)
	_shovel = Kit.model("grave:shovel", 4.0)
	_body.add_child(_shovel)
	_lantern = Node3D.new()
	_lantern.position = Vector3(1.15, 0.65, 0.3)
	_lantern.add_child(Kit.model("grave:lantern-candle", 2.6))
	var glow := OmniLight3D.new()
	glow.light_color = Color("ffb45a")
	glow.light_energy = 2.2
	glow.omni_range = 6.0
	glow.position.y = 0.45
	_lantern.add_child(glow)
	_body.add_child(_lantern)
	_shovel_pose("carry")
	make_body(STANDING)
	_ring = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = SLAM_RADIUS
	disc.bottom_radius = SLAM_RADIUS
	disc.height = 0.04
	_ring.mesh = disc
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring_mat.albedo_color = Color(1.0, 0.35, 0.2, 0.4)
	_ring.material_override = _ring_mat
	_ring.top_level = true
	_ring.visible = false
	add_child(_ring)
	floor_y = position.y
	_face(facing)


## Quicker with each hit.
func pace() -> float:
	return 1.0 + 0.2 * hits


func is_stuck() -> bool:
	return phase == Phase.STUCK


func think(delta: float) -> void:
	phase_time += delta
	var h := hero()
	match phase:
		Phase.WAIT:
			rig.play("idle")
			if phase_time > 1.0 and not _told:
				_told = true
				level.say("When his shovel sticks in the ground, jump on him!")
			if phase_time > 1.6:
				_go(Phase.WALK)
		Phase.WALK:
			var to := _flat(h.global_position - global_position) if h else Vector3.ZERO
			if to.length() > 3.2:
				_face(to)
				_move(to.normalized() * 1.9 * pace() * delta)
				rig.play("walk", 0.15, 1.2)
			else:
				rig.play("idle")
			if phase_time > 2.0 or (to.length() <= 3.2 and phase_time > 0.6):
				_go(Phase.THROW)
				_thrown = 0
				_next_throw = 0.35
		Phase.THROW:
			rig.play("idle")
			if h:
				_face(_flat(h.global_position - global_position))
			if phase_time >= _next_throw:
				if _thrown < 2 + hits:
					_throw()
					_thrown += 1
					_next_throw = phase_time + 0.8 / pace()
				else:
					_start_windup()
		Phase.WINDUP:
			var pulse := 0.3 + 0.25 * (0.5 + 0.5 * sin(phase_time * 14.0))
			_ring_mat.albedo_color.a = pulse
			if phase_time > _windup_time():
				_go(Phase.LEAP)
				_leap_from = position
				_leap_to = _clamp(slam_at - facing * REACH)
		Phase.LEAP:
			var u := clampf(phase_time / 0.6, 0.0, 1.0)
			position = _leap_from.lerp(_leap_to, u) + Vector3.UP * (4.0 * 2.2 * u * (1.0 - u))
			if u >= 1.0:
				_slam()
		Phase.STUCK:
			# Tugging at the shovel.
			_body.rotation.y = atan2(facing.x, facing.z) + sin(phase_time * 22.0) * 0.06
			if phase_time > stuck_time - 0.25 * hits:
				_pull_free()
		Phase.RECOVER:
			rig.play("idle")
			if phase_time > 0.9:
				_go(Phase.WALK)


func _go(p: Phase) -> void:
	phase = p
	phase_time = 0.0


func _windup_time() -> float:
	return maxf(1.25 - 0.15 * hits, 0.9)


func _start_windup() -> void:
	_go(Phase.WINDUP)
	var h := hero()
	slam_at = _clamp(h.global_position if h else global_position + facing * 3.0)
	slam_at.y = floor_y
	var to := _flat(slam_at - global_position)
	if to.length() > 0.2:
		_face(to)
	_ring.global_position = slam_at + Vector3.UP * 0.03
	_ring.visible = true
	rig.play("holding-both")
	_shovel_pose("raised", 0.5)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_disappear.ogg", -6.0, 0.05)


## The shovel comes down where the ring was; it sticks fast.
func _slam() -> void:
	_go(Phase.STUCK)
	position = _leap_to
	_ring.visible = false
	_shovel_pose("stuck", 0.08)
	rig.play("crouch")
	_set_body(BENT)
	open = true
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_heavy_000.ogg", -2.0, 0.05)
	_dust(slam_at)
	var h := hero()
	if h and _flat(h.global_position - slam_at).length() < SLAM_RADIUS + 0.3 and h.global_position.y < floor_y + 1.2:
		level.hurt_hero(slam_at)


func _pull_free() -> void:
	_go(Phase.RECOVER)
	open = false
	_set_body(STANDING)
	_shovel_pose("carry", 0.25)
	_face(facing)


func _on_hit() -> void:
	hits += 1
	_ring.visible = false
	_pull_free()
	rig.play_once("emote-no")
	# Send the hero bouncing clear, so they don't come down on his head.
	var h := hero()
	if h:
		var away := _flat(h.global_position - global_position)
		if away.length() < 0.2:
			away = -facing
		h.velocity += away.normalized() * 6.0


## Just after a hit he's reeling: touching him doesn't hurt while the hero
## bounces away.
func _on_touched(body: Node3D) -> void:
	if invulnerable > 0.0:
		return
	super(body)


func _on_beaten() -> void:
	_ring.visible = false
	super()


func _throw() -> void:
	var h := hero()
	if h == null:
		return
	rig.play_once("interact-right", 0.05, 1.6)
	var f := SpookyFlame.new()
	var from := _lantern.global_position + Vector3.UP * 0.5
	var target := h.global_position + Vector3.UP * 0.45
	f.velocity = (target - from).normalized() * FLAME_SPEED
	f.life = 6.0
	level.add(f, from - level.global_position)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -6.0, 0.1)


## Puts the shovel in one of its poses: "carry" (upright at his side),
## "raised" (high over his head) or "stuck" (blade in the ground in front).
func _shovel_pose(pose: String, seconds := 0.0) -> void:
	var at := Vector3(-1.15, 0.0, 0.4)
	var turn := Vector3.ZERO
	match pose:
		"raised":
			at = Vector3(-0.3, 4.6, -0.5)
			turn = Vector3(deg_to_rad(200.0), 0, 0)
		"stuck":
			at = Vector3(0, -0.35, REACH)
			turn = Vector3(deg_to_rad(-25.0), 0, 0)
	if seconds <= 0.0:
		_shovel.position = at
		_shovel.rotation = turn
		return
	var tw := create_tween().set_parallel()
	tw.tween_property(_shovel, "position", at, seconds).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(_shovel, "rotation", turn, seconds).set_trans(Tween.TRANS_QUAD)


func _set_body(size: Vector3) -> void:
	_touch_size = size
	var shape := _touch.get_child(0) as CollisionShape3D
	(shape.shape as BoxShape3D).size = size
	shape.position.y = size.y / 2.0


func _face(dir: Vector3) -> void:
	var flat := _flat(dir)
	if flat.length() < 0.01:
		return
	facing = flat.normalized()
	_body.rotation.y = atan2(facing.x, facing.z)


func _move(step: Vector3) -> void:
	position = _clamp(position + step)


## Keeps a point on the arena floor, inside its edge.
func _clamp(p: Vector3) -> Vector3:
	var flat := Vector2(p.x, p.z)
	if flat.length() > arena_radius:
		flat = flat.normalized() * arena_radius
	return Vector3(flat.x, floor_y, flat.y)


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0, v.z)


## A puff of earth where the shovel lands.
func _dust(at: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("6b5a7a")
	for i in 8:
		var m := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 0.25
		m.mesh = cube
		m.material_override = mat
		level.add_child(m)
		var a := TAU * i / 8.0
		m.global_position = at + Vector3(cos(a) * 0.4, 0.2, sin(a) * 0.4)
		var to := at + Vector3(cos(a) * 1.8, 0.6 + randf() * 0.6, sin(a) * 1.8)
		var tw := m.create_tween().set_parallel()
		tw.tween_property(m, "global_position", to, 0.4).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "scale", Vector3.ONE * 0.01, 0.45)
		tw.chain().tween_callback(m.queue_free)
