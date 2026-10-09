class_name Worlds
extends RefCounted
## The worlds of the Sky Isles and what's hidden in them. Only Sunny Isles
## so far.

const LIST := {
	"sunny": {
		"name": "Sunny Isles",
		"island": "sunny",
		"stars": {
			"sunny/sawmill": "Saw Mill Sprint",
			"sunny/chicks": "The Lost Chicks",
			"sunny/silver": "Silver Rush",
			"sunny/tower": "Top of the Old Tower",
			"sunny/ledge": "Under the Ledge",
			"sunny/crates": "The Crabs' Crate",
		},
		"gems": ["sunny/gem_crates", "sunny/gem_far", "sunny/gem_sawmill"],
		# Stars it takes for the Skyway to reach Lookout Islet.
		"skyway": 2,
	},
}


static func get_def(world: String) -> Dictionary:
	return LIST.get(world, {})


static func star_name(id: String) -> String:
	for w in LIST:
		if LIST[w].stars.has(id):
			return LIST[w].stars[id]
	return "A star"


static func star_ids(world: String) -> Array:
	return (get_def(world).get("stars", {}) as Dictionary).keys()


static func gem_ids(world: String) -> Array:
	return get_def(world).get("gems", [])


static func total_stars() -> int:
	var n := 0
	for w in LIST:
		n += LIST[w].stars.size()
	return n


static func total_gems() -> int:
	var n := 0
	for w in LIST:
		n += LIST[w].gems.size()
	return n
