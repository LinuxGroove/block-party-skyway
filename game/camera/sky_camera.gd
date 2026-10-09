class_name SkyCamera
extends Camera3D
## The camera. It sits behind and above the hero, looking ahead and slightly
## down, at an angle each area of a level sets (see CameraZone), and turns to
## a new angle slowly. It doesn't swing round behind the hero on every turn
## or bob with every jump, so jumps are easy to judge and the view stays calm.
##
## The right stick nudges it, and it eases back to the set angle when let go;
## open areas let it turn all the way round. Settings: turn speed, "follow
## behind me" (a lazy chase camera), field of view and inverted axes. There is
## no camera shake.

const LOOK_HEIGHT := 0.6
## How far a held nudge can turn the camera, and how fast.
const NUDGE_YAW := deg_to_rad(70.0)
const NUDGE_PITCH := deg_to_rad(18.0)
const NUDGE_RATE := 1.8
## Seconds after letting go of the stick before the camera eases back.
const NUDGE_HOLD := 0.6
const FREE_TURN_RATE := 2.4
const BLEND_RATE := 2.2
## How far above its last footing the hero can climb before the camera rises.
const RISE_ALLOWANCE := 2.6

var hero: Hero
## The level's shot when no zone applies.
var base := {"yaw": 0.0, "pitch": 32.0, "distance": 8.5, "free": false}
var zones: Array[CameraZone] = []
## Where the camera is now (radians and metres), easing towards the shot.
var yaw := 0.0
var pitch := deg_to_rad(32.0)
var distance := 8.5
## The heading open areas keep after the stick turns them.
var free_yaw := 0.0
var nudge := Vector2.ZERO
var focus := Vector3.ZERO
var turn_speed := 1.0
var follow := false
var invert_x := false
var invert_y := false
## Set by tests and screenshots to drive the stick without input events.
var stick_override := Vector2.INF

var _focus_y := 0.0
var _nudge_idle := 0.0
var _lead := Vector3.ZERO
var _pull := 0.0
var _free := false
var _shot := {}


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	near = 0.1
	far = 400.0
	_load_settings()
	LGSettings.changed.connect(_on_setting_changed)


func _on_setting_changed(section: String, _key: String, _value: Variant) -> void:
	if section == "camera":
		_load_settings()


func _load_settings() -> void:
	turn_speed = float(LGSettings.get_value("camera", "turn_speed"))
	follow = bool(LGSettings.get_value("camera", "follow"))
	fov = float(LGSettings.get_value("camera", "fov"))
	invert_x = bool(LGSettings.get_value("camera", "invert_x"))
	invert_y = bool(LGSettings.get_value("camera", "invert_y"))


func set_base(p_yaw: float, p_pitch := 32.0, p_distance := 8.5, p_free := false) -> void:
	base = {"yaw": p_yaw, "pitch": p_pitch, "distance": p_distance, "free": p_free}


## Connects a zone so it takes over the camera while the hero is inside.
func watch_zone(zone: CameraZone) -> void:
	zone.body_entered.connect(_on_zone_entered.bind(zone))
	zone.body_exited.connect(_on_zone_exited.bind(zone))


func _on_zone_entered(body: Node3D, zone: CameraZone) -> void:
	if body == hero:
		zones.erase(zone)
		zones.append(zone)


func _on_zone_exited(body: Node3D, zone: CameraZone) -> void:
	if body == hero:
		zones.erase(zone)


## The shot that applies now: the best zone, else the level's base.
func current_shot() -> Dictionary:
	var best: CameraZone = null
	for z in zones:
		if is_instance_valid(z) and (best == null or z.rank >= best.rank):
			best = z
	if best:
		return {"yaw": best.yaw, "pitch": best.pitch, "distance": best.distance, "free": best.free}
	return base


## The heading the stick is read against.
func input_yaw() -> float:
	return yaw + nudge.x


## Jumps straight to the shot, with no easing (on arrival and respawns).
func snap() -> void:
	_shot = current_shot()
	_free = bool(_shot.free) or follow
	free_yaw = deg_to_rad(float(_shot.yaw))
	yaw = free_yaw
	pitch = deg_to_rad(float(_shot.pitch))
	distance = float(_shot.distance)
	nudge = Vector2.ZERO
	_lead = Vector3.ZERO
	_pull = 0.0
	if hero:
		focus = hero.global_position
		_focus_y = hero.global_position.y
	_place()


## Brings a nudge back to the set angle, or in open areas turns the camera
## behind the hero.
func recenter() -> void:
	nudge = Vector2.ZERO
	if _free and hero:
		free_yaw = atan2(-hero.facing.x, -hero.facing.z)


func _process(delta: float) -> void:
	if hero == null or not is_instance_valid(hero):
		return
	update(delta, _read_stick())


