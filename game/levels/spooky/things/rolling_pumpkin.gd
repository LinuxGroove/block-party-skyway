class_name SpookyRollingPumpkin
extends Projectile
## A big lit jack-o'-lantern rolling along the ground, fired by a
## SpookyPumpkinRoller. It hurts on touch and squashes against whatever it
## rolls into.

const SCALE := 3.0

var _pivot: Node3D


func _init() -> void:
	super()
	model_name = ""
	radius = 0.45


func _ready() -> void:
	super()
	# Turn about the pumpkin's middle, so it rolls rather than wobbles.
	_pivot = Node3D.new()
	add_child(_pivot)
	var m := Kit.model("grave:pumpkin-carved", SCALE)
	m.position.y = -0.48
	_pivot.add_child(m)
	var glow := OmniLight3D.new()
	glow.light_color = Color("ffa040")
	glow.light_energy = 1.6
	glow.omni_range = 2.8
	add_child(glow)


func _physics_process(delta: float) -> void:
	super(delta)
	var flat := Vector3(velocity.x, 0, velocity.z)
	if flat.length() > 0.01:
		_pivot.rotate(Vector3.UP.cross(flat.normalized()), flat.length() / 0.48 * delta)
