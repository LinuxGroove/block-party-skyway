class_name Hero
extends CharacterBody3D
## The astronaut: every move, tuned in one place, on the fixed physics tick so
## it behaves the same at any frame rate.
##
## Moves: walk and run, jump and double jump, high jump (crouch, then jump),
## long jump (crouch while running, then jump), dive (in the air, or from a
## run), ground pound (crouch in the air), wall slide and wall jump. Kenney's
## rig has no clips for the new moves, so the body is tipped and spun in code.

signal jumped(kind: String)
signal landed(speed: float)
signal pounded(at: Vector3)
signal hurt_taken
signal stepped

enum State { GROUND, AIR, WALL, DIVE, SLIDE, POUND_SPIN, POUND_FALL, POUND_LAND, HURT, LOCKED }

const WALK_SPEED := 4.2
const RUN_SPEED := 7.2
const CROUCH_SPEED := 2.0
const GROUND_ACCEL := 34.0
const GROUND_DECEL := 30.0
const SKID_DECEL := 60.0
const AIR_ACCEL := 15.0
const GRAVITY := 32.0
## Gravity after the top of a jump, or once jump is let go: short taps make
## short hops.
const FALL_GRAVITY := 46.0
const MAX_FALL := 24.0
const JUMP_SPEED := 10.8
const DOUBLE_JUMP_SPEED := 10.2
const HIGH_JUMP_SPEED := 14.2
const LONG_JUMP_UP := 8.4
const LONG_JUMP_FORWARD := 11.5
const LONG_JUMP_GRAVITY := 22.0
const DIVE_SPEED := 10.0
const DIVE_UP := 4.8
const SLIDE_FRICTION := 13.0
const POUND_SPIN_TIME := 0.26
const POUND_SPEED := 26.0
const POUND_LAND_TIME := 0.22
const POUND_JUMP_SPEED := 13.6
const WALL_SLIDE_SPEED := 2.6
const WALL_JUMP_UP := 11.4
const WALL_JUMP_OUT := 6.6
const SPRING_SPEED := 18.0
## Seconds after leaving a ledge when jump still works, and seconds a jump
## press waits for the ground.
const COYOTE := 0.1
const JUMP_BUFFER := 0.13
const HURT_TIME := 0.45
const SAFE_TIME := 1.4
## Ledges this low are walked up without a jump.
const STEP_HEIGHT := 0.32
## Below this the hero has fallen off the world.
const KILL_Y := -14.0

var input := HeroInput.new()
var state := State.AIR
## The way the hero faces, flat and unit length.
var facing := Vector3.BACK
var crouching := false
var can_double := true
var can_dive := true
## Seconds left in the current state where that matters (spin, landing, hurt).
var state_time := 0.0
var safe_time := 0.0
var wall_normal := Vector3.ZERO
## Steering is weak for a moment after a wall jump or a bonk, so the hero
## doesn't drift straight back.
var steer_lock := 0.0
var jump_kind := ""
var last_floor_y := 0.0
## Ticks of play, for tests and ghosts.
var ticks := 0

var body: Node3D
var rig: RigCharacter
var shadow: BlobShadow
var _coyote := 0.0
var _buffer := 0.0
var _cut := false
var _was_on_floor := false
var _step_dist := 0.0
var _spin := 0.0
var _squash := 1.0
var _pitch := 0.0
var _hero_index := -1


func _init() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_max_angle = deg_to_rad(50.0)
	floor_snap_length = 0.25
	floor_constant_speed = true
	floor_stop_on_slope = true
	platform_on_leave = CharacterBody3D.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 0.86
	shape.shape = capsule
	shape.position.y = 0.43
	add_child(shape)
	body = Node3D.new()
	body.name = "Body"
	body.position.y = 0.42
	add_child(body)


func _ready() -> void:
	set_hero(GameConfig.hero_index())
	shadow = BlobShadow.new()
	shadow.hero = self
	add_child(shadow)


## Swaps the astronaut's model (0 to 4, see GameConfig.HEROES).
func set_hero(i: int) -> void:
	if i == _hero_index and rig:
		return
	_hero_index = i
	if rig:
		rig.queue_free()
	rig = RigCharacter.create(GameConfig.hero_scene(i))
	rig.position.y = -0.42
	body.add_child(rig)


