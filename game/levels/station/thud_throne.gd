class_name ThudThrone
extends BossArena
## King Thud's throne room, the last fight of the Adventure: a round metal
## deck open to space, with his throne on its own platform behind. Falling
## off comes back at the flag by the door.


func _init() -> void:
	super()
	title = "King Thud's Throne Room"
	spawn = Vector3(0, 0, 8.5)
	spawn_facing = Vector3.FORWARD
	star_spot = Vector3(0, 0.3, 0)
	music = "res://assets/kenney/audio/music/mission_plausible.ogg"
	camera_base = [0.0, 40.0, 13.0, true]


func build() -> void:
	# The round deck, in bands so no blocks overlap.
	land(-11, -7, 11, 7, 0, 3)
	land(-7, -11, 7, -7, 0, 3)
	land(-7, 7, 7, 11, 0, 3)
	for c in [Vector2i(-9, -9), Vector2i(7, -9), Vector2i(-9, 7), Vector2i(7, 7)]:
		land(c.x, c.y, c.x + 2, c.y + 2, 0, 3)
	StationDeco.panels(self, -7, -7, 7, 7, 0.0, "floor-detail")
	_edge_lamps()
	add_checkpoint(Vector3(2.6, 0, 9.2), Vector3.FORWARD)
	for at in [Vector3(8.5, 0, -4), Vector3(-8.5, 0, -4), Vector3(8.5, 0, 4), Vector3(-8.5, 0, 4)]:
		add_heart(at)
	_throne()
	StationDeco.space(self)
	var thud := StationKingThud.new()
	thud.home = Vector3(0, 0, -2)
	thud.reach = 7.5
	add_boss(thud, Vector3(0, 0, -3))
	finish()


## Little lights round the rim, so the edge is easy to see.
func _edge_lamps() -> void:
	var mat := StationDeco.glow(Color("9fe3f0"))
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 0.12, 0.3)
	var spots := []
	for i in 28:
		var a := TAU * i / 28.0
		var p := Vector3(cos(a), 0, sin(a))
		# Out to the deck's edge along this direction.
		var r := 10.6
		for test in range(110, 60, -1):
			var q := p * (test / 10.0)
			if _on_deck(q):
				r = test / 10.0
				break
		spots.append(p * (r - 0.3))
	for at in spots:
		var m := MeshInstance3D.new()
		m.mesh = mesh
		m.material_override = mat
		m.position = at + Vector3.UP * 0.06
		add_child(m)


func _on_deck(q: Vector3) -> bool:
	var ax := absf(q.x)
	var az := absf(q.z)
	return (ax < 11 and az < 7) or (ax < 7 and az < 11) or (ax < 9 and az < 9)


## The throne, on a platform of its own behind the deck, with the station's
## big windows and banners behind it.
func _throne() -> void:
	land(-6, -31, 6, -21, 2, 3)
	StationDeco.wall(self, Vector3(-6, 2, -30.5), Vector3(6, 2, -30.5), Vector3.BACK, ["wall-window-banner", "wall-pillar-banner", "wall-window-banner"], 3.0, false)
	piece("station:chair-armrest-headrest", Vector3(0, 2, -27), 0.0, 5.0)
	for x in [-4.0, 4.0]:
		piece("station:structure-barrier-high", Vector3(x, 2, -24), 0.0, 2.2)
		piece("station:computer-system", Vector3(x, 2, -28), 0.0, 2.0)
	for x in [-19.0, 19.0]:
		land(int(x) - 2, -6, int(x) + 2, 6, -3, 2)
		piece("station:structure", Vector3(x, -3, 0), 0.0, 3.0)
		piece("station:container-tall", Vector3(x, -3, -4), 0.0, 2.0)
		piece("station:container-wide", Vector3(x, -3, 4), 0.0, 2.0)
