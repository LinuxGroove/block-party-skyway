class_name PauseMenu
extends Control
## The pause menu. The game stops while it's open. The camera's comfort
## settings are here as well as on the title screen, so they can be changed
## the moment they're needed.

const TURN_SPEEDS := [[0.5, "Slow"], [1.0, "Normal"], [1.6, "Fast"]]
const FOVS := [[55.0, "Narrow"], [65.0, "Normal"], [78.0, "Wide"]]

var play: Play
var _col: VBoxContainer
var _panel: PanelContainer


func setup(p_play: Play) -> void:
	play = p_play
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.12, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.theme_type_variation = "DarkPanel"
	center.add_child(_panel)
	LGScreenFit.center(_panel)
	_col = VBoxContainer.new()
	_col.add_theme_constant_override("separation", 10)
	_panel.add_child(_col)
	_build()


func _build() -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	_col.add_child(LGUi.label("Paused", "HeaderMedium"))
	_col.add_child(LGUi.button("Carry on", close, 460))
	if play.is_speedrun():
		_col.add_child(LGUi.button("Start again", _restart, 460))
		_col.add_child(LGCycler.make("Best run's ghost", SettingsPanel.ON_OFF, LGSettings.get_value("play", "ghost"), _set_value.bind("play", "ghost"), 460))
	elif play.is_course() or play.is_boss():
		_col.add_child(LGUi.button("Back to the last flag", _to_flag, 460))
		_col.add_child(LGUi.button("Leave the arena" if play.is_boss() else "Leave the course", _leave_course, 460))
	else:
		_col.add_child(LGUi.button("Back to the last flag", _to_flag, 460))
	add_comfort(_col, 460)
	_col.add_child(LGUi.button("How to play", _howto, 460))
	var quit := LGUi.button("Back to the title", _quit, 460)
	quit.theme_type_variation = "DangerButton"
	_col.add_child(quit)


## The settings that keep the view calm: camera turn speed, the chase
## option, field of view, and the run button.
static func add_comfort(col: Container, width := 460) -> void:
	col.add_child(LGCycler.make("Camera turn speed", TURN_SPEEDS, LGSettings.get_value("camera", "turn_speed"), PauseMenu._set_value.bind("camera", "turn_speed"), width))
	col.add_child(LGCycler.make("Camera follows behind me", SettingsPanel.ON_OFF, LGSettings.get_value("camera", "follow"), PauseMenu._set_value.bind("camera", "follow"), width))
	col.add_child(LGCycler.make("Field of view", FOVS, LGSettings.get_value("camera", "fov"), PauseMenu._set_value.bind("camera", "fov"), width))
	col.add_child(LGCycler.make("Always run", SettingsPanel.ON_OFF, LGSettings.get_value("play", "always_run"), PauseMenu._set_value.bind("play", "always_run"), width))


static func _set_value(value: Variant, section: String, key: String) -> void:
	LGSettings.set_value(section, key, value)


func open() -> void:
	if visible:
		return
	_build()
	visible = true
	_panel.visible = true
	get_tree().paused = true
	LGUi.focus_first(_col)


func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	var f := get_viewport().gui_get_focus_owner()
	if f:
		f.release_focus()


func _restart() -> void:
	close()
	play.restart_run()


func _to_flag() -> void:
	close()
	play.respawn()


func _leave_course() -> void:
	close()
	play.back_to_island()


func _quit() -> void:
	visible = false
	play.quit_to_title()


func _howto() -> void:
	_panel.visible = false
	var h := HowToPanel.new()
	add_child(h)
	h.closed.connect(_back_from_howto.bind(h))
	h.open()


func _back_from_howto(h: HowToPanel) -> void:
	h.queue_free()
	if visible:
		_panel.visible = true
		LGUi.focus_first(_col)


func _unhandled_input(event: InputEvent) -> void:
	if visible and _panel.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
		get_viewport().set_input_as_handled()
		close()
