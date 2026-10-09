class_name CastleSiegeTower
extends Boss
## King Thud's Siege Tower: a tall wooden tower on wheels with a catapult on
## its top deck. It rolls along the road under the castle wall lobbing
## stones at the hero (each lands in a red ring that shows first), then
## stops at a gap in the battlements to reload: it rocks to a halt and drops
## its gangway onto the wall. That's the moment to run across and ground
## pound its deck (a stomp or a dive counts too). It throws the hero back
## over the gangway, pulls it up and rolls on, faster and throwing more.
## Three hits and it topples over backwards.
##
## The arena adds it with its feet on the road below the wall and tells it
## where the wall's edge is and where it stops:
##
##   var t := CastleSiegeTower.new(); t.stops = [-6.0, 0.0, 6.0]
##   add_boss(t, Vector3(-8.5, CastleSiegeTower.DECK_Y - CastleSiegeTower.LIFT, -7.9))

enum Act { WAIT, ROLL, BRAKE, LOWER, OPEN, RAISE, RECOIL }

const MODEL := "castle:siege-tower"
const CATAPULT := "castle:siege-catapult"
const PLANK := "castle:bridge-draw"
const SCALE := 3.4
## Where the kit's tower is cut off (its roof and the plank on its side go),
## at scale 1, and how far above its wheels that puts the deck.
const CUT := 1.83
const LIFT := 6.25
## From its middle to its back edge, which it topples over.
const BACK := 1.6
## The deck's top, in level space (the wall's top is 0).
const DECK_Y := 2.0
const DECK := Vector3(3.0, 0.3, 3.4)
const GANGWAY := 3.6
const GANGWAY_WIDTH := 2.4
## The gangway's angle up from flat: raised against the posts, and lowered
## to rest on the wall.
const RAISED := 86.0
const LOWERED := -33.7
const CATAPULT_SCALE := 1.15
## Seconds for each part of the pattern.
const WAIT_TIME := 2.8
const BRAKE_TIME := 0.8
const LOWER_TIME := 0.55
const RAISE_TIME := 0.7
const RECOIL_TIME := 1.0
## Per hit taken: rolling speed, seconds between volleys, stones per volley
## and seconds the gangway stays down.
const SPEED := [2.6, 3.2, 3.8]
const FIRE_GAP := [1.4, 1.15, 1.0]
const VOLLEY := [1, 2, 2]
const OPEN_TIME := [5.0, 4.2, 3.6]
const FLIGHT := 1.25
const WOOD := Color("b86a3e")
const IRON := Color("4a4c58")

## Where it stops along the road (x), in the order it visits them.
var stops: Array = [-6.0, 0.0, 6.0]
var order: Array = [1, 2, 0]
## The wall's top: where the hero stands, and the edge the gangway lands on.
var wall_z := -4.0
## Where on the wall its stones may land, as x and z.
var field := Rect2(-9.5, -2.5, 19.0, 11.0)
var act := Act.WAIT
var act_time := 0.0
var target_x := 0.0
## How many times the gangway has come down (for tests).
var open_count := 0
var said := false

var _visit := 0
var _fire_t := 0.0
var _rock := 0.0
var _topple := 0.0
var _angle := RAISED
var _last_x := 0.0
var _model: Node3D
var _wheels: Array[Node3D] = []
var _deck: AnimatableBody3D
var _deck_shapes: Array[CollisionShape3D] = []
var _gangway: AnimatableBody3D
var _gangway_shape: CollisionShape3D
var _chains: Array[MeshInstance3D] = []
var _catapult: Node3D
var _arm: Node3D

static var _cut_shader: Shader


func _ready() -> void:
	super()
	_last_x = position.x
	target_x = position.x
	_model = Kit.model(MODEL, SCALE)
	_model.position.x = -0.035 * SCALE
	add_child(_model)
	_cut_roof(_model)
	for n in _model.find_children("wheel*", "Node3D", true, false):
		_wheels.append(n as Node3D)
	_build_deck()
	_build_gangway()
	make_body(Vector3(DECK.x, 2.4, DECK.z), LIFT)
	_place()


## Hides the kit tower's roof and the plank on its side with a shader that
## drops everything above the cut, so the deck sits on top instead.
func _cut_roof(model: Node3D) -> void:
	if _cut_shader == null:
		_cut_shader = Shader.new()
		_cut_shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D colormap : source_color, filter_nearest_mipmap;
