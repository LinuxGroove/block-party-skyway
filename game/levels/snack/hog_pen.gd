class_name HogPen
extends BossArena
## The Hungry Hog's pen: a round frosting floor ringed by eight giant cakes,
## with gaps between them that drop off the island. The Hog charges at the
## hero and gets stuck in whichever cake is behind them.

const RING := 10.5
const CAKE_SCALE := 8.5

var hog: HungryHog
var _cake_props: Array[Node3D] = []


func _init() -> void:
	super()
	title = "The Hungry Hog's Pen"
	spawn = Vector3(0, 0, 6.5)
	spawn_facing = Vector3.FORWARD
	camera_base = [0.0, 40.0, 14.0, true]
	star_spot = Vector3(0, 1.2, 0)


func build() -> void:
	# A rough circle of frosting: three overlapping slabs.
	land(-14, -8, 14, 8, 0, 3)
	land(-8, -14, 8, 14, 0, 3)
	land(-12, -12, 12, 12, 0, 3)
	# A cream path in from the south, where the hero arrives.
	land(-2, 14, 2, 18, 0, 3, "snow")
	add_checkpoint(Vector3(0, 0, 8.5), Vector3.FORWARD)
	var cakes := []
	for i in 8:
		var a := TAU * i / 8.0 + TAU / 16.0
		var at := Vector3(sin(a) * RING, 0, cos(a) * RING)
		var model := "food:cake-birthday" if i % 2 == 0 else "food:cake"
		var b := SnackFood.bounds(model)
		SnackFood.body(self, at, maxf(b.size.x, b.size.z) / 2.0 * CAKE_SCALE * 0.92, b.end.y * CAKE_SCALE)
		# Drawn as its own node, so it can wobble when the Hog hits it.
		var cake := Kit.model(model, CAKE_SCALE)
		cake.position = at
		cake.rotation.y = a
		add_child(cake)
		_cake_props.append(cake)
		cakes.append([at, maxf(b.size.x, b.size.z) / 2.0 * CAKE_SCALE])
	for at in [Vector3(-11.5, 0, 0), Vector3(11.5, 0, 0), Vector3(0, 0, -11.5)]:
		add_heart(at)
	for at in [Vector3(-6, 0, 11), Vector3(6, 0, 11), Vector3(-1, 0, 16.5)]:
		SnackFood.stick(self, "food:lollypop", at, 6.0, at.x * 20.0)
	hog = HungryHog.new()
	hog.cakes = cakes
	add_boss(hog, Vector3(0, 0, -1))
	finish()


## A cake shakes when the Hog smashes into it.
func wobble_cake(i: int) -> void:
	if i < 0 or i >= _cake_props.size():
		return
	var cake := _cake_props[i]
	var s := Vector3.ONE * CAKE_SCALE
	var tw := create_tween()
	tw.tween_property(cake, "scale", s * Vector3(1.12, 0.85, 1.12), 0.08)
	tw.tween_property(cake, "scale", s, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func shots() -> Array:
	return [{"name": "cakes", "at": Vector3(0, 0, 12), "face": Vector3.FORWARD}]
