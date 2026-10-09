extends RefCounted
## World 4, Spooky Hollow: crypts, pumpkins, ghosts and skeletons, at dusk.
## The island, its four courses and the Night Keeper's graveyard.

const DEF := {
	"name": "Spooky Hollow",
	"island": "spooky",
	"music": "res://assets/kenney/audio/music/mishief_stroll.ogg",
	"course_music": "res://assets/kenney/audio/music/retro_mystic.ogg",
	"palette": "res://assets/palettes/spooky.png",
	"sky": {"top": "#1d1538", "horizon": "#6b4a8a", "bottom": "#2b2147", "fog": "#5b4778", "fog_density": 0.012, "sun_energy": 0.55, "sun_color": "#c9b8ff", "ambient": 0.75},
	"courses": {
		"crypt_creep": {"name": "Crypt Creep", "star": "spooky/crypt_creep", "gem": "spooky/gem_crypt_creep", "medals": [31000, 22000, 17500, 15500]},
		"ghost_bridge": {"name": "Ghost Bridge", "star": "spooky/ghost_bridge", "gem": "spooky/gem_ghost_bridge", "medals": [29500, 21000, 17000, 14500]},
		"pumpkin_patch": {"name": "Pumpkin Patch", "star": "spooky/pumpkin_patch", "gem": "spooky/gem_pumpkin_patch", "medals": [29000, 20500, 16500, 14500]},
		"haunted_tower": {"name": "Haunted Tower", "star": "spooky/haunted_tower", "gem": "spooky/gem_haunted_tower", "medals": [30000, 21000, 17000, 15000]},
	},
	"boss": {"id": "night_keeper", "name": "The Night Keeper", "star": "spooky/boss", "door": 5},
	"stars": {
		"spooky/crypt_creep": "Crypt Creep",
		"spooky/ghost_bridge": "Ghost Bridge",
		"spooky/pumpkin_patch": "Pumpkin Patch",
		"spooky/haunted_tower": "Haunted Tower",
		"spooky/lanterns": "Light the Lanterns",
		"spooky/silver": "Silver in the Graves",
		"spooky/ghosts": "The Chapel Ghosts",
		"spooky/tower": "Top of the Bell Tower",
		"spooky/lost_grave": "The Lost Grave",
		"spooky/boss": "The Night Keeper",
	},
	"gems": ["spooky/gem_swamp", "spooky/gem_knoll", "spooky/gem_crypt_creep", "spooky/gem_ghost_bridge", "spooky/gem_pumpkin_patch", "spooky/gem_haunted_tower"],
	## Stars a level hands out when something is done, rather than placing.
	"given": ["spooky/lanterns", "spooky/silver", "spooky/ghosts"],
	"levels": {
		"spooky": "res://game/levels/spooky/spooky_hollow.gd",
		"crypt_creep": "res://game/levels/spooky/crypt_creep.gd",
		"ghost_bridge": "res://game/levels/spooky/ghost_bridge.gd",
		"pumpkin_patch": "res://game/levels/spooky/pumpkin_patch.gd",
		"haunted_tower": "res://game/levels/spooky/haunted_tower.gd",
		"night_keeper": "res://game/levels/spooky/keeper_arena.gd",
	},
}