func place(at: Vector3, face := Vector3.BACK) -> void:
	global_position = at
	velocity = Vector3.ZERO
	facing = Vector3(face.x, 0, face.z).normalized() if face.length() > 0.01 else Vector3.BACK
	state = State.AIR
	crouching = false
	can_double = true
	can_dive = true
	steer_lock = 0.0
	last_floor_y = at.y
	_pitch = 0.0
	_spin = 0.0
	_update_body(0.0)
	reset_physics_interpolation()


## Freezes the controls for `seconds` (a star, a door, a conversation).
func lock(seconds: float) -> void:
	state = State.LOCKED
	state_time = seconds
	velocity.x = 0.0
	velocity.z = 0.0


func is_locked() -> bool:
	return state == State.LOCKED


## Springs and stomps: an upward launch that gives the air moves back.
func bounce(speed := SPRING_SPEED) -> void:
	velocity.y = speed
	state = State.AIR
	jump_kind = "bounce"
	can_double = true
	can_dive = true
	_cut = false
	_coyote = 0.0
	if rig:
		rig.play_once("jump", 0.05)
	jumped.emit("bounce")


## Knocks the hero away from `from`. Returns false while still blinking from
## the last hit.
func take_hit(from: Vector3) -> bool:
	if safe_time > 0.0 or state == State.LOCKED:
		return false
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -facing
	velocity = away * 6.0 + Vector3.UP * 7.5
	state = State.HURT
	state_time = HURT_TIME
	safe_time = SAFE_TIME
	crouching = false
	hurt_taken.emit()
	return true


func is_pounding() -> bool:
	return state in [State.POUND_SPIN, State.POUND_FALL]


func is_diving() -> bool:
	return state == State.DIVE or state == State.SLIDE


## How far the body is tipped forward (dives, flips), for ghosts.
func pose_pitch() -> float:
	return _pitch + _spin


func horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _physics_process(delta: float) -> void:
	step(delta)


## One tick of movement. Tests call this directly.
func step(delta: float) -> void:
	ticks += 1
	safe_time = maxf(safe_time - delta, 0.0)
	steer_lock = maxf(steer_lock - delta, 0.0)
	if input.jump:
		_buffer = JUMP_BUFFER
	else:
		_buffer = maxf(_buffer - delta, 0.0)
	match state:
		State.GROUND:
			_ground(delta)
		State.AIR:
			_air(delta)
		State.WALL:
			_wall(delta)
		State.DIVE:
			_dive(delta)
		State.SLIDE:
			_slide(delta)
		State.POUND_SPIN:
			_pound_spin(delta)
		State.POUND_FALL:
			_pound_fall(delta)
		State.POUND_LAND:
			_pound_land(delta)
		State.HURT:
			_hurt(delta)
		State.LOCKED:
			_locked(delta)
	var before := velocity
	move_and_slide()
	_after_move(before, delta)
	_update_body(delta)


