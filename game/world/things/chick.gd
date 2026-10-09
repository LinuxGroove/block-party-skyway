class_name Chick
extends Area3D
## A lost chick. Touch it and it hops off home to its mother.

signal found(chick: Chick)

var level: Level
var home := Vector3.ZERO
var is_home := false

var _rig: RigCharacter
var _t := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	shape.shape = sphere
	shape.position.y = 0.3
	add_child(shape)
	_rig = RigCharacter.create(Kit.scene("animal-chick"), 0.22)
	add_child(_rig)
	_rig.play("idle")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if not is_home:
		_rig.rotation.y = sin(_t * 1.3) * 1.2


func _on_body_entered(body: Node3D) -> void:
	if body != level.hero or is_home:
		return
	go_home()


func go_home() -> void:
	if is_home:
		return
	is_home = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_select.ogg", 0.0)
	_rig.play("run")
	var tw := create_tween()
	var mid := (position + home) / 2.0 + Vector3.UP * 3.0
	tw.tween_property(self, "position", mid, 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", home, 0.5).set_ease(Tween.EASE_IN)
	tw.tween_callback(_arrived)


func _arrived() -> void:
	_rig.play("dance")
	found.emit(self)
