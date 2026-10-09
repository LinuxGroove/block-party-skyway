extends Node
## Saves a screenshot, for checking the look without a screen (run under
## xvfb-run, with --resolution WxH):
##   godot --path . --resolution 1280x720 tools/screenshot.tscn -- /tmp/shot.png [options]
## Options:
##   title | welcome | speedrun | settings | howto | about   a menu
##   play=sunny | course=sawmill | adventure=sawmill         a level
##   at=x,y,z   face=x,z   stick=x,y                         where the hero stands, and a camera nudge
##   pause | results | speech | banner | ghost               something over the level
##   stars=n    found a few stars first (the Skyway opens at 2)
##   hero=0..4  which astronaut
##   wait=2.5   seconds before the shot
## Or every level of every built world (or of one), as JPEGs in
## <dir>/<world>/<level>.jpg, plus any extra views a level lists in shots():
##   godot --path . --resolution 1280x720 tools/screenshot.tscn -- --all=docs/screenshots [world=frosty]
## Uses its own saves (user://screenshot-progress-<pid>.cfg).

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/shot.png"
	var opts := {}
	for i in range(1, args.size()):
		var a: String = args[i]
		if "=" in a:
			opts[a.get_slice("=", 0)] = a.get_slice("=", 1)
		else:
			opts[a] = true
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGInput.register_actions(GameConfig.ACTIONS)
	LGInput.extend_ui_actions()
	LGTheme.apply(get_tree().root, 22)
	LGSettings.set_value("video", "fullscreen", false, false)
	LGSettings.set_value("tutorial", "welcomed", not opts.has("welcome"), false)
	LGSettings.set_value("player", "hero", int(opts.get("hero", 0)), false)
	var pid := OS.get_process_id()
	Progress.use_path("user://screenshot-progress-%d.cfg" % pid, "user://screenshot-ghosts-%d/" % pid)
	Progress.wipe()
	for id in Courses.ids():
		Progress.find_course(id)
	if out.begins_with("--all="):
		await _all(out.trim_prefix("--all="), str(opts.get("world", "")), float(opts.get("wait", 2.5)))
		return
	var shot_level := str(opts.get("course", opts.get("adventure", opts.get("play", "sunny"))))
	var stars := Worlds.star_ids(Worlds.world_of(shot_level))
	for i in mini(int(opts.get("stars", 0)), stars.size()):
		Progress.add_star(stars[i])
	if opts.has("ghost"):
		Progress.record_time("sawmill", 41230, _fake_ghost())
	var wait := float(opts.get("wait", 2.5))
	get_tree().current_scene = null
	for menu in ["title", "welcome", "speedrun", "settings", "howto", "about"]:
		if opts.has(menu):
			LGScenes.change_scene("res://game/ui/title.tscn")
			await LGScenes.scene_changed
			var t: TitleScreen = get_tree().current_scene
			match menu:
				"speedrun":
					t._show_speedrun()
				"settings":
					t._show_settings()
				"howto":
					t._show_howto()
				"about":
					t._show_about()
			await get_tree().create_timer(wait).timeout
			_save(out)
			return
	var level := "sunny"
	var mode := "adventure"
	if opts.has("course"):
		level = opts.course
		mode = "speedrun"
	elif opts.has("adventure"):
		level = opts.adventure
	elif opts.has("play"):
		level = opts.play
	var arrive := {}
	if opts.has("at"):
		var p: PackedStringArray = str(opts.at).split(",")
		arrive.position = Vector3(float(p[0]), float(p[1]), float(p[2]))
		var f: PackedStringArray = str(opts.get("face", "0,-1")).split(",")
		arrive.facing = Vector3(float(f[0]), 0, float(f[1]))
	Play.open(level, mode, arrive)
	await LGScenes.scene_changed
	var play: Play = get_tree().current_scene
	if opts.has("stick"):
		var s: PackedStringArray = str(opts.stick).split(",")
		play.cam.stick_override = Vector2(float(s[0]), float(s[1]))
	await get_tree().create_timer(wait).timeout
	if opts.has("pause"):
		play.pause.open()
	if opts.has("speech"):
		play.level.speak("Pebble", ["Oh, my chicks! Three of them wandered off while I was napping."])
	if opts.has("banner"):
		play.hud.banner("Star found!", "The Lost Chicks", 10.0)
	if opts.has("results"):
		play.results.show_result(level, 40870, 41230, true)
	await get_tree().create_timer(0.8).timeout
	_save(out)


