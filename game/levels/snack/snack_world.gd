extends RefCounted
## World 5, Snack Valley: giant food, frosting meadows and soda lakes. The
## island, its four courses and the Hungry Hog's pen.

const DEF := {
	"name": "Snack Valley",
	"island": "snack",
	"music": "res://assets/kenney/audio/music/italian_mom.ogg",
	"course_music": "res://assets/kenney/audio/music/wacky_waiting.ogg",
	"palette": "res://assets/palettes/snack.png",
	"sky": {"top": "#ff8fcf", "horizon": "#ffe6f2", "bottom": "#ffc2e2", "fog": "#ffe3f1", "fog_density": 0.004, "sun_energy": 1.05, "ambient": 1.0},
	"courses": {
		"cake_climb": {"name": "Layer Cake Climb", "star": "snack/cake_climb", "gem": "snack/gem_cake_climb", "medals": [29000, 21000, 17000, 14600]},
		"donut_hop": {"name": "Donut Hop", "star": "snack/donut_hop", "gem": "snack/gem_donut_hop", "medals": [30000, 21000, 17000, 14800]},
		"kitchen_dash": {"name": "Kitchen Dash", "star": "snack/kitchen_dash", "gem": "snack/gem_kitchen_dash", "medals": [30000, 21000, 17000, 14900]},
		"fizzy_crossing": {"name": "Fizzy Crossing", "star": "snack/fizzy_crossing", "gem": "snack/gem_fizzy_crossing", "medals": [31000, 22000, 18000, 15500]},
	},
	"boss": {"id": "hungry_hog", "name": "The Hungry Hog", "star": "snack/boss", "door": 5},
	"stars": {
		"snack/cake_climb": "Layer Cake Climb",
		"snack/donut_hop": "Donut Hop",
		"snack/kitchen_dash": "Kitchen Dash",
		"snack/fizzy_crossing": "Fizzy Crossing",
		"snack/cherries": "Coco's Cherries",
		"snack/sprinkles": "Sprinkle Rush",
		"snack/cake_top": "Top of the Wedding Cake",
		"snack/falls": "Behind the Chocolate Falls",
		"snack/runaway": "The Runaway Donut",
		"snack/boss": "The Hungry Hog",
	},
	"gems": ["snack/gem_fizz", "snack/gem_pantry", "snack/gem_cake_climb", "snack/gem_donut_hop", "snack/gem_kitchen_dash", "snack/gem_fizzy_crossing"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["snack/cherries", "snack/sprinkles", "snack/runaway"],
	"levels": {
		"snack": "res://game/levels/snack/snack_valley.gd",
		"cake_climb": "res://game/levels/snack/layer_cake_climb.gd",
		"donut_hop": "res://game/levels/snack/donut_hop.gd",
		"kitchen_dash": "res://game/levels/snack/kitchen_dash.gd",
		"fizzy_crossing": "res://game/levels/snack/fizzy_crossing.gd",
		"hungry_hog": "res://game/levels/snack/hog_pen.gd",
	},
}
