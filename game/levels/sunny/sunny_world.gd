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
	},
	"boss": {"id": "pinch", "name": "Captain Pinch", "star": "sunny/boss", "door": 5},
	"stars": {
		"sunny/sawmill": "Saw Mill Sprint",
		"sunny/chicks": "The Lost Chicks",
		"sunny/silver": "Silver Rush",
		"sunny/tower": "Top of the Old Tower",
		"sunny/ledge": "Under the Ledge",
		"sunny/crates": "The Crabs' Crate",
	},
	"gems": ["sunny/gem_crates", "sunny/gem_far", "sunny/gem_sawmill"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["sunny/chicks", "sunny/silver"],
	"levels": {
		"sunny": "res://game/levels/sunny/sunny_isle.gd",
		"sawmill": "res://game/levels/sunny/saw_mill_sprint.gd",
	},
	# Stars it takes for the Skyway to reach Lookout Islet.
	"skyway": 2,
}
