class_name SkywayGate
extends Node3D
## Where the Skyway leaves an island for another world: a rainbow arch on
## two posts. It glows once that world is open (its boss before it beaten)
## and Talk walks across; until then it's grey, and says what it needs.

var level: Level
var to_world := ""
var facing := Vector3.BACK
## For Level.arrival(): arriving from `to_world` comes out here.
var arrive_id: String:
	get:
		return "skyway:" + to_world

var _arch: MeshInstance3D


func _ready() -> void:
	add_to_group("talker")
	add_to_group("arrival")
	var turn := atan2(facing.x, facing.z)
	var side := facing.cross(Vector3.UP).normalized()
	for s in [-1.4, 1.4]:
		var post := Kit.model("block-snow-narrow", 1.0)
		post.position = side * s
		post.scale = Vector3(0.5, 3.0, 0.5)
		add_child(post)
	_arch = MeshInstance3D.new()
	_arch.mesh = _rainbow()
	_arch.rotation.y = turn
	add_child(_arch)
	_refresh()
	if level:
		for s in [-1.4, 1.4]:
			var at: Vector3 = global_position + side * s
			level.solid(at + Vector3(-0.25, 0, -0.25), at + Vector3(0.25, 3.0, 0.25))


## Half a ring of six bands over the gate.
func _rainbow() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 20
	for b in SkywayBridge.BANDS.size():
		var r0 := 1.3 + b * 0.12
		var r1 := r0 + 0.12
		var c: Color = SkywayBridge.BANDS[SkywayBridge.BANDS.size() - 1 - b]
		for i in steps:
			var a0 := PI * i / steps
			var a1 := PI * (i + 1) / steps
			var p := [Vector3(cos(a0) * r0, sin(a0) * r0, 0), Vector3(cos(a0) * r1, sin(a0) * r1, 0),
				Vector3(cos(a1) * r1, sin(a1) * r1, 0), Vector3(cos(a1) * r0, sin(a1) * r0, 0)]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(c)
				st.set_normal(Vector3.BACK)
				st.add_vertex(p[idx] + Vector3.UP * 2.0)
	return st.commit()


func _refresh() -> void:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if is_open():
		mat.emission_enabled = true
		mat.emission_energy_multiplier = 0.35
	else:
		mat.albedo_color = Color(0.35, 0.35, 0.4, 0.45)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_arch.material_override = mat


func is_open() -> bool:
	if not Worlds.is_built(to_world):
		return false
	# Going back is always open; going on needs the next world open.
	return Worlds.ORDER.find(to_world) < Worlds.ORDER.find(level.world) or Worlds.is_open(to_world)


func can_talk() -> bool:
	return level.hero != null and level.hero.is_on_floor()


func talk_range() -> float:
	return 2.0


func talk_text() -> String:
	if is_open():
		return "Skyway to %s" % Worlds.world_name(to_world)
	return "Skyway to %s: faded" % Worlds.world_name(to_world)


func talk() -> void:
	if not is_open():
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/error_004.ogg", -4.0)
		if not Worlds.is_built(to_world):
			level.say("The Skyway to %s is still faded. Nobody has been there yet." % Worlds.world_name(to_world))
		else:
			var before := Worlds.neighbour(to_world, -1)
			level.say("The Skyway to %s is faded. Beat %s to bring it back." % [Worlds.world_name(to_world), Worlds.boss_def(before).get("name", "the boss")])
		return
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_magic.ogg", -2.0)
	level.travel_to(str(Worlds.get_def(to_world).island), {"door": "skyway:" + level.world})
