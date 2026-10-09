class_name Projectile
extends Area3D
## Something thrown or fired (a cannonball, a snowball, a laser bolt) that
## flies straight, hurts the hero on touch and goes after `life` seconds or
## when it hits the ground. Launcher fires these.

var level: Level
var model_name := "pirate:cannon-ball"
var model_scale := 1.0
var velocity := Vector3.ZERO
## Pulls it down (0 flies straight).
var fall := 0.0
var life := 4.0
var radius := 0.35

var _model: Node3D


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO | Kit.LAYER_WORLD
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	add_child(shape)
	if model_name != "":
		_model = Kit.model(model_name, model_scale)
		add_child(_model)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	velocity.y -= fall * delta
	position += velocity * delta
	if _model:
		_model.rotation.x += delta * 6.0


func _on_body(body: Node3D) -> void:
	if level and body == level.hero:
		level.hurt_hero(global_position - velocity.normalized())
	set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.12)
	tw.tween_callback(queue_free)
