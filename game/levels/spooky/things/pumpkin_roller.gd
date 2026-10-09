class_name SpookyPumpkinRoller
extends Launcher
## Rolls a big pumpkin along the ground every `period` seconds, out of a gap
## in a hay wall, say. It has no model of its own.

## The pumpkins it has rolled that are still about, for tests and the pilot.
var rolled: Array[SpookyRollingPumpkin] = []


static func roll(p_direction: Vector3, p_period := 2.4, p_phase := 0.0, p_speed := 6.0) -> SpookyPumpkinRoller:
	var r := SpookyPumpkinRoller.new()
	r.model_name = ""
	r.direction = p_direction.normalized()
	r.period = p_period
	r.phase = p_phase
	r.speed = p_speed
	r.muzzle = Vector3(0, 0.5, 0)
	return r


func fire() -> Projectile:
	var p := SpookyRollingPumpkin.new()
	p.velocity = direction * speed
	p.life = shot_life
	level.add(p, global_position + muzzle + direction * 1.0)
	var still: Array[SpookyRollingPumpkin] = []
	for q in rolled:
		if is_instance_valid(q):
			still.append(q)
	still.append(p)
	rolled = still
	return p


## Seconds until the next pumpkin rolls out.
func next_shot() -> float:
	return period - _t
