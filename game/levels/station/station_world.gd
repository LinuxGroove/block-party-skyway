extends RefCounted
## World 8, Star Station: King Thud's station above the clouds, in space. The
## station's decks, its four courses and King Thud's throne room, the last
## fight of the Adventure.

const DEF := {
	"name": "Star Station",
	"island": "station",
	"music": "res://assets/kenney/audio/music/space_cadet.ogg",
	"course_music": "res://assets/kenney/audio/music/alpha_dance.ogg",
	"palette": "res://assets/palettes/station.png",
	"sky": {"top": "#04050d", "horizon": "#262a66", "bottom": "#0b0c22", "fog": "#1d2150", "fog_density": 0.004, "sun_energy": 1.0, "sun_color": "#e8f0ff", "ambient": 0.7},
	"courses": {
		"moonhop": {"name": "Moon Hop", "star": "station/moonhop", "gem": "station/gem_moonhop", "medals": [36500, 26000, 21000, 18300]},
		"laserhall": {"name": "Laser Hall", "star": "station/laserhall", "gem": "station/gem_laserhall", "medals": [32000, 23000, 18500, 16100]},
		"ventclimb": {"name": "Vent Climb", "star": "station/ventclimb", "gem": "station/gem_ventclimb", "medals": [29500, 21000, 17000, 14800]},
		"orbitring": {"name": "Orbit Ring", "star": "station/orbitring", "gem": "station/gem_orbitring", "medals": [45000, 32000, 25800, 22400]},
	},
	"boss": {"id": "king_thud", "name": "King Thud", "star": "station/boss", "door": 5},
	"stars": {
		"station/moonhop": "Moon Hop",
		"station/laserhall": "Laser Hall",
		"station/ventclimb": "Vent Climb",
		"station/orbitring": "Orbit Ring",
		"station/fuses": "Sprocket's Fuses",
		"station/dust": "Star Dust Rush",
		"station/mast": "Top of the Comms Mast",
		"station/hangar": "The Hidden Hangar",
		"station/comet": "Catch Comet",
		"station/boss": "King Thud",
	},
	"gems": ["station/gem_crate", "station/gem_asteroid", "station/gem_moonhop", "station/gem_laserhall", "station/gem_ventclimb", "station/gem_orbitring"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["station/fuses", "station/dust", "station/comet"],
	"levels": {
		"station": "res://game/levels/station/station_isle.gd",
		"moonhop": "res://game/levels/station/moon_hop.gd",
		"laserhall": "res://game/levels/station/laser_hall.gd",
		"ventclimb": "res://game/levels/station/vent_climb.gd",
		"orbitring": "res://game/levels/station/orbit_ring.gd",
		"king_thud": "res://game/levels/station/thud_throne.gd",
	},
}
