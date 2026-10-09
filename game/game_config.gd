class_name GameConfig
extends RefCounted
## Game-wide constants: identity, heroes, music, setting defaults and the
## input map.

const GAME_ID := "block-party-skyway"
const TITLE := "Block Party: Skyway"

## The five astronauts, Block Party's cast in 3D: name and Platformer Kit model.
const HEROES := [
	["Zip", "character-oobi"],
	["Sol", "character-oodi"],
	["Dot", "character-ooli"],
	["Plum", "character-oopi"],
	["Bean", "character-oozi"],
]

const SETTING_DEFAULTS := {
	"online": {
		"enabled": true,
		"host": OnlineServer.HOST,
		"port": OnlineServer.PORT,
		"scheme": OnlineServer.SCHEME,
		"server_key": OnlineServer.SERVER_KEY,
	},
	"tutorial": {
		"welcomed": false,
		"hints": true,
	},
	"player": {
		"hero": 0,
	},
	"camera": {
		# How fast the camera turns to a new angle and follows a nudge:
		# 0.5 slow, 1.0 normal, 1.6 fast.
		"turn_speed": 1.0,
		# Off: each area sets the angle. On: the camera swings round behind
		# you as you run.
		"follow": false,
		"fov": 65.0,
		"invert_x": false,
		"invert_y": false,
	},
	"play": {
		"always_run": false,
		"ghost": true,
		"split_timer": false,
	},
}

const MENU_MUSIC := "res://assets/kenney/audio/music/wacky_waiting.ogg"

## Every in-game action, with keyboard and controller bindings (see LGInput).
const ACTIONS := {
	"move_left": ["key:A", "axis:lx-"],
	"move_right": ["key:D", "axis:lx+"],
	"move_up": ["key:W", "axis:ly-"],
	"move_down": ["key:S", "axis:ly+"],
	"cam_left": ["key:Left", "axis:rx-"],
	"cam_right": ["key:Right", "axis:rx+"],
	"cam_up": ["key:Up", "axis:ry-"],
	"cam_down": ["key:Down", "axis:ry+"],
	"jump": ["key:Space", "joy:a"],
	"run": ["key:Shift", "joy:x"],
	"crouch": ["key:Ctrl", "key:C", "axis:lt+", "joy:lb"],
	"dive": ["key:F", "mouse:right", "joy:rb", "axis:rt+"],
	"talk": ["key:E", "key:Enter", "joy:y"],
	"recenter": ["key:Q", "mouse:middle", "joy:rs"],
	"restart": ["key:R", "joy:back"],
	"pause": ["key:Escape", "joy:start"],
}


static func version() -> String:
	return LGVersion.current()


static func hero_index() -> int:
	return clampi(int(LGSettings.get_value("player", "hero")), 0, HEROES.size() - 1)


static func hero_name(i := -1) -> String:
	return HEROES[hero_index() if i < 0 else clampi(i, 0, HEROES.size() - 1)][0]


static func hero_scene(i := -1) -> PackedScene:
	var n: String = HEROES[hero_index() if i < 0 else clampi(i, 0, HEROES.size() - 1)][1]
	return load("res://assets/kenney/platformer-kit/%s.glb" % n)
