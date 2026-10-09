class_name Levels
extends RefCounted
## Makes a level by id: islands for Adventure, courses for both modes, and
## boss arenas. Each world's data names the script of each of its levels.


static func make(id: String, mode := "adventure") -> Level:
	var path := Worlds.level_path(id)
	if path == "":
		return null
	var level: Level = load(path).new()
	level.level_id = id
	level.mode = mode
	level.world = Worlds.world_of(id)
	var def := Worlds.get_def(level.world)
	if level.sky.is_empty():
		level.sky = def.get("sky", {})
	if level.block_palette == "":
		level.block_palette = str(def.get("palette", ""))
	if level.music == "":
		level.music = str(def.get("music" if id == def.island else "course_music", ""))
	return level


## Every level id of a world: the island, its courses, then the boss.
static func of_world(world: String) -> Array:
	var def := Worlds.get_def(world)
	var out := []
	for id in [def.get("island", "")] + Courses.of_world(world) + [Worlds.boss_def(world).get("id", "")]:
		if (def.get("levels", {}) as Dictionary).has(id):
			out.append(id)
	return out
