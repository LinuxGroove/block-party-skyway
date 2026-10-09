class_name GearsDecor
extends RefCounted
## Floor markings for Gear Works' decks: dark steel plates in a strip, and
## orange arrows painted on the floor.


## Lays dark floor plates every `step` metres from `a` to `b` (both ends
## included), just above the floor.
static func strip(level: Level, a: Vector3, b: Vector3, step := 2.0, model := "factory:floor-large") -> void:
	var n := maxi(int(roundf(a.distance_to(b) / step)), 0)
	for i in n + 1:
		var at := a.lerp(b, float(i) / maxf(n, 1))
		level.deco(model, at + Vector3.UP * 0.012, 0.0, step / 2.0)


## An orange arrow painted on the floor at `at`, pointing along `dir`.
static func arrow(level: Level, at: Vector3, dir: Vector3, size := 1.6) -> void:
	# The arrow model points west (-x) unturned.
	var yaw := rad_to_deg(atan2(dir.z, -dir.x))
	level.deco("factory:indicator-special-arrow", at + Vector3.UP * 0.02, yaw, size)
