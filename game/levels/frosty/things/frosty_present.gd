class_name FrostyPresent
extends Area3D
## One of Dasher's lost presents. Touch it and it flies back to his sled.

signal found(present: FrostyPresent)

const MODELS := ["holiday:present-a-cube", "holiday:present-b-round", "holiday:present-a-rectangle"]

var level: Level
## Where it lands on the sled.
var home := Vector3.ZERO
var kind := 0
var is_home := false

var _model: Node3D
var _t := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 0.9, 0.9)
	shape.shape = box
	shape.position.y = 0.45
	add_child(shape)
	_model = Kit.model(MODELS[kind % MODELS.size()], 1.4)
	add_child(_model)
	_t = position.x
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if not is_home:
		# A slow wobble so it catches the eye.
		_model.rotation.y = sin(_t * 1.1) * 0.5
		_model.position.y = absf(sin(_t * 2.4)) * 0.12


func _on_body_entered(body: Node3D) -> void:
	if body == level.hero and not is_home:
		go_home()


func go_home() -> void:
	if is_home:
		return
	is_home = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_magic.ogg", -4.0)
	_model.position.y = 0.0
	var tw := create_tween()
	var mid := (position + home) / 2.0 + Vector3.UP * 6.0
	tw.tween_property(self, "position", mid, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", home, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_arrived)


## Puts it straight on the sled (for a visit after the request is done).
func place_home() -> void:
	is_home = true
	monitoring = false
	position = home


func _arrived() -> void:
	found.emit(self)
