class_name Courses
extends RefCounted
## The courses: compact obstacle runs behind doors on the islands. Each is a
## star in Adventure and a time trial in Speedrun.

## Medal times in milliseconds: bronze, silver, gold and Patrol (the hidden
## one, the developers' own best). Each world lists its own courses; all()
## gathers them, with "world" added, in world order.
static var _list := {}
const MEDALS := ["", "Bronze", "Silver", "Gold", "Patrol"]
const MEDAL_COLORS := [Color.WHITE, Color("d68a4c"), Color("c9d3dd"), Color("ffd23f"), Color("7fd6ff")]


static func all() -> Dictionary:
	if _list.is_empty():
		for w in Worlds.ORDER:
			var courses: Dictionary = Worlds.get_def(w).get("courses", {})
			for id in courses:
				var def: Dictionary = (courses[id] as Dictionary).duplicate()
				def.world = w
				_list[id] = def
	return _list


static func ids() -> Array:
	return all().keys()


static func has(id: String) -> bool:
	return all().has(id)


static func get_def(id: String) -> Dictionary:
	return all().get(id, {})


## The courses of one world, in door order.
static func of_world(world: String) -> Array:
	return (Worlds.get_def(world).get("courses", {}) as Dictionary).keys()


static func title(id: String) -> String:
	return str(get_def(id).get("name", id))


## 0 for none, then 1 bronze, 2 silver, 3 gold, 4 Patrol.
static func medal_for(id: String, msec: int) -> int:
	if msec <= 0:
		return 0
	var times: Array = get_def(id).get("medals", [])
	var best := 0
	for i in times.size():
		if msec <= int(times[i]):
			best = i + 1
	return best


## The next medal to aim for after `msec` (0 if none yet), as [medal, time].
## Patrol only shows up as the next one once gold is won.
static func next_medal(id: String, msec: int) -> Array:
	var have := medal_for(id, msec)
	var times: Array = get_def(id).get("medals", [])
	if have >= times.size():
		return []
	return [have + 1, int(times[have])]


## 1:02.35, or 42.35 under a minute.
static func time_text(msec: int) -> String:
	if msec < 0:
		return "--"
	var cs := int(msec / 10.0)
	var s := cs / 100
	var m := s / 60
	if m > 0:
		return "%d:%02d.%02d" % [m, s % 60, cs % 100]
	return "%d.%02d" % [s, cs % 100]
