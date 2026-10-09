class_name GhostRunner
extends Node3D
## Plays a ghost back as a see-through astronaut.

var ghost: Ghost
var time := 0.0
var running := false

var _rig: RigCharacter
var _body: Node3D


func _ready() -> void:
	# Placed from the recording every frame.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_body = Node3D.new()
	_body.position.y = 0.42
	add_child(_body)
	_rig = RigCharacter.create(GameConfig.hero_scene(ghost.hero if ghost else 0))
	_rig.position.y = -0.42
	_body.add_child(_rig)
	_see_through(_rig)
	visible = false


func start() -> void:
	time = 0.0
	running = ghost != null and ghost.sample_count() > 0
	visible = running
	_apply()


func stop() -> void:
	running = false
	visible = false


func _process(delta: float) -> void:
	if not running:
		return
	time += delta
	_apply()
	if time > ghost.duration() + 1.0:
		visible = false


## Keeps in step with the run's own clock (the play scene calls this).
func sync(t: float) -> void:
	time = t
	_apply()


func _apply() -> void:
	if ghost == null:
		return
	var s := ghost.sample(time)
	if s.is_empty():
		return
	position = s.position
	_body.basis = Basis(Vector3.UP, s.yaw) * Basis(Vector3.RIGHT, s.pitch)
	_rig.play(s.clip)


static func _see_through(n: Node) -> void:
	if n is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.7, 0.9, 1.0, 0.38)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		(n as MeshInstance3D).material_override = mat
		(n as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_see_through(c)
