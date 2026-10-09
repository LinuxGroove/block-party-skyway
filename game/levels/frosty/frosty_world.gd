extends RefCounted
## World 2, Frosty Peaks: snow, ice, cabins and presents. The island, its
## four courses and The Big Chill's arena.

const DEF := {
	"name": "Frosty Peaks",
	"island": "frosty",
	"music": "res://assets/kenney/audio/music/cheerful_annoyance.ogg",
	"course_music": "res://assets/kenney/audio/music/polka_train.ogg",
	"palette": "res://assets/palettes/frosty.png",
	"sky": {"top": "#5b97d6", "horizon": "#e2effc", "bottom": "#b9d6f2", "fog": "#dde9f7", "fog_density": 0.0045, "sun_energy": 1.0, "ambient": 0.72, "sun_color": "#fff6e8"},
	"courses": {
		"icerink": {"name": "Ice Rink Rush", "star": "frosty/icerink", "gem": "frosty/gem_icerink", "medals": [37000, 26000, 21000, 18300]},
		"chimneys": {"name": "Chimney Hop", "star": "frosty/chimneys", "gem": "frosty/gem_chimneys", "medals": [32000, 23000, 18500, 16000]},
		"toytrain": {"name": "Toy Train Express", "star": "frosty/toytrain", "gem": "frosty/gem_toytrain", "medals": [43000, 30500, 24500, 21400]},
		"giftstack": {"name": "Gift Stack Climb", "star": "frosty/giftstack", "gem": "frosty/gem_giftstack", "medals": [30500, 21500, 17500, 15200]},
	},
	"boss": {"id": "big_chill", "name": "The Big Chill", "star": "frosty/boss", "door": 5},
	"stars": {
		"frosty/icerink": "Ice Rink Rush",
		"frosty/chimneys": "Chimney Hop",
		"frosty/toytrain": "Toy Train Express",
		"frosty/giftstack": "Gift Stack Climb",
		"frosty/presents": "Dasher's Presents",
		"frosty/silver": "Silver on the Ice",
		"frosty/peak": "Top of Frosty Peak",
		"frosty/curtain": "Behind the Ice Curtain",
		"frosty/pingo": "Catch Pingo",
		"frosty/boss": "The Big Chill",
	},
	"gems": ["frosty/gem_present", "frosty/gem_floe", "frosty/gem_icerink", "frosty/gem_chimneys", "frosty/gem_toytrain", "frosty/gem_giftstack"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["frosty/presents", "frosty/silver", "frosty/pingo"],
	"levels": {
		"frosty": "res://game/levels/frosty/frosty_peaks.gd",
		"icerink": "res://game/levels/frosty/ice_rink_rush.gd",
		"chimneys": "res://game/levels/frosty/chimney_hop.gd",
		"toytrain": "res://game/levels/frosty/toy_train_express.gd",
		"giftstack": "res://game/levels/frosty/gift_stack_climb.gd",
		"big_chill": "res://game/levels/frosty/big_chill_arena.gd",
	},
}
