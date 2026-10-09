class_name Spring
extends StaticBody3D
## A spring: land on it, or walk onto it, and it throws the hero high.

var level: Level
var power := Hero.SPRING_SPEED

var _model: Node3D
var _cool := 0.0


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 0.3, 0.7)
	shape.shape = box
	shape.position.y = 0.15
	add_child(shape)
	_model = Kit.model("spring", 1.2)
	add_child(_model)
	var top := Area3D.new()
	top.collision_layer = 0
	top.collision_mask = Kit.LAYER_HERO
	top.monitorable = false
	var ts := CollisionShape3D.new()
	var tb := BoxShape3D.new()
	tb.size = Vector3(0.8, 0.3, 0.8)
	ts.shape = tb
	ts.position.y = 0.45
	top.add_child(ts)
	add_child(top)
	top.body_entered.connect(_on_top)


func _physics_process(delta: float) -> void:
	_cool = maxf(_cool - delta, 0.0)


func _on_top(body: Node3D) -> void:
	if body != level.hero or _cool > 0.0 or level.hero.velocity.y > 1.0:
		return
	_cool = 0.3
	level.hero.bounce(power)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_jump-high.ogg", -4.0, 0.05)
	var tw := create_tween()
	tw.tween_property(_model, "scale", Vector3(1.4, 0.7, 1.4), 0.06)
	tw.tween_property(_model, "scale", Vector3.ONE * 1.2, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
