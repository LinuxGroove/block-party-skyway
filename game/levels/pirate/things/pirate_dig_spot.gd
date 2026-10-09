class_name PirateDigSpot
extends Node3D
## X marks the spot: a cross on the sand where treasure is buried. Ground
## pound it and the sand flies, a chest comes up and opens, and what's
## inside pops out (a star, usually).

signal dug

var level: Level
## "star:<id>", "gem:<id>" or "coins:<n>".
var contents := ""
var is_dug := false

var _cross: Node3D
var _chest: Node3D


static func make(p_contents: String) -> PirateDigSpot:
	var d := PirateDigSpot.new()
	d.contents = p_contents
	return d


func _ready() -> void:
	add_to_group("poundable")
	_cross = Node3D.new()
	add_child(_cross)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c0392b")
	mat.roughness = 0.9
	for turn in [45.0, -45.0]:
		var bar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.22, 0.04, 1.3)
		bar.mesh = bm
		bar.material_override = mat
		bar.position.y = 0.02
		bar.rotation_degrees.y = turn
		_cross.add_child(bar)
	var shovel := Kit.model("pirate:tool-shovel", 0.6)
	shovel.position = Vector3(0.9, 0, -0.4)
	shovel.rotation_degrees = Vector3(-12, 30, 8)
	add_child(shovel)
	var parts := contents.split(":")
	if parts[0] == "star" and level and level.found_stars.has(parts[1]):
		# Dug on an earlier visit: the hole is still there, with the star.
		_show_hole()
		level.add_star(parts[1], position + Vector3.UP * 0.5)
		is_dug = true


func _show_hole() -> void:
	_cross.visible = false
	var hole := Kit.model("pirate:hole", 0.7)
	add_child(hole)


func pound() -> void:
	if is_dug:
		return
	is_dug = true
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", -2.0, 0.1)
	_sand()
	_show_hole()
	_chest = Kit.model("pirate:chest", 0.6)
	_chest.position.y = -0.7
	add_child(_chest)
	var tw := create_tween()
	tw.tween_property(_chest, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_open)
	tw.tween_interval(0.35)
	tw.tween_callback(_reward)


func _open() -> void:
	var anim := _chest.find_children("*", "AnimationPlayer", true, false)
	if not anim.is_empty():
		anim[0].play("open")
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/open_001.ogg", -2.0)


func _reward() -> void:
	var parts := contents.split(":")
	var top := position + Vector3.UP * 0.9
	match parts[0]:
		"star":
			level.add_star(parts[1], top)
		"gem":
			level.add(Pickup.make("gem", parts[1], level.found_gems.has(parts[1])), top)
		"coins":
			for i in int(parts[1]):
				var a := TAU * i / int(parts[1])
				level.add_coin(top + Vector3(cos(a), -0.4, sin(a)) * 0.8)
	dug.emit()


## A burst of sand.
func _sand() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("f2d48f")
	for i in 10:
		var m := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 0.16
		m.mesh = cube
		m.material_override = mat
		add_child(m)
		m.position = Vector3(randf_range(-0.3, 0.3), 0.1, randf_range(-0.3, 0.3))
		var to := m.position + Vector3(randf_range(-1.2, 1.2), randf_range(0.6, 1.4), randf_range(-1.2, 1.2))
		var tw := m.create_tween()
		tw.set_parallel()
		tw.tween_property(m, "position", to, 0.4).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "scale", Vector3.ONE * 0.01, 0.5)
		tw.chain().tween_callback(m.queue_free)
