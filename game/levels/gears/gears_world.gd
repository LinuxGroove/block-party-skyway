extends RefCounted
## World 6, Gear Works: a floating factory of steel decks, conveyor belts,
## fans, pistons and crushers. The island, its four courses and The Big
## Press's arena.

const DEF := {
	"name": "Gear Works",
	"island": "gears",
	"music": "res://assets/kenney/audio/music/time_driving.ogg",
	"course_music": "res://assets/kenney/audio/music/drumming_sticks.ogg",
	"palette": "res://assets/palettes/gears.png",
	"sky": {"top": "#6c7c92", "horizon": "#e0cba6", "bottom": "#8f8a80", "fog": "#d8c7a8", "fog_density": 0.008, "sun_energy": 0.95, "sun_color": "#ffe2b8", "ambient": 0.85},
	"courses": {
		"belt_rush": {"name": "Belt Rush", "star": "gears/belt_rush", "gem": "gears/gem_belt_rush", "medals": [31000, 22000, 17750, 15500]},
		"piston_climb": {"name": "Piston Climb", "star": "gears/piston_climb", "gem": "gears/gem_piston_climb", "medals": [43500, 31000, 25000, 21750]},
		"fan_tower": {"name": "Fan Tower", "star": "gears/fan_tower", "gem": "gears/gem_fan_tower", "medals": [36000, 25500, 20500, 18000]},
		"crusher_row": {"name": "Crusher Row", "star": "gears/crusher_row", "gem": "gears/gem_crusher_row", "medals": [31000, 22000, 17750, 15500]},
	},
	"boss": {"id": "big_press", "name": "The Big Press", "star": "gears/boss", "door": 5},
	"stars": {
		"gears/belt_rush": "Belt Rush",
		"gears/piston_climb": "Piston Climb",
		"gears/fan_tower": "Fan Tower",
		"gears/crusher_row": "Crusher Row",
		"gears/cogs": "Bolt's Lost Cogs",
		"gears/switch": "The Shift Switch",
		"gears/crane": "Top of the Crane Tower",
		"gears/belt": "The End of Belt Seven",
		"gears/scamp": "Catch Scamp",
		"gears/boss": "The Big Press",
	},
	"gems": ["gears/gem_crate", "gears/gem_pipe", "gears/gem_belt_rush", "gears/gem_piston_climb", "gears/gem_fan_tower", "gears/gem_crusher_row"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["gears/cogs", "gears/scamp"],
	"levels": {
		"gears": "res://game/levels/gears/gears_isle.gd",
		"belt_rush": "res://game/levels/gears/belt_rush.gd",
		"piston_climb": "res://game/levels/gears/piston_climb.gd",
		"fan_tower": "res://game/levels/gears/fan_tower.gd",
		"crusher_row": "res://game/levels/gears/crusher_row.gd",
		"big_press": "res://game/levels/gears/press_arena.gd",
	},
}
