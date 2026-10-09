class_name FrostyTrain
extends AnimatableBody3D
## A toy train from the Holiday Kit, blown up big enough to ride: cars in a
## line behind the front one, shuttling along `axis` between home and
## `travel` metres away. It waits `stop` seconds at each end, takes `run`
## seconds between them (easing in and out), and carries whoever stands on
## it. A flat wagon's top is 0.85 m above the train's feet; set the feet
## that far under a platform and riders walk straight on and off.
##
##   add(FrostyTrain.make(Vector3.FORWARD, 20.0, ["loco", "wagon", "wagon"]), nose)

const TOP := 0.85
const WIDTH := 1.9
const GAP := 0.15
## Each car: model, length, height, and how much its model is widened (the
## kit's engine is wider than its wagons).
const CARS := {
	"loco": ["holiday:train-locomotive", 0.67 * 5.0, 0.43 * 5.0, WIDTH / 0.27],
	"wagon": ["holiday:train-wagon-flat", 0.69 * 5.0, TOP, WIDTH / 0.19],
}

var level: Level
## Which way the front points, and the way it goes from home (flat, unit).
var axis := Vector3.FORWARD
var travel := 10.0
var run := 3.0
var stop := 2.0
## Seconds into its cycle at the start.
var phase := 0.0
## Car kinds from the front.
var cars: Array = ["loco", "wagon", "wagon"]

var _home := Vector3.ZERO
var _t := 0.0


static func make(p_axis: Vector3, p_travel: float, p_cars: Array, p_run := 3.0, p_stop := 2.0, p_phase := 0.0) -> FrostyTrain:
	var t := FrostyTrain.new()
	t.axis = p_axis.normalized()
	t.travel = p_travel
	t.cars = p_cars
	t.run = p_run
	t.stop = p_stop
	t.phase = p_phase
	return t


func _ready() -> void:
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase
	var turn := atan2(-axis.z, axis.x)
	var back := 0.0
	for kind in cars:
		var c: Array = CARS[kind]
		var length: float = c[1]
		var height: float = c[2]
		var mid := -axis * (back + length / 2.0)
		var m := Kit.model(c[0])
		m.scale = Vector3(5, 5, c[3])
		m.rotation.y = turn
		m.position = mid
		add_child(m)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(length, height, WIDTH)
		shape.shape = box
		shape.rotation.y = turn
		shape.position = mid + Vector3.UP * height / 2.0
		add_child(shape)
		back += length + GAP
	_place()


## Seconds in one trip there and back.
func cycle() -> float:
	return 2.0 * (stop + run)


## How far along it is at time t: 0 at home, 1 at the far end.
func along_at(t: float) -> float:
	var u := fposmod(t, cycle())
	if u < stop:
		return 0.0
	u -= stop
	if u < run:
		return smoothstep(0.0, 1.0, u / run)
	u -= run
	if u < stop:
		return 1.0
	u -= stop
	return 1.0 - smoothstep(0.0, 1.0, u / run)


## Where its front is `ahead` seconds from now (for tests and the autopilot).
func front_at(ahead := 0.0) -> Vector3:
	return _home + axis * travel * along_at(_t + ahead)


## Where a point `back` metres behind the front is, `ahead` seconds from now.
func point_at(back: float, ahead := 0.0) -> Vector3:
	return front_at(ahead) - axis * back


func along() -> float:
	return along_at(_t)


## Seconds until it next sets off from home (0 while moving).
func time_to_leave() -> float:
	var u := fposmod(_t, cycle())
	return stop - u if u < stop else 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	_place()


func _place() -> void:
	position = _home + axis * travel * along_at(_t)
