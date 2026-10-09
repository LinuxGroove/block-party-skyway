class_name Spinner
extends Node3D
## A bar that sweeps round a post: jump it as it comes. Built from a model
## repeated along the arm (spike blocks, logs, flames, gears); touching any
## of it hurts.
##
##   add(Spinner.make(4, 60.0), at)            # four spike blocks, 60°/s
##   add(Spinner.make(3, -45.0, "factory:cog-a", 2), at)   # two arms

var level: Level
var length := 4
var speed := 60.0
var arms := 1
var model_name := "spike-block"
var model_scale := 0.6
## Height of the arm above the post's foot.
var height := 0.4
var phase := 0.0

var _arm: Node3D
var _hit: Area3D


static func make(p_length := 4, p_speed := 60.0, p_model := "spike-block", p_arms := 1) -> Spinner:
	var s := Spinner.new()
	s.length = p_length
	s.speed = p_speed
	s.model_name = p_model
	s.arms = p_arms
	return s


func _ready() -> void:
	var post := Kit.model("block-snow-narrow", 1.0)
	post.scale = Vector3(0.5, height + 0.3, 0.5)
	add_child(post)
	_arm = Node3D.new()
	_arm.position.y = height
	_arm.rotation_degrees.y = phase
	add_child(_arm)
	_hit = Area3D.new()
	_hit.collision_layer = 0
	_hit.collision_mask = Kit.LAYER_HERO
	_hit.monitorable = false
	_arm.add_child(_hit)
	for a in arms:
		var turn := TAU * a / arms
		var dir := Vector3(sin(turn), 0, cos(turn))
		for i in length:
			var m := Kit.model(model_name, model_scale)
			m.position = dir * (i + 1.0) + Vector3.DOWN * 0.25
			_arm.add_child(m)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.55, 0.55, float(length))
		shape.shape = box
		shape.position = dir * (length / 2.0 + 0.5)
		shape.rotation.y = turn
		_hit.add_child(shape)
	_hit.body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	_arm.rotation_degrees.y += speed * delta
	if level and level.hero and _hit.overlaps_body(level.hero):
		level.hurt_hero(global_position + Vector3.UP * height)


func _on_body(body: Node3D) -> void:
	if level and body == level.hero:
		level.hurt_hero(global_position + Vector3.UP * height)
