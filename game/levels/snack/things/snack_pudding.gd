class_name SnackPudding
extends StaticBody3D
## A giant wobbly pudding sunk into the ground: walk onto it, or land on
## it, and it throws the hero high, like a spring. Only its top sticks out,
## low enough to walk onto.

var level: Level
var power := Hero.SPRING_SPEED
var model_scale := 4.0
## How far the top stands above the ground it's sunk into.
var rise := 0.3

var _model: Node3D
var _top: Area3D
var _cool := 0.0
var _size := Vector3.ONE


static func make(p_power := Hero.SPRING_SPEED, p_scale := 4.0) -> SnackPudding:
	var p := SnackPudding.new()
	p.power = p_power
	p.model_scale = p_scale
	return p


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	var b := SnackFood.bounds("food:pudding")
	_size = b.size * model_scale
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(_size.x * 0.85, rise, _size.z * 0.85)
	shape.shape = box
	shape.position.y = rise / 2.0
	add_child(shape)
	_model = Kit.model("food:pudding", model_scale)
	_model.position.y = rise - _size.y
	add_child(_model)
	_top = Area3D.new()
	_top.collision_layer = 0
	_top.collision_mask = Kit.LAYER_HERO
	_top.monitorable = false
	var ts := CollisionShape3D.new()
	var tb := BoxShape3D.new()
	tb.size = Vector3(_size.x * 0.9, 0.35, _size.z * 0.9)
	ts.shape = tb
	ts.position.y = rise + 0.15
	_top.add_child(ts)
	add_child(_top)


func _physics_process(delta: float) -> void:
	_cool = maxf(_cool - delta, 0.0)
	var h := level.hero if level else null
	if h and _cool <= 0.0 and h.velocity.y <= 1.0 and _top.overlaps_body(h):
		boing()


## Throws the hero up and wobbles.
func boing() -> void:
	_cool = 0.3
	level.hero.bounce(power)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_jump-high.ogg", -4.0, 0.05)
	var s := Vector3.ONE * model_scale
	var tw := create_tween()
	tw.tween_property(_model, "scale", s * Vector3(1.25, 0.7, 1.25), 0.06)
	tw.tween_property(_model, "scale", s, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
