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
## Uses its own saves (user://screenshot-progress.cfg).

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
	Progress.use_path("user://screenshot-progress.cfg", "user://screenshot-ghosts/")
	Progress.wipe()
	Progress.find_course("sawmill")
	var stars := Worlds.star_ids("sunny")
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
