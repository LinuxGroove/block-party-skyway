class_name StationTurret
extends Launcher
## A laser turret: a station machine that fires a glowing bolt along
## `direction` every `period` seconds, at knee height, so a jump clears it.
##
##   add(StationTurret.laser(Vector3.RIGHT, 1.8), at)


static func laser(p_direction: Vector3, p_period := 2.0, p_phase := 0.0, p_speed := 8.0) -> StationTurret:
	var t := StationTurret.new()
	t.model_name = ""
	t.direction = p_direction.normalized()
	t.period = p_period
	t.phase = p_phase
	t.speed = p_speed
	t.shot_life = 3.0
	t.muzzle = Vector3(0, 0.45, 0)
	return t


func _ready() -> void:
	super()
	# The kit's machine with a cone on one side (its -x) makes a turret.
	var m := Kit.model("station:computer-system", 1.3)
	m.rotation.y = atan2(direction.z, -direction.x)
	add_child(m)
	var eye := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.12
	ball.height = 0.24
	eye.mesh = ball
	eye.material_override = StationDeco.glow(Color("ff4d6d"))
	eye.position = Vector3(0, 0.95, 0)
	add_child(eye)
	if level:
		level.solid(global_position + Vector3(-0.55, 0, -0.55), global_position + Vector3(0.55, 0.8, 0.55))


func fire() -> Projectile:
	var p := StationBolt.new()
	p.velocity = direction * speed
	p.life = shot_life
	level.add(p, global_position - level.global_position + muzzle + direction * 0.9)
	return p
