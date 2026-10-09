class_name Breakable
extends StaticBody3D
## A crate or a brick. Ground pound it, or dive into it, and it breaks and
## lets out what's inside: coins, a heart, a hidden gem or a star.
## Strong crates only give way to a ground pound.

var level: Level
var model_name := "crate"
## "coins:3", "heart", "gem:<id>", "star:<id>" or "".
var contents := ""
var strong := false

var _broken := false


static func make(p_model := "crate", p_contents := "") -> Breakable:
	var b := Breakable.new()
	b.model_name = p_model
	b.contents = p_contents
	b.strong = p_model.ends_with("strong")
	return b


func _ready() -> void:
	add_to_group("poundable")
	collision_layer = Kit.LAYER_WORLD
	collision_mask = 0
	var size := 0.6 if strong else 0.5
	var scale := 1.6
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE * size * scale
	shape.shape = box
	shape.position.y = size * scale / 2.0
	add_child(shape)
	add_child(Kit.model(model_name, scale))
	if not strong:
		var hit := Area3D.new()
		hit.collision_layer = 0
		hit.collision_mask = Kit.LAYER_HERO
		hit.monitorable = false
		var hs := CollisionShape3D.new()
		var hb := BoxShape3D.new()
		hb.size = Vector3.ONE * (size * scale + 0.3)
		hs.shape = hb
		hs.position.y = size * scale / 2.0
		hit.add_child(hs)
		add_child(hit)
		hit.body_entered.connect(_on_touch)


func _on_touch(body: Node3D) -> void:
	if body == level.hero and level.hero.is_diving():
		pound()


func pound() -> void:
	if _broken:
		return
	_broken = true
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPlank_medium_000.ogg", -2.0, 0.1)
	_debris()
	var top := global_position + Vector3.UP * 0.4
	var parts := contents.split(":")
	match parts[0]:
		"coins":
			var n := int(parts[1]) if parts.size() > 1 else 1
			for i in n:
				var c := Pickup.make("coin")
				var a := TAU * i / n
				level.add(c, top - level.global_position + Vector3(cos(a), 0.0, sin(a)) * 0.7)
		"heart":
			level.add(Pickup.make("heart"), top - level.global_position)
		"gem":
			level.add(Pickup.make("gem", parts[1], level.found_gems.has(parts[1])), top - level.global_position)
		"star":
			level.add(Pickup.make("star", parts[1], level.found_stars.has(parts[1])), top - level.global_position + Vector3.UP * 0.3)
	queue_free()


func _debris() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("c4834a") if model_name.begins_with("crate") else Color("b8573a")
	for i in 6:
		var m := MeshInstance3D.new()
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * 0.18
		m.mesh = cube
		m.material_override = mat
		level.add_child(m)
		m.global_position = global_position + Vector3(randf_range(-0.3, 0.3), 0.4, randf_range(-0.3, 0.3))
		var to := m.global_position + Vector3(randf_range(-1, 1), randf_range(0.2, 1.0), randf_range(-1, 1))
		var tw := m.create_tween()
		tw.set_parallel()
		tw.tween_property(m, "global_position", to, 0.35).set_ease(Tween.EASE_OUT)
		tw.tween_property(m, "scale", Vector3.ONE * 0.01, 0.4)
		tw.chain().tween_callback(m.queue_free)
