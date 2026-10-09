class_name CastleShot
extends Projectile
## A catapult stone: it flies in a high arc to a spot marked by a red ring on
## the ground, filling in as the stone comes down, and lands with a thump
## that hurts anyone inside the ring. Catapults and the Siege Tower throw
## these.

const RING_RADIUS := 0.95
const STONE_RADIUS := 0.38

## Where it lands (the ground under the ring).
var target := Vector3.ZERO
## Seconds from the throw to landing.
var flight := 1.3
## Bodies it flies through (the thrower's own deck and gangway).
var ignore: Array[Node] = []

var _ring: Node3D
var _fill: MeshInstance3D
var _age := 0.0
var _landed := false


## A stone thrown from `from` to land on `p_target` after `seconds`, pulled
## down by `gravity`. Add it to the level at `from`.
static func lob(from: Vector3, p_target: Vector3, seconds := 1.3, gravity := 20.0) -> CastleShot:
	var s := CastleShot.new()
	s.target = p_target
	s.flight = seconds
	s.fall = gravity
	s.life = seconds + 0.6
	s.radius = STONE_RADIUS
	s.model_name = ""
	# The stone's centre comes down a radius above the ground. Projectile
	# moves in steps, so take those steps into account for the height.
	var aim := p_target + Vector3.UP * STONE_RADIUS
	var d := aim - from
	var dt := 1.0 / 60.0
	var n := seconds / dt
	var v := Vector3(d.x, 0.0, d.z) / seconds
	v.y = (d.y + gravity * dt * dt * n * (n + 1.0) / 2.0) / seconds
	s.velocity = v
	return s


func _ready() -> void:
	super()
	var stone := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = STONE_RADIUS
	sphere.height = STONE_RADIUS * 2.0
	sphere.radial_segments = 7
	sphere.rings = 4
	stone.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("9c9282")
	mat.roughness = 0.9
	stone.material_override = mat
	add_child(stone)
	_model = stone
	_ring = Node3D.new()
	_ring.top_level = true
	add_child(_ring)
	_ring.global_position = target + Vector3.UP * 0.04
	var torus := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = RING_RADIUS - 0.14
	tm.outer_radius = RING_RADIUS
	tm.rings = 24
	tm.ring_segments = 6
	torus.mesh = tm
	torus.scale = Vector3(1.0, 0.25, 1.0)
	torus.material_override = _flat(Color(1.0, 0.3, 0.22, 0.9))
	_ring.add_child(torus)
	_fill = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RING_RADIUS - 0.1
	disc.bottom_radius = RING_RADIUS - 0.1
	disc.height = 0.02
	disc.radial_segments = 24
	_fill.mesh = disc
	_fill.material_override = _flat(Color(1.0, 0.35, 0.25, 0.35))
	_fill.scale = Vector3(0.05, 1.0, 0.05)
	_ring.add_child(_fill)


func _physics_process(delta: float) -> void:
	_age += delta
	var u := clampf(_age / flight, 0.05, 1.0)
	if _fill:
		_fill.scale = Vector3(u, 1.0, u)
	super(delta)


func _on_body(body: Node3D) -> void:
	if _landed or body in ignore:
		return
	_landed = true
	if level and body != level.hero and level.hero:
		# A thump on the ground: anyone in the ring is hit.
		var h := level.hero.global_position
		var flat := Vector2(h.x - target.x, h.z - target.z).length()
		if flat < RING_RADIUS + 0.2 and h.y > target.y - 0.6 and h.y < target.y + 1.4:
			level.hurt_hero(target)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", -10.0, 0.1)
	if _ring:
		_ring.queue_free()
		_ring = null
	super(body)


static func _flat(c: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = false
	return mat
