extends Node
## Boots the game: input map, theme and window, then the title screen.
##
## Developer shortcuts (after `--`):
##   --play=sunny        skip the menus and start Adventure on an island
##   --course=sawmill    skip the menus and run a course in Speedrun
##   --set=video/fullscreen=false   any setting, for one run

func _ready() -> void:
	LGSettings.register_defaults(GameConfig.SETTING_DEFAULTS)
	LGLaunchPing.send(GameConfig.GAME_ID)
	LGInput.register_actions(GameConfig.ACTIONS, float(LGSettings.get_value("input", "stick_deadzone")))
	LGInput.extend_ui_actions()
	LGTheme.apply(get_tree().root, 22)
	get_window().title = GameConfig.TITLE
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--play="):
			LGSettings.set_value("tutorial", "welcomed", true, false)
			Play.open(a.trim_prefix("--play="), "adventure")
			return
		if a.begins_with("--course="):
			LGSettings.set_value("tutorial", "welcomed", true, false)
			Play.open(a.trim_prefix("--course="), "speedrun")
			return
	LGScenes.change_scene("res://game/ui/title.tscn")
