class_name CastleBannerPole
extends Area3D
## A flagpole with its banner pulled down. Touch the pole and the banner
## runs back up to the top.

signal raised(pole: CastleBannerPole)

const BANNER := "castle:flag-banner-short"
const POLE_HEIGHT := 3.2

var level: Level
var facing := Vector3.BACK
var is_raised := false

var _banner: Node3D


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 2.4, 1.4)
	shape.shape = box
	shape.position.y = 1.2
	add_child(shape)
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.08
	cyl.height = POLE_HEIGHT
	cyl.radial_segments = 8
	pole.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("6b4a35")
	pole.material_override = mat
	pole.position.y = POLE_HEIGHT / 2.0
	add_child(pole)
	var knob := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.13
	ball.height = 0.26
	knob.mesh = ball
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffcf40")
	gold.metallic = 0.4
	knob.material_override = gold
	knob.position.y = POLE_HEIGHT + 0.08
	add_child(knob)
	# The kit's banner hangs from a bar along z at its top; turn it to face.
	_banner = Kit.model(BANNER, 1.8)
	_banner.rotation.y = atan2(facing.x, facing.z) + PI / 2.0
	add_child(_banner)
	_set_height(1.0 if is_raised else 0.0)
	body_entered.connect(_on_body_entered)


## 0 is down by the foot of the pole, 1 at the top.
func _set_height(u: float) -> void:
	# Hung beside the pole, not threaded on it.
	var side := facing.cross(Vector3.UP).normalized() * (0.63 * 1.8 * 0.5 + 0.07)
	_banner.position = Vector3.UP * lerpf(0.15, POLE_HEIGHT - 0.78 * 1.8, u) + side
	_banner.scale = Vector3(1.8, 1.8 * lerpf(0.35, 1.0, u), 1.8)


func _on_body_entered(body: Node3D) -> void:
	if is_raised or level == null or body != level.hero:
		return
	is_raised = true
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/confirmation_001.ogg", -2.0)
	var tw := create_tween()
	tw.tween_method(_set_height, 0.0, 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	raised.emit(self)
