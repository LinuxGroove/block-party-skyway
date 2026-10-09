class_name SnackFood
extends RefCounted
## Snack Valley's giant food: Food Kit models scaled up, as scenery or as
## solid things to stand on. The models' sizes come from their meshes, so a
## cake at scale 10 gets a body exactly as wide and tall as it looks.
##
##   SnackFood.prop(level, "food:lollypop", at, 6.0)              # scenery
##   var top := SnackFood.solid(level, "food:cake", at, 10.0)     # stand on it

static var _bounds := {}


## The model's box at scale 1, from its meshes.
static func bounds(model_name: String) -> AABB:
	if _bounds.has(model_name):
		return _bounds[model_name]
	var box := AABB()
	var first := true
	for entry in Kit.meshes(model_name):
		var mesh: Mesh = entry[0]
		var xf: Transform3D = entry[1]
		var b := xf * mesh.get_aabb()
		box = b if first else box.merge(b)
		first = false
	_bounds[model_name] = box
	return box


## Food to look at: drawn (batched), no body.
static func prop(level: Level, model_name: String, at: Vector3, scale: float, turn := 0.0) -> void:
	level.piece(model_name, at, turn, scale)


## Food to stand on: drawn, with a round body (or a box, `round` false) as
## wide and tall as the model. `fit` shrinks the body a little inside the
## model's outline. Returns the height of its top.
static func solid(level: Level, model_name: String, at: Vector3, scale: float, turn := 0.0, round := true, fit := 0.92) -> float:
	level.piece(model_name, at, turn, scale)
	var b := bounds(model_name)
	var size := b.size * scale
	var centre := Vector3(b.get_center().x, 0, b.get_center().z) * scale
	centre = centre.rotated(Vector3.UP, deg_to_rad(turn))
	var top := at.y + b.end.y * scale
	var bottom := at.y + b.position.y * scale
	if round:
		body(level, at + centre + Vector3.UP * (bottom - at.y), maxf(size.x, size.z) / 2.0 * fit, top - bottom)
	else:
		var shape := level.solid(Vector3(-size.x, 0, -size.z) / 2.0 * fit, Vector3(size.x, 0, size.z) / 2.0 * fit + Vector3.UP * (top - bottom))
		shape.position += at + centre + Vector3.UP * (bottom - at.y)
		shape.rotation.y = deg_to_rad(turn)
	return top


## A solid upright cylinder: its foot at `foot`.
static func body(level: Level, foot: Vector3, radius: float, height: float) -> StaticBody3D:
	var b := StaticBody3D.new()
	b.collision_layer = Kit.LAYER_WORLD
	b.collision_mask = 0
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	shape.shape = cyl
	shape.position = foot + Vector3.UP * height / 2.0
	b.add_child(shape)
	level.add_child(b)
	return b


## A tall thin thing (a lollipop, a popsicle, a candle) with a stick the
## hero bumps into.
static func stick(level: Level, model_name: String, at: Vector3, scale: float, turn := 0.0, thick := 0.3) -> void:
	level.piece(model_name, at, turn, scale)
	var h := bounds(model_name).end.y * scale
	level.solid(at + Vector3(-thick / 2.0, 0, -thick / 2.0), at + Vector3(thick / 2.0, h * 0.6, thick / 2.0))
