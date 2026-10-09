extends RefCounted
## World 7, Sky Castle: towers, walls and drawbridges above the clouds at
## sunset. The island, its four courses and the Siege Tower's arena.

const DEF := {
	"name": "Sky Castle",
	"island": "castle",
	"music": "res://assets/kenney/audio/music/german_virtue.ogg",
	"course_music": "res://assets/kenney/audio/music/mission_plausible.ogg",
	"palette": "res://assets/palettes/castle.png",
	"sky": {"top": "#4a78d0", "horizon": "#ffd2a3", "bottom": "#f7e3c8", "fog": "#ffe0bd", "fog_density": 0.004, "sun_energy": 1.1, "sun_color": "#ffe0b0", "sun_angle": 38.0, "ambient": 0.9},
	"courses": {
		"ramparts": {"name": "Rampart Run", "star": "castle/ramparts", "gem": "castle/gem_ramparts", "medals": [34000, 24000, 19500, 17000]},
		"drawbridge": {"name": "Drawbridge Dash", "star": "castle/drawbridge", "gem": "castle/gem_drawbridge", "medals": [34000, 24000, 19500, 17000]},
		"spire": {"name": "Spire Climb", "star": "castle/spire", "gem": "castle/gem_spire", "medals": [29500, 21000, 17000, 14500]},
		"siege": {"name": "Siege Gauntlet", "star": "castle/siege", "gem": "castle/gem_siege", "medals": [30000, 21500, 17500, 15000]},
	},
	"boss": {"id": "siege_tower", "name": "The Siege Tower", "star": "castle/boss", "door": 5},
	"stars": {
		"castle/ramparts": "Rampart Run",
		"castle/drawbridge": "Drawbridge Dash",
		"castle/spire": "Spire Climb",
		"castle/siege": "Siege Gauntlet",
		"castle/banners": "Raise the Banners",
		"castle/silver": "Rampart Rush",
		"castle/keep": "Top of the Keep",
		"castle/cloud": "Star on a Cloud",
		"castle/catapult": "Silence the Catapult",
		"castle/boss": "The Siege Tower",
	},
	"gems": ["castle/gem_banner", "castle/gem_ramparts", "castle/gem_drawbridge", "castle/gem_spire", "castle/gem_siege"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["castle/banners", "castle/silver", "castle/catapult"],
	"levels": {
		"castle": "res://game/levels/castle/castle_isle.gd",
		"ramparts": "res://game/levels/castle/rampart_run.gd",
		"drawbridge": "res://game/levels/castle/drawbridge_dash.gd",
		"spire": "res://game/levels/castle/spire_climb.gd",
		"siege": "res://game/levels/castle/siege_gauntlet.gd",
		"siege_tower": "res://game/levels/castle/siege_tower_arena.gd",
	},
}