func _read_stick() -> Vector2:
	if stick_override != Vector2.INF:
		return stick_override
	var s := Input.get_vector("cam_left", "cam_right", "cam_up", "cam_down")
	if invert_x:
		s.x = -s.x
	if invert_y:
		s.y = -s.y
	if Input.is_action_just_pressed("recenter"):
		recenter()
	return s


## One frame of camera work, with the right stick's position.
func update(delta: float, stick: Vector2) -> void:
	var shot := current_shot()
	# "Follow behind me" keeps whatever heading it swings to, like open areas.
	var is_free := bool(shot.free) or follow
	if shot != _shot or is_free != _free:
		if is_free and not _free:
			free_yaw = yaw + nudge.x
			nudge.x = 0.0
		_shot = shot
		_free = is_free
	var rate := turn_speed
	# The stick: open areas turn for good; elsewhere it's a nudge that eases
	# back when let go.
	if _free:
		free_yaw -= stick.x * FREE_TURN_RATE * rate * delta
	if stick.length() > 0.15:
		_nudge_idle = 0.0
		if not _free:
			nudge.x = clampf(nudge.x - stick.x * NUDGE_RATE * rate * delta, -NUDGE_YAW, NUDGE_YAW)
		nudge.y = clampf(nudge.y + stick.y * NUDGE_RATE * 0.6 * rate * delta, -NUDGE_PITCH, NUDGE_PITCH)
	else:
		_nudge_idle += delta
		if _nudge_idle > NUDGE_HOLD:
			nudge = nudge.lerp(Vector2.ZERO, 1.0 - exp(-2.5 * rate * delta))
	var flat_v := Vector3(hero.velocity.x, 0, hero.velocity.z)
	if follow and flat_v.length() > 2.0 and not hero.is_locked():
		# A lazy chase camera: it swings round as you run sideways, never
		# when you run straight at it.
		var behind := atan2(-flat_v.x, -flat_v.z)
		var diff := wrapf(behind - free_yaw, -PI, PI)
		if absf(diff) < PI * 0.8:
			free_yaw += sin(diff) * clampf(flat_v.length() / Hero.RUN_SPEED, 0.0, 1.0) * 1.4 * rate * delta
	var k := 1.0 - exp(-BLEND_RATE * rate * delta)
	if _free:
		yaw = free_yaw
	else:
		yaw = lerp_angle(yaw, deg_to_rad(float(shot.yaw)), k)
	pitch = lerpf(pitch, deg_to_rad(float(shot.pitch)) + nudge.y, k)
	distance = lerpf(distance, float(shot.distance), k)
	# Follow the hero across quickly, but up and down only when they land
	# somewhere new or leave the frame.
	var at := hero.get_global_transform_interpolated().origin
	var target_y := clampf(hero.last_floor_y, at.y - RISE_ALLOWANCE, at.y + 0.2)
	var ky := 1.0 - exp(-(8.0 if target_y < _focus_y else 3.5) * delta)
	_focus_y = lerpf(_focus_y, target_y, ky)
	var lead_target := flat_v * 0.1
	if lead_target.length() > 0.9:
		lead_target = lead_target.normalized() * 0.9
	_lead = _lead.lerp(lead_target, 1.0 - exp(-1.5 * delta))
	var kx := 1.0 - exp(-12.0 * delta)
	focus.x = lerpf(focus.x, at.x + _lead.x, kx)
	focus.z = lerpf(focus.z, at.z + _lead.z, kx)
	focus.y = _focus_y
	_place(delta)


func _place(delta := 0.0) -> void:
	var heading := yaw + (0.0 if _free else nudge.x)
	var look := focus + Vector3.UP * LOOK_HEIGHT
	var dir := Vector3(sin(heading) * cos(pitch), sin(pitch), cos(heading) * cos(pitch))
	var want := distance
	var blocked := _blocked_distance(look, dir, distance)
	# Move in quickly when something is in the way, and back out gently.
	if blocked < distance - _pull:
		_pull = distance - blocked
	elif delta > 0.0:
		_pull = lerpf(_pull, distance - blocked, 1.0 - exp(-2.0 * delta))
	else:
		_pull = distance - blocked
	want = maxf(distance - _pull, 1.5)
	global_position = look + dir * want
	if not global_position.is_equal_approx(look):
		look_at(look, Vector3.UP)


func _blocked_distance(from: Vector3, dir: Vector3, dist: float) -> float:
	if not is_inside_tree():
		return dist
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.3
	q.shape = sphere
	q.transform = Transform3D(Basis.IDENTITY, from)
	q.motion = dir * dist
	q.collision_mask = 1
	var r := space.cast_motion(q)
	if r.is_empty() or r[0] >= 1.0:
		return dist
	return maxf(dist * r[0], 1.5)
