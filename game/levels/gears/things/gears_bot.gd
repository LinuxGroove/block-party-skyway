class_name GearsBot
extends Critter
## Gear Works' little robots, built from Factory Kit parts. A box bot is an
## orange crate on the move with a screen for a face and a warning light on
## top: jump on it, ground pound it or dive into it. A cog bot is a toothy
## cog rolling along on its edge: only a ground pound stops it.
##
##   add(GearsBot.box_bot(Vector3(4, 0, 0)), at)       # patrols
##   add(GearsBot.box_bot(Vector3.ZERO, 5.0), at)      # chases within 5 m
##   add(GearsBot.cog_bot(Vector3(0, 0, 3)), at)       # rolls back and forth

var kind := "box"

var _roll: Node3D


static func box_bot(p_travel: Vector3, p_chase := 0.0, p_period := 4.0, p_phase := 0.0) -> GearsBot:
	var b := GearsBot.new()
	b.kind = "box"
	b.model_name = "factory:box-small"
	b.model_scale = 1.0
	b.travel = p_travel
	b.period = p_period
	b.phase = p_phase
	b.chase_range = p_chase
	b.speed = 2.6
	b.size = Vector3(0.7, 0.8, 0.6)
	return b


static func cog_bot(p_travel: Vector3, p_period := 3.0, p_phase := 0.0) -> GearsBot:
	var b := GearsBot.new()
	b.kind = "cog"
	b.model_name = "factory:cog-b"
	b.model_scale = 0.95
	b.travel = p_travel
	b.period = p_period
	b.phase = p_phase
	b.spiky = true
	b.coins = 3
	b.size = Vector3(0.8, 0.95, 0.8)
	return b


func _ready() -> void:
	super()
	if kind == "cog":
		# Yaw (the critter turns it to face its way), then roll, then the cog
		# stood on its edge with its axle across.
		var cog := _model
		remove_child(cog)
		var holder := Node3D.new()
		add_child(holder)
		_roll = Node3D.new()
		_roll.position.y = 0.48
		holder.add_child(_roll)
		cog.position = Vector3.ZERO
		cog.rotation.z = PI / 2.0
		_roll.add_child(cog)
		_model = holder
	else:
		var face := Kit.model("factory:screen-hanging-small", 0.75)
		face.position = Vector3(0, 0.55, 0.0)
		face.rotation.y = PI
		_model.add_child(face)
		var light := Kit.model("factory:warning-traffic", 0.3)
		light.position = Vector3(0.18, 0.55, -0.12)
		_model.add_child(light)


func _physics_process(delta: float) -> void:
	var before := position
	super(delta)
	if _roll and not defeated:
		var moved := Vector3(position.x - before.x, 0, position.z - before.z).length()
		_roll.rotation.x += moved / 0.45
