class_name FrostyThrower
extends Launcher
## A snowman that rolls snowballs along `direction` every `period` seconds,
## low enough to the ground that a jump clears them.
##
##   add(FrostyThrower.snowman(Vector3.LEFT, 2.5), at)

## How big the snowballs are (their radius).
var ball_radius := 0.35

var _body_model: Node3D


static func snowman(p_direction: Vector3, p_period := 2.5, p_phase := 0.0, p_speed := 5.5) -> FrostyThrower:
	var t := FrostyThrower.new()
	t.model_name = "holiday:snowman-hat"
	t.model_scale = 1.3
	t.direction = p_direction.normalized()
	t.period = p_period
	t.phase = p_phase
	t.speed = p_speed
	t.shot_life = 6.0
	return t


func _ready() -> void:
	super()
	muzzle = Vector3(0, ball_radius + 0.06, 0)
	if get_child_count() > 0:
		_body_model = get_child(0) as Node3D


func fire() -> Projectile:
	var p := FrostySnowball.new()
	p.radius = ball_radius
	p.velocity = direction * speed
	p.fall = shot_gravity
	p.life = shot_life
	level.add(p, global_position + muzzle + direction * (0.8 + ball_radius))
	if _body_model:
		# A little bow as it lets go.
		var tw := create_tween()
		tw.tween_property(_body_model, "scale", Vector3(1.1, 0.88, 1.1) * model_scale, 0.08)
		tw.tween_property(_body_model, "scale", Vector3.ONE * model_scale, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return p
