extends RefCounted
## The Star Road: the last stretch of the Skyway, opened by beating King
## Thud. Stardust Plaza, a hub above the clouds at night, with doors to eight
## hard courses that mix every world's kits and tricks, and no boss.

const DEF := {
	"name": "The Star Road",
	"label": "The Star Road",
	"island": "star",
	"music": "res://assets/kenney/audio/music/infinite_descent.ogg",
	"course_music": "res://assets/kenney/audio/music/flowing_rocks.ogg",
	"palette": "res://assets/palettes/star.png",
	"sky": {"top": "#0b0b2e", "horizon": "#7a4fb8", "bottom": "#1a1450", "fog": "#4a3a8a", "fog_density": 0.004, "sun_energy": 1.0, "sun_color": "#fff2d8", "ambient": 0.85},
	"courses": {
		"rainbow_rush": {"name": "Rainbow Rush", "star": "star/rainbow_rush", "gem": "star/gem_rainbow_rush", "medals": [40000, 29000, 23200, 20200]},
		"cannon_crypts": {"name": "Cannon Crypts", "star": "star/cannon_crypts", "gem": "star/gem_cannon_crypts", "medals": [41000, 29500, 23700, 20700]},
		"sugar_gears": {"name": "Sugar Gears", "star": "star/sugar_gears", "gem": "star/gem_sugar_gears", "medals": [56000, 40000, 32300, 28100]},
		"moon_ramparts": {"name": "Moon Ramparts", "star": "star/moon_ramparts", "gem": "star/gem_moon_ramparts", "medals": [41500, 29500, 23800, 20700]},
		"blizzard_bluffs": {"name": "Blizzard Bluffs", "star": "star/blizzard_bluffs", "gem": "star/gem_blizzard_bluffs", "medals": [38500, 27500, 22100, 19300]},
		"haunted_heights": {"name": "Haunted Heights", "star": "star/haunted_heights", "gem": "star/gem_haunted_heights", "medals": [39500, 28000, 22600, 19700]},
		"bounce_hollow": {"name": "Bounce Hollow", "star": "star/bounce_hollow", "gem": "star/gem_bounce_hollow", "medals": [38500, 27500, 22100, 19300]},
	},
	"boss": {},
	"stars": {
		"star/rainbow_rush": "Rainbow Rush",
		"star/cannon_crypts": "Cannon Crypts",
		"star/sugar_gears": "Sugar Gears",
		"star/moon_ramparts": "Moon Ramparts",
		"star/blizzard_bluffs": "Blizzard Bluffs",
		"star/haunted_heights": "Haunted Heights",
		"star/bounce_hollow": "Bounce Hollow",
		"star/silver": "Silver Lap",
		"star/spire": "Top of the Spire",
	},
	"gems": ["star/gem_hub", "star/gem_rainbow_rush", "star/gem_cannon_crypts", "star/gem_sugar_gears", "star/gem_moon_ramparts", "star/gem_blizzard_bluffs", "star/gem_haunted_heights", "star/gem_bounce_hollow"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["star/silver"],
	"levels": {
		"star": "res://game/levels/star/star_plaza.gd",
		"rainbow_rush": "res://game/levels/star/rainbow_rush.gd",
		"cannon_crypts": "res://game/levels/star/cannon_crypts.gd",
		"sugar_gears": "res://game/levels/star/sugar_gears.gd",
		"moon_ramparts": "res://game/levels/star/moon_ramparts.gd",
		"blizzard_bluffs": "res://game/levels/star/blizzard_bluffs.gd",
		"haunted_heights": "res://game/levels/star/haunted_heights.gd",
		"bounce_hollow": "res://game/levels/star/bounce_hollow.gd",
	},
}