## Every level of the built worlds (or one world), one JPEG per view.
func _all(dir: String, only_world: String, wait: float) -> void:
	var root := dir if dir.begins_with("/") else ProjectSettings.globalize_path("res://").path_join(dir)
	# Scene changes replace the current scene; this one stays to drive them.
	get_tree().current_scene = null
	for w in Worlds.built():
		if only_world != "" and w != only_world:
			continue
		# The worlds before are done, so the way back is open.
		Progress.wipe()
		for i in Worlds.ORDER.find(w):
			Progress.add_star(str(Worlds.boss_def(Worlds.ORDER[i]).star))
		for id in Courses.ids():
			Progress.find_course(id)
		DirAccess.make_dir_recursive_absolute(root.path_join(w))
		for id in Levels.of_world(w):
			var probe := Levels.make(id)
			var views: Array = probe.shots() if probe.has_method("shots") else []
			probe.free()
			views.push_front({"name": ""})
			for v in views:
				var arrive := {}
				if v.has("at"):
					arrive = {"position": v.at, "facing": v.get("face", Vector3.FORWARD)}
				Play.open(id, "adventure", arrive)
				await LGScenes.scene_changed
				var play: Play = get_tree().current_scene
				if v.has("stick"):
					play.cam.stick_override = v.stick
				await get_tree().create_timer(wait).timeout
				await RenderingServer.frame_post_draw
				var file: String = id + ("-" + str(v.name) if str(v.name) != "" else "") + ".jpg"
				get_viewport().get_texture().get_image().save_jpg(root.path_join(w).path_join(file), 0.85)
				print("Saved ", w, "/", file)
	_write_index(root)
	get_tree().quit()


## A README.md beside the screenshots with every world's levels, from the
## images that are there.
func _write_index(root: String) -> void:
	var lines := ["# Screenshots", "", "Every level of Block Party: Skyway, made with:", "",
		"    xvfb-run -a -s \"-screen 0 1280x720x24\" godot --path . --resolution 1280x720 tools/screenshot.tscn -- --all=docs/screenshots", ""]
	for w in Worlds.built():
		var files := DirAccess.get_files_at(root.path_join(w))
		if files.is_empty():
			continue
		lines.append("## %s" % (Worlds.world_name(w) if Worlds.get_def(w).has("label") else "%s: %s" % [Worlds.label(w), Worlds.world_name(w)]))
		lines.append("")
		for id in Levels.of_world(w):
			var level := Levels.make(id)
			var title := level.title
			level.free()
			var kind := "island" if id == str(Worlds.get_def(w).island) else ("boss" if Worlds.is_boss(id) else "course")
			for f in files:
				if f == id + ".jpg" or (f.begins_with(id + "-") and f.ends_with(".jpg")):
					var view := f.trim_prefix(id).trim_prefix("-").trim_suffix(".jpg")
					lines.append("**%s** (%s%s)" % [title, kind, ", " + view if view != "" else ""])
					lines.append("")
					lines.append("![%s](%s/%s)" % [title, w, f])
					lines.append("")
	var out := FileAccess.open(root.path_join("README.md"), FileAccess.WRITE)
	if out:
		out.store_string("\n".join(lines))


func _fake_ghost() -> Ghost:
	var g := Ghost.new()
	for i in 20:
		g.frames.append_array([0.0, 0.0, 2.0 - i * 0.5, PI, 0.0])
		g.clips.append(2)
	return g


func _save(out: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out)
	print("Saved ", out)
	get_tree().quit()
