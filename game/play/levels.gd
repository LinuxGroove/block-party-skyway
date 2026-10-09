class_name Levels
extends RefCounted
## Makes a level by id: islands for Adventure, courses for both modes.


static func make(id: String, mode := "adventure") -> Level:
	var level: Level = null
	match id:
		"sunny":
			level = SunnyIsle.new()
		"sawmill":
			level = SawMillSprint.new()
	if level:
		level.level_id = id
		level.mode = mode
	return level
