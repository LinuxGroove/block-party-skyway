extends RefCounted
## World 3, Pirate Cove: sandy islands in a sunny cove, docks, ships and
## cannons, with the sea between the islands. The island, its four courses
## and Polly's ship.

const DEF := {
	"name": "Pirate Cove",
	"island": "pirate",
	"music": "res://assets/kenney/audio/music/night_at_the_beach.ogg",
	"course_music": "res://assets/kenney/audio/music/retro_reggae.ogg",
	"palette": "res://assets/palettes/pirate.png",
	"sky": {"top": "#2f9be0", "horizon": "#fff0c4", "bottom": "#7cc6f0", "fog": "#fff3d6", "fog_density": 0.003, "sun_energy": 1.15, "ambient": 0.95},
	"courses": {
		"dockdash": {"name": "Dock Dash", "star": "pirate/dockdash", "gem": "pirate/gem_dockdash", "medals": [32500, 23000, 18700, 16200]},
		"cannoncove": {"name": "Cannon Cove", "star": "pirate/cannoncove", "gem": "pirate/gem_cannoncove", "medals": [30600, 21800, 17600, 15300]},
		"wreckclimb": {"name": "Shipwreck Climb", "star": "pirate/wreckclimb", "gem": "pirate/gem_wreckclimb", "medals": [34000, 24100, 19500, 17000]},
		"riggingrun": {"name": "Rigging Run", "star": "pirate/riggingrun", "gem": "pirate/gem_riggingrun", "medals": [32300, 23000, 18500, 16200]},
	},
	"boss": {"id": "polly", "name": "Polly", "star": "pirate/boss", "door": 5},
	"stars": {
		"pirate/dockdash": "Dock Dash",
		"pirate/cannoncove": "Cannon Cove",
		"pirate/wreckclimb": "Shipwreck Climb",
		"pirate/riggingrun": "Rigging Run",
		"pirate/rascal": "Catch That Fox",
		"pirate/silver": "Silver on the Docks",
		"pirate/lookout": "Top of the Lookout",
		"pirate/skull": "Skull Rock",
		"pirate/treasure": "X Marks the Spot",
		"pirate/boss": "Polly's Ship",
	},
	"gems": ["pirate/gem_barrel", "pirate/gem_wreck", "pirate/gem_dockdash", "pirate/gem_cannoncove", "pirate/gem_wreckclimb", "pirate/gem_riggingrun"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["pirate/rascal", "pirate/silver", "pirate/treasure"],
	"levels": {
		"pirate": "res://game/levels/pirate/pirate_cove.gd",
		"dockdash": "res://game/levels/pirate/dock_dash.gd",
		"cannoncove": "res://game/levels/pirate/cannon_cove.gd",
		"wreckclimb": "res://game/levels/pirate/wreck_climb.gd",
		"riggingrun": "res://game/levels/pirate/rigging_run.gd",
		"polly": "res://game/levels/pirate/polly_ship.gd",
	},
}
