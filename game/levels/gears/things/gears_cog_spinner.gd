class_name GearsCogSpinner
extends Spinner
## A Spinner whose arms are rows of cogs stood on edge, each turning as
## the arm sweeps round a piston post. Touching any of it hurts: jump the
## arms as they come, or slip through just after one goes by.
##
##   add(GearsCogSpinner.cogs(3, 80.0, 2), at)

var _cogs: Array[Node3D] = []


static func cogs(p_length := 3, p_speed := 80.0, p_arms := 2) -> GearsCogSpinner:
	var s := GearsCogSpinner.new()
	s.length = p_length
	s.speed = p_speed
	s.arms = p_arms
	s.model_name = "factory:cog-b"
	s.model_scale = 0.62
	return s


func _ready() -> void:
	super()
	# Swap the post for a piston housing.
	var post := get_child(0) as Node3D
	post.visible = false
	var housing := Kit.model("factory:piston-round")
	housing.scale = Vector3(0.7, height + 0.3, 0.7)
	add_child(housing)
	for c in _arm.get_children():
		if c is Area3D:
			continue
		var m := c as Node3D
		# Stand each cog up on edge in line with its arm, a little higher, so
		# the arm reads as a row of turning cogs.
		var along := Vector3(m.position.x, 0, m.position.z).normalized()
		m.basis = Basis(along, PI / 2.0).scaled(Vector3.ONE * model_scale)
		m.position.y = 0.0
		_cogs.append(m)


func _physics_process(delta: float) -> void:
	super(delta)
	for m in _cogs:
		var along := Vector3(m.position.x, 0, m.position.z).normalized()
		m.rotate(along.cross(Vector3.UP).normalized(), delta * 5.0)