func _ground(delta: float) -> void:
	_coyote = COYOTE
	can_double = true
	can_dive = true
	var was_crouching := crouching
	crouching = input.crouch
	if crouching and not was_crouching and horizontal_speed() > 3.0:
		_play_once("crouch")
	var top := RUN_SPEED if input.run else WALK_SPEED
	if crouching:
		top = CROUCH_SPEED
	var target := input.move * top
	var flat := Vector3(velocity.x, 0, velocity.z)
	var accel := GROUND_ACCEL
	if target.length() < 0.01:
		# Crouching at speed is a short slide that keeps the run going into a
		# long jump.
		accel = GROUND_DECEL * (0.35 if crouching else 1.0)
	elif flat.length() > 1.0 and flat.normalized().dot(target.normalized()) < -0.3:
		accel = SKID_DECEL
	elif crouching and flat.length() > top:
		accel = GROUND_DECEL * 0.35
	flat = flat.move_toward(target, accel * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y = minf(velocity.y, 0.0) - GRAVITY * delta * 0.1
	if flat.length() > 0.4:
		_turn_toward(flat, 16.0, delta)
	elif input.move.length() > 0.2:
		_turn_toward(input.move, 16.0, delta)
	if _buffer > 0.0:
		_buffer = 0.0
		if crouching and flat.length() > 4.5:
			_long_jump()
		elif crouching:
			_jump(HIGH_JUMP_SPEED, "high")
			velocity.x *= 0.3
			velocity.z *= 0.3
		else:
			_jump(JUMP_SPEED, "jump")
	elif input.dive and flat.length() > 3.0:
		_start_dive(true)


func _air(delta: float) -> void:
	_coyote = maxf(_coyote - delta, 0.0)
	crouching = false
	if _buffer > 0.0:
		if _coyote > 0.0:
			_buffer = 0.0
			_jump(JUMP_SPEED, "jump")
		elif can_double:
			_buffer = 0.0
			can_double = false
			_jump(DOUBLE_JUMP_SPEED, "double")
	if input.crouch_pressed and _coyote <= 0.0:
		_start_pound()
		return
	if input.dive and can_dive:
		_start_dive(false)
		return
	_steer(delta, AIR_ACCEL)
	_fall(delta)


func _wall(delta: float) -> void:
	can_dive = true
	velocity.x = -wall_normal.x * 0.5
	velocity.z = -wall_normal.z * 0.5
	velocity.y = maxf(velocity.y - GRAVITY * delta, -WALL_SLIDE_SPEED)
	facing = Vector3(wall_normal.x, 0, wall_normal.z).normalized()
	if _buffer > 0.0:
		_buffer = 0.0
		velocity = wall_normal * WALL_JUMP_OUT
		velocity.y = WALL_JUMP_UP
		state = State.AIR
		jump_kind = "wall"
		steer_lock = 0.22
		can_double = true
		_cut = false
		_play_once("jump")
		jumped.emit("wall")
		return
	# Pull away from the wall, or press crouch, to let go.
	state_time -= delta
	if (input.move.dot(wall_normal) > 0.5 and state_time <= 0.0) or input.crouch_pressed:
		state = State.AIR
		velocity += wall_normal * 1.5


func _dive(delta: float) -> void:
	var flat := Vector3(velocity.x, 0, velocity.z)
	if input.move.length() > 0.2 and flat.length() > 0.1:
		# A little steering, like leaning while flying.
		var turned := flat.slerp(input.move.normalized() * flat.length(), clampf(2.0 * delta, 0.0, 1.0))
		velocity.x = turned.x
		velocity.z = turned.z
		facing = turned.normalized()
	velocity.y = maxf(velocity.y - GRAVITY * delta, -MAX_FALL)


func _slide(delta: float) -> void:
	state_time -= delta
	var flat := Vector3(velocity.x, 0, velocity.z)
	flat = flat.move_toward(Vector3.ZERO, SLIDE_FRICTION * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	velocity.y = minf(velocity.y, 0.0) - GRAVITY * delta * 0.1
	if _buffer > 0.0:
		# Rolling out of a belly slide keeps the speed.
		_buffer = 0.0
		_jump(JUMP_SPEED * 0.8, "rollout")
		return
	if state_time <= 0.0 or flat.length() < 1.2:
		state = State.GROUND


func _pound_spin(delta: float) -> void:
	state_time -= delta
	velocity = Vector3.ZERO
	_spin = TAU * (1.0 - state_time / POUND_SPIN_TIME)
	if state_time <= 0.0:
		_spin = 0.0
		state = State.POUND_FALL
		velocity.y = -POUND_SPEED


func _pound_fall(_delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = -POUND_SPEED


func _pound_land(delta: float) -> void:
	state_time -= delta
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = -1.0
	if _buffer > 0.0:
		_buffer = 0.0
		_jump(POUND_JUMP_SPEED, "pound")
		return
	if state_time <= 0.0:
		state = State.GROUND


func _hurt(delta: float) -> void:
	state_time -= delta
	_fall(delta)
	if state_time <= 0.0:
		state = State.GROUND if is_on_floor() else State.AIR


func _locked(delta: float) -> void:
	state_time -= delta
	velocity.x = move_toward(velocity.x, 0.0, GROUND_DECEL * delta)
	velocity.z = move_toward(velocity.z, 0.0, GROUND_DECEL * delta)
	_fall(delta)
	if state_time <= 0.0:
		state = State.GROUND if is_on_floor() else State.AIR


func _jump(speed: float, kind: String) -> void:
	velocity.y = speed
	state = State.AIR
	jump_kind = kind
	_coyote = 0.0
	_cut = false
	crouching = false
	_play_once("jump")
	jumped.emit(kind)


func _long_jump() -> void:
	var dir := Vector3(velocity.x, 0, velocity.z).normalized()
	if input.move.length() > 0.3:
		dir = dir.slerp(input.move.normalized(), 0.3).normalized()
	velocity = dir * maxf(LONG_JUMP_FORWARD, horizontal_speed())
	facing = dir
	_jump(LONG_JUMP_UP, "long")


func _start_dive(from_ground: bool) -> void:
	var dir := input.move.normalized() if input.move.length() > 0.3 else facing
	var speed := maxf(DIVE_SPEED, horizontal_speed() + 1.5)
	velocity = dir * speed
	velocity.y = DIVE_UP if not from_ground else DIVE_UP * 0.8
	facing = dir
	state = State.DIVE
	can_dive = false
	crouching = false
	_play_once("fall")
	jumped.emit("dive")


func _start_pound() -> void:
	state = State.POUND_SPIN
	state_time = POUND_SPIN_TIME
	velocity = Vector3.ZERO
	can_dive = false
	jumped.emit("pound_spin")


func _steer(delta: float, accel: float) -> void:
	var top := maxf(RUN_SPEED if input.run else WALK_SPEED, horizontal_speed())
	if jump_kind == "long":
		top = maxf(top, LONG_JUMP_FORWARD)
	var target := input.move * top
	var flat := Vector3(velocity.x, 0, velocity.z)
	var a := accel * (0.25 if steer_lock > 0.0 else 1.0)
	if input.move.length() < 0.05:
		# Let go of the stick and the hero keeps most of their speed.
		a *= 0.25
		target = flat
	flat = flat.move_toward(target, a * delta)
	velocity.x = flat.x
	velocity.z = flat.z
	if input.move.length() > 0.2 and steer_lock <= 0.0:
		_turn_toward(input.move, 9.0, delta)


func _fall(delta: float) -> void:
	if not input.jump_held:
		_cut = true
	var g := GRAVITY
	if jump_kind == "long" and state == State.AIR:
		g = LONG_JUMP_GRAVITY
	elif velocity.y < 0.0 or (_cut and jump_kind in ["jump", "double", "high", "rollout"]):
		g = FALL_GRAVITY
	velocity.y = maxf(velocity.y - g * delta, -MAX_FALL)


func _turn_toward(dir: Vector3, rate: float, delta: float) -> void:
	var want := Vector3(dir.x, 0, dir.z)
	if want.length() < 0.01:
		return
	want = want.normalized()
	var angle := facing.signed_angle_to(want, Vector3.UP)
	var stepped_angle := clampf(angle, -rate * delta, rate * delta)
	facing = facing.rotated(Vector3.UP, stepped_angle).normalized()


func _after_move(before: Vector3, delta: float) -> void:
	var on_floor := is_on_floor()
	if on_floor and is_on_wall() and state in [State.GROUND, State.SLIDE]:
		_step_up(before, delta)
	if on_floor:
		last_floor_y = global_position.y
		_push_from_floor(delta)
	match state:
		State.AIR, State.HURT:
			if on_floor and velocity.y <= 0.01:
				_land(before.y)
			elif is_on_wall() and state == State.AIR and (before.y < 3.0 or jump_kind == "wall"):
				var n := get_wall_normal()
				n.y = 0.0
				var into := input.move.dot(-n.normalized()) > 0.3 or Vector3(before.x, 0, before.z).dot(-n.normalized()) > 2.0
				if n.length() > 0.5 and into and global_position.y > last_floor_y + 0.6:
					wall_normal = n.normalized()
					state = State.WALL
					# Kicking across a narrow gap keeps the climb going, and
					# the stick can't pull off the new wall straight away.
					if jump_kind == "wall":
						state_time = 0.25
					else:
						state_time = 0.0
						velocity.y = minf(velocity.y, 0.0)
		State.WALL:
			if on_floor:
				_land(before.y)
			elif not test_move(global_transform, -wall_normal * 0.08):
				state = State.AIR
		State.DIVE:
			if on_floor:
				state = State.SLIDE
				state_time = 0.55
				landed.emit(-before.y)
			elif is_on_wall():
				# Bonk.
				var n := get_wall_normal()
				velocity = Vector3(n.x, 0, n.z) * 3.0 + Vector3.UP * 3.0
				state = State.AIR
				steer_lock = 0.4
				jump_kind = "bonk"
		State.POUND_FALL:
			if on_floor:
				state = State.POUND_LAND
				state_time = POUND_LAND_TIME
				_squash = 0.6
				landed.emit(POUND_SPEED)
				pounded.emit(global_position)
		State.GROUND, State.SLIDE, State.POUND_LAND:
			if not on_floor:
				state = State.AIR
				jump_kind = "ledge"
				_cut = true
		State.LOCKED:
			pass
	if state == State.GROUND and on_floor and horizontal_speed() > 0.5:
		_step_dist += horizontal_speed() * delta
		if _step_dist > (1.6 if horizontal_speed() > 5.0 else 1.1):
			_step_dist = 0.0
			stepped.emit()
	_was_on_floor = on_floor


## Walks up a low ledge (the top of a slope, a low block) if there's room.
func _step_up(before: Vector3, delta: float) -> void:
	var flat := Vector3(before.x, 0, before.z)
	if flat.length() < 0.5:
		return
	var ahead := flat.normalized() * maxf(flat.length() * delta, 0.1)
	var up := Vector3.UP * STEP_HEIGHT
	if test_move(global_transform, up):
		return
	var raised := global_transform.translated(up)
	if test_move(raised, ahead):
		return
	global_position += up + ahead
	apply_floor_snap()


func _land(fall_speed: float) -> void:
	state = State.GROUND
	jump_kind = ""
	if fall_speed < -8.0:
		_squash = clampf(1.0 + fall_speed / 60.0, 0.7, 0.95)
	landed.emit(-fall_speed)


## Conveyor belts carry whoever stands on them (they set a "push" meta).
func _push_from_floor(delta: float) -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y > 0.7:
			var obj := c.get_collider()
			if obj and obj.has_meta("push"):
				var push: Vector3 = obj.get_meta("push")
				global_position += push * delta
				return


func _play_once(clip: String) -> void:
	if rig:
		rig.play_once(clip, 0.05)


## Points and poses the body, and picks the clip. Runs on the physics tick so
## physics interpolation smooths it.
func _update_body(delta: float) -> void:
	var want_pitch := 0.0
	match state:
		State.DIVE:
			want_pitch = deg_to_rad(80.0)
		State.SLIDE:
			want_pitch = deg_to_rad(88.0)
		State.AIR:
			if jump_kind == "long":
				want_pitch = deg_to_rad(30.0)
	_pitch = lerpf(_pitch, want_pitch, clampf(18.0 * delta, 0.0, 1.0)) if delta > 0.0 else want_pitch
	_squash = move_toward(_squash, 1.0, 4.0 * delta)
	var yaw := atan2(facing.x, facing.z)
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, _pitch + _spin)
	var s := Vector3(1.0 + (1.0 - _squash) * 0.6, _squash, 1.0 + (1.0 - _squash) * 0.6)
	body.basis = b.scaled_local(s)
	body.visible = safe_time <= 0.0 or int(safe_time * 12.0) % 2 == 0 or state == State.LOCKED
	if rig == null or rig.busy():
		return
	match state:
		State.GROUND:
			var v := horizontal_speed()
			if crouching:
				rig.play("crouch")
			elif v > 5.4:
				rig.play("sprint", 0.12, clampf(v / RUN_SPEED, 0.6, 1.4))
			elif v > 0.3:
				rig.play("walk", 0.12, clampf(v / WALK_SPEED, 0.5, 1.5))
			else:
				rig.play("idle")
		State.AIR, State.HURT:
			rig.play("jump" if velocity.y > 1.0 else "fall")
		State.WALL, State.DIVE, State.SLIDE:
			rig.play("fall")
		State.POUND_SPIN, State.POUND_FALL, State.POUND_LAND:
			rig.play("crouch")
		State.LOCKED:
			if is_on_floor():
				rig.play("idle")
