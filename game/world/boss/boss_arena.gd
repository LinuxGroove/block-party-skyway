class_name BossArena
extends Level
## Base for a boss's arena, in Adventure: an island with the boss on it.
## Beat the boss and its star appears at `star_spot`; collect it and the
## hero goes back to the world's island, with the Skyway to the next world
## brought back.
##
## A subclass builds the arena in build(), then calls add_boss() with its
## Boss.

## The boss's health, for the HUD.
signal boss_changed(boss_name: String, health: int, max_health: int)

var boss: Boss
## Where the star appears.
var star_spot := Vector3(0, 1.2, 0)


func _init() -> void:
	super()
	camera_base = [0.0, 38.0, 12.0, true]


func boss_def() -> Dictionary:
	return Worlds.boss_def(world)


## Adds the boss and listens to it.
func add_boss(b: Boss, at: Vector3) -> Boss:
	if b.boss_name == "":
		b.boss_name = str(boss_def().get("name", "The boss"))
	add(b, at)
	b.health_changed.connect(_on_boss_health)
	b.defeated.connect(_on_boss_defeated)
	boss = b
	_on_boss_health(b.health, b.max_health)
	return b


func _on_boss_health(health: int, max_health: int) -> void:
	boss_changed.emit(boss.boss_name, health, max_health)


func _on_boss_defeated() -> void:
	boss_changed.emit(boss.boss_name, 0, boss.max_health)
	say("%s is beaten!" % boss.boss_name)
	add_star(str(boss_def().get("star", "")), star_spot)
