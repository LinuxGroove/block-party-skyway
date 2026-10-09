class_name SnackSkewer
extends Node3D
## A giant cooking fork (or a skewer) that sweeps round a pepper mill, like a
## spinner: jump it as it comes. Touching the arm hurts.
##
##   add(SnackSkewer.make(4.0, 60.0), at)                        # one fork
##   add(SnackSkewer.make(3.0, -45.0, "food:skewer", 2), at)     # two skewers

var level: Level
## Arm length in metres, from the post.
var length := 4.0
var speed := 60.0
var arms := 1
var model_name := "food:cooking-fork"
## Height of the arm above the post's foot.
var height := 0.45
var phase := 0.0

var _arm: Node3D
var _hit: Area3D


static func make(p_length := 4.0, p_speed := 60.0, p_model := "food:cooking-fork", p_arms := 1) -> SnackSkewer:
	var s := SnackSkewer.new()
	s.length = p_length
	s.speed = p_speed
	s.model_name = p_model
	s.arms = p_arms
	return s


func _ready() -> void:
	var mill := Kit.model("food:pepper-mill", 2.6)
	add_child(mill)
	if level:
		level.solid(global_position + Vector3(-0.22, 0, -0.22), global_position + Vector3(0.22, 1.4, 0.22))
	_arm = Node3D.new()
	_arm.position.y = height
	_arm.rotation_degrees.y = phase
	add_child(_arm)
	_hit = Area3D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = Kit.LAYER_HERO
	_hit.monitorable = false
	_arm.add_child(_hit)
	var b := SnackFood.bounds(model_name)
	# The models lie along x; stretch one across the arm.
	var s := length / b.size.x
	for a in arms:
		var turn := TAU * a / arms
		var dir := Vector3(sin(turn), 0, cos(turn))
		var holder := Node3D.new()
		holder.rotation.y = turn - PI / 2.0
		_arm.add_child(holder)
		var m := Kit.model(model_name)
		m.scale = Vector3(s, s * 0.8, s * 0.8)
		# Handle at the post, prongs out at the end.
		m.position = Vector3(length / 2.0 - b.get_center().x * s, -b.size.y * s * 0.4, -b.get_center().z * s * 0.8)
		m.rotation.y = PI if model_name == "food:cooking-fork" else 0.0
		if model_name == "food:cooking-fork":
			m.position.x = length / 2.0 + b.get_center().x * s
		holder.add_child(m)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5, 0.5, length - 0.3)
		shape.shape = box
		shape.position = dir * (length / 2.0 + 0.3)
		shape.rotation.y = turn
		_hit.add_child(shape)
	_hit.body_entered.connect(_on_body)


## The arm's heading now, in degrees (0 points south, +z).
func angle() -> float:
	return fposmod(_arm.rotation_degrees.y, 360.0)


func _physics_process(delta: float) -> void:
	_arm.rotation_degrees.y += speed * delta
	if level and level.hero and _hit.overlaps_body(level.hero):
		level.hurt_hero(global_position + Vector3.UP * height)


func _on_body(body: Node3D) -> void:
	if level and body == level.hero:
		level.hurt_hero(global_position + Vector3.UP * height)
