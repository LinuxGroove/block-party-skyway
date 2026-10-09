class_name Kit
extends RefCounted
## Kenney's Platformer Kit and Cube Pets models, by name.
##
## Levels draw the many repeated pieces (blocks, fences, flowers) through
## MultiMeshes built from each model's meshes, so an island of hundreds of
## blocks is a handful of draw calls; anything that moves or animates is an
## ordinary instance of the model.

const PLATFORMER := "res://assets/kenney/platformer-kit/"
const PETS := "res://assets/kenney/cube-pets/"

## Physics layers.
const LAYER_WORLD := 1
const LAYER_HERO := 2
const LAYER_PICKUP := 4

static var _meshes := {}


static func path(model_name: String) -> String:
	if model_name.begins_with("animal-"):
		return PETS + model_name + ".glb"
	return PLATFORMER + model_name + ".glb"


static func scene(model_name: String) -> PackedScene:
	return load(path(model_name))


## A fresh instance of a model.
static func model(model_name: String, scale := 1.0) -> Node3D:
	var n: Node3D = scene(model_name).instantiate()
	if scale != 1.0:
		n.scale = Vector3.ONE * scale
	return n


## The meshes in a model and where each sits in it: [[Mesh, Transform3D]].
static func meshes(model_name: String) -> Array:
	if _meshes.has(model_name):
		return _meshes[model_name]
	var out := []
	var root := scene(model_name).instantiate()
	_collect(root, Transform3D.IDENTITY, out, true)
	root.free()
	_meshes[model_name] = out
	return out


static func _collect(n: Node, xf: Transform3D, out: Array, is_root: bool) -> void:
	var t := xf
	if n is Node3D and not is_root:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out.append([(n as MeshInstance3D).mesh, t])
	for c in n.get_children():
		_collect(c, t, out, false)
