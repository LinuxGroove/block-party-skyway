extends Node
## What the player has found and done, kept in user://progress.cfg (autoload:
## Progress): stars, hidden gems, coins, the courses Adventure has found
## (Speedrun opens those), best times and medals. Best runs' ghosts are kept
## beside it in user://ghosts/.

signal changed

var path := "user://progress.cfg"
var ghost_dir := "user://ghosts/"
var stars := {}
var gems := {}
var coins := 0
var courses := {}
var best := {}
## Where the hero was on the island when last playing, to carry on there.
var island_spot := {}

var _cfg := ConfigFile.new()


func _ready() -> void:
	load_progress()


## Points the saves somewhere else (tests and screenshots) and loads them.
func use_path(p_path: String, p_ghost_dir: String) -> void:
	path = p_path
	ghost_dir = p_ghost_dir
	load_progress()


func load_progress() -> void:
	_cfg = ConfigFile.new()
	if FileAccess.file_exists(path) and _cfg.load(path) != OK:
		push_warning("Progress: could not read %s" % path)
		_cfg = ConfigFile.new()
	stars = _cfg.get_value("found", "stars", {})
	gems = _cfg.get_value("found", "gems", {})
	coins = int(_cfg.get_value("found", "coins", 0))
	courses = _cfg.get_value("found", "courses", {})
	best = _cfg.get_value("speedrun", "best", {})
	island_spot = _cfg.get_value("adventure", "spot", {})


func save() -> void:
	_cfg.set_value("found", "stars", stars)
	_cfg.set_value("found", "gems", gems)
	_cfg.set_value("found", "coins", coins)
	_cfg.set_value("found", "courses", courses)
	_cfg.set_value("speedrun", "best", best)
	_cfg.set_value("adventure", "spot", island_spot)
	if _cfg.save(path) != OK:
		push_warning("Progress: could not save %s" % path)
	changed.emit()


## Starts Adventure again from nothing. Best times and ghosts stay.
func new_adventure() -> void:
	stars = {}
	gems = {}
	coins = 0
	courses = {}
	island_spot = {}
	save()


func has_started() -> bool:
	return not stars.is_empty() or not courses.is_empty() or coins > 0 or not island_spot.is_empty()


func has_star(id: String) -> bool:
	return stars.has(id)


## Returns true if the star is new.
func add_star(id: String) -> bool:
	if stars.has(id):
		return false
	stars[id] = true
	save()
	return true


func star_count(world := "") -> int:
	if world == "":
		return stars.size()
	var n := 0
	for id in Worlds.star_ids(world):
		if stars.has(id):
			n += 1
	return n


func has_gem(id: String) -> bool:
	return gems.has(id)


func add_gem(id: String) -> bool:
	if gems.has(id):
		return false
	gems[id] = true
	save()
	return true


func add_coins(n: int) -> void:
	coins += n


func find_course(id: String) -> void:
	if not courses.has(id):
		courses[id] = true
		save()


func course_found(id: String) -> bool:
	return courses.has(id)


## Best time in milliseconds, or 0 for none.
func best_time(id: String) -> int:
	return int(best.get(id, 0))


## Keeps the time if it's the best so far, with its ghost. Returns true for
## a new best.
func record_time(id: String, msec: int, ghost: Ghost = null) -> bool:
	var old := best_time(id)
	if old > 0 and msec >= old:
		return false
	best[id] = msec
	save()
	if ghost:
		save_ghost(id, ghost)
	return true


func save_ghost(id: String, ghost: Ghost) -> void:
	DirAccess.make_dir_recursive_absolute(ghost_dir)
	var f := FileAccess.open(ghost_dir.path_join(id + ".ghost"), FileAccess.WRITE)
	if f == null:
		push_warning("Progress: could not save the ghost for %s" % id)
		return
	f.store_buffer(ghost.to_bytes())


func load_ghost(id: String) -> Ghost:
	var p := ghost_dir.path_join(id + ".ghost")
	if not FileAccess.file_exists(p):
		return null
	return Ghost.from_bytes(FileAccess.get_file_as_bytes(p))


## Forgets everything, ghosts included (tests and screenshots).
func wipe() -> void:
	new_adventure()
	best = {}
	save()
	var d := DirAccess.open(ghost_dir)
	if d:
		for f in d.get_files():
			d.remove(f)
