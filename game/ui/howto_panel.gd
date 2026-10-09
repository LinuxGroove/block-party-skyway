class_name HowToPanel
extends Control
## How to play: a few pages on the two modes, the moves and the camera.
## Opened from the title and pause menus.

signal closed

## [actions..., what they do], shown with the current device's buttons.
const MOVES := [
	[["move_up"], "Walk. Hold Run to run"],
	[["jump"], "Jump, and jump again in the air"],
	[["crouch", "jump"], "High jump: crouch, then jump"],
	[["run", "crouch", "jump"], "Long jump: crouch while running, then jump"],
	[["dive"], "Dive: in the air, or from a run"],
	[["crouch"], "Ground pound: crouch in the air"],
	[["jump"], "Wall jump: jump at a wall, then jump again"],
	[["talk"], "Talk, read signs, go through doors"],
]
const CAMERA := [
	[["cam_left"], "Nudge the camera; it eases back when you let go"],
	[["recenter"], "Put the camera back"],
	[["restart"], "Speedrun: start again"],
	[["pause"], "Pause, and the camera settings"],
]

var _title: Label
var _body: Label
var _extra: VBoxContainer
var _count: Label
var _prev: Button
var _next: Button
var _page := 0


static func pages() -> Array:
	return [
		{"title": "The Sky Isles", "body":
			"King Thud has pulled the stars out of the sky and hidden them all over the islands. Without them, the Skyway's rainbow bridges have faded away.\n\nEvery star you find brings a piece of the Skyway back, and the map grows from there."},
		{"title": "Adventure", "body":
			"Roam the islands and look everywhere. Stars hide at the end of course doors, on the hardest ledges to reach, in crates, and with islanders who need a hand. Hidden gems are tucked away too.\n\nFall off and you're back at the last flag, with nothing lost."},
		{"title": "The worlds", "body":
			"Eight worlds lie along the Skyway, from Sunny Isles to King Thud's Star Station. Each has an island to explore, four course doors and a boss.\n\nFind five of a world's stars and its boss's door opens. Beat the boss and the Skyway to the next world comes back. The rainbow gates on each island lead along it, and the pause menu takes you to any world you've opened."},
		{"title": "Speedrun", "body":
			"Every course you find in Adventure opens in Speedrun. Run it against the clock for bronze, silver and gold medals, and race your best run's ghost.\n\nStart again any time with one button."},
		{"title": "Moves", "body": "", "rows": MOVES},
		{"title": "The camera", "body":
			"The camera sits behind you and each area sets its angle, turning slowly where the way turns. A dark disc under you shows where you'll land.\n\nIn the pause menu: camera turn speed, a camera that follows behind you, and the field of view.", "rows": CAMERA},
	]


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "ParchmentPanel"
	panel.custom_minimum_size = Vector2(780, 520)
	center.add_child(panel)
	LGScreenFit.center(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	_title = LGUi.label("", "InkTitle")
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_body = LGUi.label("", "InkLabel")
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size.x = 720
	col.add_child(_body)
	_extra = VBoxContainer.new()
	_extra.add_theme_constant_override("separation", 6)
	_extra.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_extra)
	_count = LGUi.label("", "InkLabel")
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_count)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	col.add_child(row)
	_prev = LGUi.button("Previous", _go.bind(-1), 200)
	row.add_child(_prev)
	_next = LGUi.button("Next", _go.bind(1), 200)
	row.add_child(_next)


func open() -> void:
	_page = 0
	visible = true
	_show_page()
	_next.grab_focus.call_deferred()


func close() -> void:
	if visible:
		visible = false
		closed.emit()


func _go(dir: int) -> void:
	_page += dir
	if _page >= pages().size():
		close()
		return
	_page = maxi(_page, 0)
	_show_page()
	(_prev if dir < 0 and _prev.visible else _next).grab_focus.call_deferred()


func _show_page() -> void:
	var all := pages()
	var page: Dictionary = all[_page]
	_title.text = page.title
	_body.text = page.body
	_body.visible = page.body != ""
	for c in _extra.get_children():
		_extra.remove_child(c)
		c.queue_free()
	var rows: Array = page.get("rows", [])
	_extra.visible = not rows.is_empty()
	for r in rows:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		for action in r[0]:
			line.add_child(Hud.key_cap(action))
		var l := LGUi.label(r[1], "InkLabel")
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		line.add_child(l)
		_extra.add_child(line)
	_count.text = "%d / %d" % [_page + 1, all.size()]
	_prev.visible = _page > 0
	_next.text = "Done" if _page == all.size() - 1 else "Next"


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
