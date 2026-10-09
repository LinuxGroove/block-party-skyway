class_name Worlds
extends RefCounted
## The eight worlds of the Sky Isles, in order. Each world's data lives
## beside its levels in game/levels/<world>/<world>_world.gd: its name, the
## island, its courses (with medal times), its boss, every star and hidden
## gem, the music and the sky.
##
## A world opens once the boss of the world before it is beaten (that
## brings its Skyway back); Sunny Isles is open from the start.

const ORDER := ["sunny", "frosty", "pirate", "spooky", "snack", "gears", "castle", "station"]
const DATA := {
	"sunny": preload("res://game/levels/sunny/sunny_world.gd"),
	"frosty": preload("res://game/levels/frosty/frosty_world.gd"),
	"pirate": preload("res://game/levels/pirate/pirate_world.gd"),
	"spooky": preload("res://game/levels/spooky/spooky_world.gd"),
	"snack": preload("res://game/levels/snack/snack_world.gd"),
	"gears": preload("res://game/levels/gears/gears_world.gd"),
	"castle": preload("res://game/levels/castle/castle_world.gd"),
	"station": preload("res://game/levels/station/station_world.gd"),
}


static func get_def(world: String) -> Dictionary:
	return DATA[world].DEF if DATA.has(world) else {}


## Worlds whose island is built, in order.
static func built() -> Array:
	var out := []
	for w in ORDER:
		if is_built(w):
			out.append(w)
	return out


static func is_built(world: String) -> bool:
	var def := get_def(world)
	return not def.is_empty() and (def.levels as Dictionary).has(def.island)


## 1 for Sunny Isles, up to 8.
static func number(world: String) -> int:
	return ORDER.find(world) + 1


static func world_name(world: String) -> String:
	return str(get_def(world).get("name", world))


## The world before or after this one, or "" at either end.
static func neighbour(world: String, step: int) -> String:
	var i := ORDER.find(world) + step
	return ORDER[i] if i >= 0 and i < ORDER.size() else ""


## Which world a level (island, course or boss arena) belongs to.
static func world_of(level_id: String) -> String:
	for w in ORDER:
		if (get_def(w).get("levels", {}) as Dictionary).has(level_id):
			return w
	return ""


## The script path of a level, or "".
static func level_path(level_id: String) -> String:
	var w := world_of(level_id)
	return str(get_def(w).levels[level_id]) if w != "" else ""


static func boss_def(world: String) -> Dictionary:
	return get_def(world).get("boss", {})


## True for a boss arena's level id.
static func is_boss(level_id: String) -> bool:
	var w := world_of(level_id)
	return w != "" and str(boss_def(w).get("id", "")) == level_id


## A world is open once the boss before it is beaten.
static func is_open(world: String) -> bool:
	var before := neighbour(world, -1)
	if before == "":
		return true
	return Progress.has_star(str(boss_def(before).get("star", "")))


static func star_name(id: String) -> String:
	for w in ORDER:
		var stars: Dictionary = get_def(w).get("stars", {})
		if stars.has(id):
			return stars[id]
	return "A star"


static func star_ids(world: String) -> Array:
	return (get_def(world).get("stars", {}) as Dictionary).keys()


static func gem_ids(world: String) -> Array:
	return get_def(world).get("gems", [])


static func total_stars() -> int:
	var n := 0
	for w in ORDER:
		n += star_ids(w).size()
	return n


static func total_gems() -> int:
	var n := 0
	for w in ORDER:
		n += gem_ids(w).size()
	return n
