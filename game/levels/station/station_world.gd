extends RefCounted
## World 8, Star Station: King Thud's station above the clouds, in space. Not built yet.

const DEF := {
	"name": "Star Station",
	"island": "station",
	"music": "res://assets/kenney/audio/music/space_cadet.ogg",
	"course_music": "res://assets/kenney/audio/music/alpha_dance.ogg",
	"palette": "res://assets/palettes/station.png",
	"sky": {"top": "#04050d", "horizon": "#262a66", "bottom": "#0b0c22", "fog": "#1d2150", "fog_density": 0.004, "sun_energy": 1.0, "sun_color": "#e8f0ff", "ambient": 0.7},
	"courses": {},
	"boss": {"id": "king_thud", "name": "King Thud", "star": "station/boss", "door": 5},
	"stars": {},
	"gems": [],
	"given": [],
	"levels": {},
}
