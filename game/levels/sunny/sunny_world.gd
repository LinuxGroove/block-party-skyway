extends RefCounted
## World 1, Sunny Isles: grass, meadows and grumpy crabs. The island, its
## four courses and Captain Pinch's arena.

const DEF := {
	"name": "Sunny Isles",
	"island": "sunny",
	"music": "res://assets/kenney/audio/music/farm_frolics.ogg",
	"course_music": "res://assets/kenney/audio/music/swinging_pants.ogg",
	"palette": "",
	"sky": {},
	"courses": {
		"sawmill": {"name": "Saw Mill Sprint", "star": "sunny/sawmill", "gem": "sunny/gem_sawmill", "medals": [25000, 18000, 14500, 12600]},
		"crabshore": {"name": "Crab Shore Dash", "star": "sunny/crabshore", "gem": "sunny/gem_crabshore", "medals": [34000, 24000, 19500, 17000]},
		"windmill": {"name": "Windmill Hills", "star": "sunny/windmill", "gem": "sunny/gem_windmill", "medals": [34500, 24500, 20000, 17200]},
		"treetop": {"name": "Treetop Hop", "star": "sunny/treetop", "gem": "sunny/gem_treetop", "medals": [29000, 20500, 16500, 14500]},
	},
	"boss": {"id": "pinch", "name": "Captain Pinch", "star": "sunny/boss", "door": 5},
	"stars": {
		"sunny/sawmill": "Saw Mill Sprint",
		"sunny/crabshore": "Crab Shore Dash",
		"sunny/windmill": "Windmill Hills",
		"sunny/treetop": "Treetop Hop",
		"sunny/chicks": "The Lost Chicks",
		"sunny/silver": "Silver Rush",
		"sunny/tower": "Top of the Old Tower",
		"sunny/ledge": "Under the Ledge",
		"sunny/crates": "The Crabs' Crate",
		"sunny/boss": "Captain Pinch",
	},
	"gems": ["sunny/gem_crates", "sunny/gem_far", "sunny/gem_sawmill", "sunny/gem_crabshore", "sunny/gem_windmill", "sunny/gem_treetop"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["sunny/chicks", "sunny/silver"],
	"levels": {
		"sunny": "res://game/levels/sunny/sunny_isle.gd",
		"sawmill": "res://game/levels/sunny/saw_mill_sprint.gd",
		"crabshore": "res://game/levels/sunny/crab_shore_dash.gd",
		"windmill": "res://game/levels/sunny/windmill_hills.gd",
		"treetop": "res://game/levels/sunny/treetop_hop.gd",
		"pinch": "res://game/levels/sunny/pinch_arena.gd",
	},
	# Stars it takes for the Skyway to reach Lookout Islet.
	"skyway": 2,
}