uniform float cut = 1.83;
varying vec3 local_pos;
void vertex() {
	local_pos = VERTEX;
}
void fragment() {
	if (local_pos.y > cut || (local_pos.x > 0.37 && local_pos.y > 1.6)) {
		discard;
	}
	ALBEDO = texture(colormap, UV).rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
}
"""
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var std := mesh.surface_get_material(0) as StandardMaterial3D
		var mat := ShaderMaterial.new()
		mat.shader = _cut_shader
		mat.set_shader_parameter("colormap", std.albedo_texture if std else null)
		mat.set_shader_parameter("cut", CUT)
		(mi as MeshInstance3D).material_override = mat


## The deck on top: planks, low wooden boards round three sides, posts for
## the gangway's chains and the catapult, all on one body that moves with
## the tower.
func _build_deck() -> void:
	_deck = AnimatableBody3D.new()
	_deck.top_level = true
	_deck.sync_to_physics = true
	_deck.collision_layer = Kit.LAYER_WORLD
	_deck.collision_mask = 0
	add_child(_deck)
	var wood := StandardMaterial3D.new()
	wood.albedo_color = WOOD
	wood.roughness = 1.0
	_deck_box(Vector3(DECK.x, DECK.y, DECK.z), Vector3(0, -DECK.y / 2.0, 0))
	var floor_plank := Kit.model(PLANK)
	floor_plank.scale = Vector3(DECK.z, DECK.y / 0.1, DECK.x / 0.83)
	floor_plank.rotation.y = PI / 2.0
	floor_plank.position = Vector3(0, -DECK.y, -DECK.z / 2.0)
	_deck.add_child(floor_plank)
	var hx := DECK.x / 2.0
	var hz := DECK.z / 2.0
	for b in [[Vector3(DECK.x, 0.8, 0.16), Vector3(0, 0.4, -hz + 0.08)],
			[Vector3(0.16, 0.8, DECK.z), Vector3(-hx + 0.08, 0.4, 0)],
			[Vector3(0.16, 0.8, DECK.z), Vector3(hx - 0.08, 0.4, 0)]]:
		_deck_box(b[0], b[1])
		_mesh_box(_deck, b[0], b[1], wood)
	# Posts at the front corners that the raised gangway rests against.
	for s in [-1.0, 1.0]:
		_mesh_box(_deck, Vector3(0.22, 2.9, 0.22), Vector3(s * (GANGWAY_WIDTH / 2.0 + 0.2), 1.45, hz - 0.12), wood)
	_catapult = Kit.model(CATAPULT, CATAPULT_SCALE)
	_catapult.rotation.y = -PI / 2.0
	_catapult.position = Vector3(0, 0, -hz + 0.95)
	_deck.add_child(_catapult)
	_arm = _catapult.find_child("catapult", true, false) as Node3D
	_deck_box(Vector3(1.1, 1.0, 1.6), Vector3(0, 0.5, -hz + 0.95))


func _deck_box(size: Vector3, at: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	_deck.add_child(shape)
	_deck_shapes.append(shape)


static func _mesh_box(parent: Node3D, size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.material_override = mat
	m.position = at
	parent.add_child(m)
	return m


## The gangway, hinged at the deck's front edge, with chains up to the posts.
func _build_gangway() -> void:
	_gangway = AnimatableBody3D.new()
	_gangway.top_level = true
	_gangway.sync_to_physics = true
	_gangway.collision_layer = Kit.LAYER_WORLD
	_gangway.collision_mask = 0
	add_child(_gangway)
	_gangway_shape = CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(GANGWAY_WIDTH, 0.25, GANGWAY)
	_gangway_shape.shape = box
	_gangway_shape.position = Vector3(0, -0.125, GANGWAY / 2.0)
	_gangway.add_child(_gangway_shape)
	var plank := Kit.model(PLANK)
	plank.scale = Vector3(GANGWAY, 2.5, GANGWAY_WIDTH / 0.83)
	plank.rotation.y = PI / 2.0
	plank.position = Vector3.DOWN * 0.25
	_gangway.add_child(plank)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = IRON
	# Iron bands across its underside, which faces the wall when it's up.
	for k in [0.2, 0.5, 0.8]:
		_mesh_box(_gangway, Vector3(GANGWAY_WIDTH + 0.06, 0.06, 0.22), Vector3(0, -0.27, GANGWAY * k), mat)
	for i in 2:
		var chain := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.06
		cyl.bottom_radius = 0.06
		cyl.height = 1.0
		cyl.radial_segments = 6
		chain.mesh = cyl
		chain.material_override = mat
		chain.top_level = true
		add_child(chain)
		_chains.append(chain)


## How many hits it has taken: 0, 1 or 2.
func stage() -> int:
	return clampi(max_health - health, 0, 2)


## The stop it's rolling to (or stopped at), as x along the road.
func next_stop() -> float:
	return target_x


func think(delta: float) -> void:
	act_time += delta
	match act:
		Act.WAIT:
			if act_time > 0.6 and not said:
				said = true
				level.say("When the Siege Tower stops to reload, run across and ground pound it!")
			if act_time >= WAIT_TIME:
				_roll_on()
		Act.ROLL:
			var speed: float = SPEED[stage()]
			position.x = move_toward(position.x, target_x, speed * delta)
			_fire_t -= delta
			if _fire_t <= 0.0:
				_fire_t = FIRE_GAP[stage()]
				_volley()
			if is_equal_approx(position.x, target_x):
				_set_act(Act.BRAKE)
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/open_001.ogg", -4.0, 0.05)
		Act.BRAKE:
			# Rocks to a halt on its wheels.
			var u := act_time / BRAKE_TIME
			_rock = sin(act_time * 22.0) * 2.0 * (1.0 - u)
			if u >= 1.0:
				_rock = 0.0
				_set_act(Act.LOWER)
		Act.LOWER:
			var u := minf(act_time / LOWER_TIME, 1.0)
			_angle = lerpf(RAISED, LOWERED, u * u)
			if u >= 1.0:
				open = true
				open_count += 1
				LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", -2.0, 0.05)
				_set_act(Act.OPEN)
		Act.OPEN:
			if act_time >= OPEN_TIME[stage()]:
				open = false
				_throw_off(11.5)
				_set_act(Act.RAISE)
		Act.RAISE:
			var u := minf(act_time / RAISE_TIME, 1.0)
			_angle = lerpf(LOWERED, RAISED, smoothstep(0.0, 1.0, u))
			if u >= 1.0:
				_roll_on()
		Act.RECOIL:
			var u := act_time / RECOIL_TIME
			_rock = sin(act_time * 18.0) * 3.0 * (1.0 - u)
			if u >= 1.0:
				_rock = 0.0
				_set_act(Act.RAISE)
	# The gangway is only solid when it's still: up, or down on the wall.
	_gangway_shape.disabled = act == Act.LOWER or act == Act.RAISE
	_place()


func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0


## Off to the next stop.
func _roll_on() -> void:
	target_x = float(stops[int(order[_visit % order.size()])])
	_visit += 1
	_fire_t = 0.5
	_set_act(Act.ROLL)


## Throws stones at the hero: one where they are, and later one where
## they're heading too.
func _volley() -> void:
	var h := hero()
	if h == null or h.is_locked():
		return
	var at := h.global_position - level.global_position
	if at.z < wall_z or at.y < -1.0:
		return
	var spot := Vector3(at.x, h.last_floor_y - level.global_position.y, at.z)
	var targets: Array[Vector3] = [spot]
	if VOLLEY[stage()] > 1:
		var ahead := spot + Vector3(h.velocity.x, 0, h.velocity.z) * FLIGHT
		if ahead.distance_to(spot) < 2.0:
			ahead = spot + Vector3(2.2 * signf(target_x - spot.x + 0.01), 0, 0)
		targets.append(ahead)
	for t in targets:
		t.x = clampf(t.x, field.position.x, field.end.x)
		t.z = clampf(t.z, field.position.y, field.end.y)
		_fire(t)


func _fire(at: Vector3) -> void:
	var from := _deck.global_position - level.global_position + Vector3(0, CATAPULT_SCALE * 1.6, -DECK.z / 2.0 + 0.95 + 0.9 * CATAPULT_SCALE)
	var shot := CastleShot.lob(from, at, FLIGHT)
	shot.ignore = [_deck, _gangway]
	level.add(shot, from)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -6.0, 0.1)
	if _arm:
		var tw := create_tween()
		tw.tween_property(_arm, "rotation:z", deg_to_rad(-95.0), 0.12)
		tw.tween_property(_arm, "rotation:z", 0.0, 0.7).set_trans(Tween.TRANS_SINE)


## True while the hero is on the deck or the gangway (not on the wall).
func hero_on_board() -> bool:
	var h := hero()
	if h == null:
		return false
	var p := h.global_position - level.global_position
	return absf(p.x - position.x) < DECK.x / 2.0 + 0.4 and p.z < wall_z - 0.1 \
			and p.z > position.z - DECK.z / 2.0 - 0.4 and p.y > DECK_Y - 1.0


## Sends anyone on board flying back over the gangway onto the wall.
func _throw_off(up: float) -> void:
	if not hero_on_board():
		return
	var h := hero()
	h.bounce(up)
	h.velocity.x = 0.0
	h.velocity.z = 8.0
	h.steer_lock = 0.6


## While open, a pound, a dive or a stomp on the deck is a hit (and throws
## the hero back to the wall); walking about on it does nothing. Shut, the
## tower hurts to touch.
func _on_touched(body: Node3D) -> void:
	if beaten or level == null or body != level.hero:
		return
	var h := level.hero
	if open:
		var stomp := _above <= 3 and h.velocity.y < -1.0
		if invulnerable <= 0.0 and (h.is_pounding() or h.is_diving() or stomp):
			if hit():
				_throw_off(13.0)
	elif invulnerable <= 0.0:
		level.hurt_hero(global_position)


func _on_hit() -> void:
	_set_act(Act.RECOIL)


func _on_beaten() -> void:
	open = false
	_touch.set_deferred("monitoring", false)
	for sh in _deck_shapes:
		sh.set_deferred("disabled", true)
	_gangway_shape.set_deferred("disabled", true)
	_throw_off(13.0)
	# It topples over backwards, away from the wall, and lands with a bump.
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_method(_set_topple, 0.0, 88.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_crash)
	tw.tween_method(_set_topple, 88.0, 82.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_method(_set_topple, 82.0, 88.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _set_topple(degrees: float) -> void:
	_topple = degrees
	_place()


func _crash() -> void:
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactSoft_heavy_000.ogg", 0.0, 0.05)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", -2.0, 0.1)


## Moves the deck, gangway and chains along with the tower, and turns its
## wheels as it rolls.
func _place() -> void:
	if not is_inside_tree():
		return
	var roll := (position.x - _last_x) / (0.2 * SCALE)
	_last_x = position.x
	for w in _wheels:
		w.rotation.z -= roll
	# Rocking turns it about its feet; toppling over about its back edge.
	var back := Vector3(0, 0, -BACK)
	var tilt := Transform3D(Basis(Vector3.BACK, deg_to_rad(_rock)), Vector3.ZERO) \
			* Transform3D(Basis.IDENTITY, back) * Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-_topple)), Vector3.ZERO) \
			* Transform3D(Basis.IDENTITY, -back)
	_model.transform = tilt * Transform3D(Basis.from_scale(Vector3.ONE * SCALE), Vector3(-0.035 * SCALE, 0, 0))
	var deck_xf := global_transform * tilt * Transform3D(Basis.IDENTITY, Vector3(0, LIFT, 0))
	if is_instance_valid(_deck):
		_deck.global_transform = deck_xf
	if not is_instance_valid(_gangway):
		return
	var hinge := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-_angle)), Vector3(0, 0, DECK.z / 2.0))
	_gangway.global_transform = deck_xf * hinge
	for i in _chains.size():
		var s := -1.0 if i == 0 else 1.0
		var foot := _gangway.global_transform * Vector3(s * (GANGWAY_WIDTH / 2.0 - 0.1), 0.05, GANGWAY * 0.9)
		var top := deck_xf * Vector3(s * (GANGWAY_WIDTH / 2.0 + 0.2), 2.8, DECK.z / 2.0 - 0.12)
		var along := top - foot
		var chain := _chains[i]
		chain.global_position = (foot + top) / 2.0
		if along.length() > 0.05:
			chain.global_basis = Basis(Quaternion(Vector3.UP, along.normalized())).scaled_local(Vector3(1.0, along.length(), 1.0))
