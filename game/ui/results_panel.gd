class_name ResultsPanel
extends Control
## After a speedrun: the time, the medal it earns, the best time and what to
## aim for next.

var play: Play
var _col: VBoxContainer
var _panel: PanelContainer


func setup(p_play: Play) -> void:
	play = p_play
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
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


func show_result(course_id: String, msec: int, old_best: int, is_best: bool) -> void:
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	var head := LGUi.label(Courses.title(course_id), "HeaderMedium")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(head)
	var time := Hud.text(Courses.time_text(msec), 64, Color("ffd23f"))
	time.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(time)
	var medal := Courses.medal_for(course_id, msec)
	var m := Hud.text("%s medal" % Courses.MEDALS[medal] if medal > 0 else "No medal yet", 28, Courses.MEDAL_COLORS[medal])
	m.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(m)
	var lines := []
	if is_best and old_best > 0:
		lines.append("New best! %s faster than before." % Courses.time_text(old_best - msec))
	elif is_best:
		lines.append("Your first time on this course.")
	else:
		lines.append("Best: %s (%s behind)" % [Courses.time_text(old_best), Courses.time_text(msec - old_best)])
	var next := Courses.next_medal(course_id, Progress.best_time(course_id))
	if not next.is_empty():
		lines.append("Next: %s at %s" % [Courses.MEDALS[next[0]], Courses.time_text(next[1])])
	for line in lines:
		var l := LGUi.label(line, "HintLabel")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_col.add_child(l)
	_col.add_child(LGUi.button("Run it again", _again, 420))
	_col.add_child(LGUi.button("Pick a course", _courses, 420))
	_col.add_child(LGUi.button("Back to the title", _title, 420))
	visible = true
	LGUi.focus_first(_col)


func close() -> void:
	visible = false


func _again() -> void:
	play.restart_run()


func _courses() -> void:
	visible = false
	TitleScreen.start_page = "speedrun"
	play.quit_to_title()


func _title() -> void:
	visible = false
	play.quit_to_title()
