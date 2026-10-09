class_name BigChillArena
extends BossArena
## The Big Chill's arena: an ice rink with a snowy edge, ringed by a low
## snow wall and watched by a crowd of penguins. Getting knocked (or
## jumping) over the wall and off the edge comes back at the flag.

const HALF := 9


func _init() -> void:
	super()
	title = "The Big Chill"
	spawn = Vector3(0, 0, 6.5)
	spawn_facing = Vector3.FORWARD
	star_spot = Vector3(0, 1.2, 0)


func build() -> void:
	# The floor: snow all round, ice in the middle.
	land(-13, -13, 13, -5, 0, 4, "snow")
	land(-13, 5, 13, 13, 0, 4, "snow")
	land(-13, -5, -5, 5, 0, 4, "snow")
	land(5, -5, 13, 5, 0, 4, "snow")
	land(-5, -5, 5, 5, -0.5, 3.5, "snow")
	FrostyBuild.ice(self, -5, -5, 5, 5, 0.0, 0.5)
	# The wall round the rink, low enough to jump.
	land(-HALF - 1, -HALF - 1, HALF + 1, -HALF, 1.0, 1, "snow")
	land(-HALF - 1, HALF, HALF + 1, HALF + 1, 1.0, 1, "snow")
	land(-HALF - 1, -HALF, -HALF, HALF, 1.0, 1, "snow")
	land(HALF, -HALF, HALF + 1, HALF, 1.0, 1, "snow")
	add_checkpoint(spawn, Vector3.FORWARD)
	for at in [Vector3(-HALF - 0.5, 1, -HALF - 0.5), Vector3(HALF + 0.5, 1, -HALF - 0.5), Vector3(-HALF - 0.5, 1, HALF + 0.5), Vector3(HALF + 0.5, 1, HALF + 0.5)]:
		add_heart(at)
	var bear := FrostyBigChill.new()
	bear.center = Vector3.ZERO
	bear.half = HALF
	add_boss(bear, Vector3(0, 0, -5))
	_crowd()
	finish()


## Penguins watching from the edge, and some holiday trimmings.
func _crowd() -> void:
	var spots := [Vector3(-6, 0, -11.5), Vector3(-3, 0, -11.8), Vector3(3, 0, -11.6), Vector3(6, 0, -11.8),
		Vector3(-11.6, 0, -4), Vector3(-11.8, 0, 3), Vector3(11.6, 0, -2), Vector3(11.8, 0, 4)]
	for i in spots.size():
		var at: Vector3 = spots[i]
		var fan := RigCharacter.create(Kit.scene("animal-penguin"), 0.36)
		fan.position = at
		var to := -at
		fan.rotation.y = atan2(to.x, to.z)
		add_child(fan)
		fan.set_looping("dance")
		fan.play_once("dance", 0.1, 0.8 + 0.1 * (i % 3))
	for at in [Vector3(-12, 0, -12), Vector3(12, 0, -12), Vector3(-12, 0, 12), Vector3(12, 0, 12)]:
		tree(at, "holiday:tree-decorated-snow", 1.5)
	for at in [Vector3(-11.8, 0, 8), Vector3(11.8, 0, -8), Vector3(8, 0, 11.8), Vector3(-8, 0, -11.8)]:
		deco("holiday:lantern", at, 0.0, 1.6)
	for at in [Vector3(-11.5, 0, 10), Vector3(10.5, 0, 11.5), Vector3(11.4, 0, 9.5)]:
		deco("holiday:" + FrostyBuild.PRESENTS[int(absf(at.x)) % 4], at, at.z * 20.0, 1.6)
	for x in [-11.6, 11.6]:
		deco("holiday:snowman-hat", Vector3(x, 0, -9.5), 90.0 if x < 0 else -90.0, 1.4)
