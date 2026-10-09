class_name TitleScreen
extends Node
## The title screen: Adventure (carry on, or start again), Speedrun (the
## courses Adventure has found), which astronaut to play, how to play,
## settings, about and quit.

const TITLE_COLOR := Color("ffd23f")

## The page to open on arrival ("speedrun" after a run's results).
static var start_page := ""
## Shown once when arriving here.
static var message := ""

var backdrop: MenuBackdrop
var _ui: Control
var _col: VBoxContainer
var _status: Label
var _about_scroll: ScrollContainer
var _leaving := false


func _ready() -> void:
	backdrop = MenuBackdrop.new()
	add_child(backdrop)
	var layer := CanvasLayer.new()
	add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(_ui)
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.06, 0.16, 0.25)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(shade)
	var version := LGUi.label("v%s" % GameConfig.version(), "HintLabel")
	_ui.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
	_col = LGUi.centered_column(_ui, 560)
	LGScreenFit.center(_col)
	LGAudio.play_music(GameConfig.MENU_MUSIC, -8.0)
	var page := start_page
	start_page = ""
	if page == "speedrun":
		_show_speedrun()
	elif not bool(LGSettings.get_value("tutorial", "welcomed", false)):
		_show_welcome()
	else:
		_show_main()


func _clear() -> void:
	# Detach before freeing, so focus_first can't grab a button on its way out.
	for c in _col.get_children():
		_col.remove_child(c)
		c.queue_free()
	_about_scroll = null
	_status = null


func _add_title() -> void:
	var title := LGUi.label("Block Party", "HeaderLarge")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_font_override("font", load("res://assets/kenney/fonts/Kenney Blocks.ttf"))
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", Color("1d2a55"))
	_col.add_child(title)
	var sub := LGUi.label("Skyway", "HeaderLarge")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color("7fd6ff"))
	sub.add_theme_constant_override("outline_size", 10)
	sub.add_theme_color_override("font_outline_color", Color("1d2a55"))
	_col.add_child(sub)
	var tag := LGUi.label("Explore every island. Then race through it.", "HintLabel")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(tag)


func _add_status(text := "") -> void:
	_status = LGUi.label(text, "HintLabel")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_col.add_child(_status)


func _show_main() -> void:
	_clear()
	_add_title()
	if Progress.has_started():
		_col.add_child(LGUi.button("Adventure: carry on (%s)" % _stars_text(Progress.star_count()), _carry_on))
		_col.add_child(LGUi.button("Speedrun", _show_speedrun))
		_col.add_child(LGUi.button("Start the adventure again", _confirm_new))
	else:
		_col.add_child(LGUi.button("Adventure", _new_adventure))
		_col.add_child(LGUi.button("Speedrun", _show_speedrun))
	_col.add_child(_hero_row())
	_col.add_child(LGUi.button("How to play", _show_howto))
	_col.add_child(LGUi.button("Settings", _show_settings))
	_col.add_child(LGUi.button("About", _show_about))
	var quit := LGUi.button("Quit", _quit)
	quit.theme_type_variation = "DangerButton"
	_col.add_child(quit)
	_add_status(message)
	message = ""
	LGUi.focus_first(_col)


static func _stars_text(n: int) -> String:
	return "1 star" if n == 1 else "%d stars" % n


func _hero_row() -> LGCycler:
	var options := []
	for i in GameConfig.HEROES.size():
		options.append([i, GameConfig.HEROES[i][0]])
	return LGCycler.make("Astronaut", options, GameConfig.hero_index(), _set_hero, 520)


func _set_hero(i: Variant) -> void:
	LGSettings.set_value("player", "hero", int(i))
	backdrop.show_hero(int(i))


func _quit() -> void:
	get_tree().quit()


## Shown the first time the game starts.
func _show_welcome() -> void:
	LGSettings.set_value("tutorial", "welcomed", true)
	_clear()
	_add_title()
	var l := LGUi.label("New here? The signs on the first island show you the moves. How to play has them all on one page.", "HintLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(l)
	_col.add_child(LGUi.button("Start the adventure", _new_adventure))
	_col.add_child(LGUi.button("How to play", _show_howto))
	_col.add_child(_hero_row())
	_col.add_child(LGUi.button("Not now", _show_main))
	LGUi.focus_first(_col)


func _show_howto() -> void:
	_col.visible = false
	var panel := HowToPanel.new()
	_ui.add_child(panel)
	panel.closed.connect(_on_howto_closed.bind(panel))
	panel.open()


func _on_howto_closed(panel: HowToPanel) -> void:
	panel.queue_free()
	_col.visible = true
	_show_main()


# --- Adventure ---------------------------------------------------------------

func _carry_on() -> void:
	if _leaving or LGScenes.is_busy():
		return
	_leaving = true
	var spot := Progress.island_spot
	if spot.has("position"):
		Play.open(str(spot.get("level", "sunny")), "adventure", {"position": spot.position, "facing": spot.get("facing", Vector3.FORWARD)})
	else:
		Play.open("sunny", "adventure")


func _new_adventure() -> void:
	if _leaving or LGScenes.is_busy():
		return
	_leaving = true
	Progress.new_adventure()
	Play.open("sunny", "adventure")


func _confirm_new() -> void:
	_clear()
	_col.add_child(LGUi.label("Start again?", "HeaderMedium"))
	var l := LGUi.label("Your stars, gems and coins go back to none. Your best times and ghosts stay.", "HintLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(l)
	_col.add_child(LGUi.button("Keep my adventure", _show_main))
	var go := LGUi.button("Start again", _new_adventure)
	go.theme_type_variation = "DangerButton"
	_col.add_child(go)
	LGUi.focus_first(_col)


# --- Speedrun ----------------------------------------------------------------

func _show_speedrun() -> void:
	_clear()
	_col.add_child(LGUi.label("Speedrun", "HeaderMedium"))
	var l := LGUi.label("Courses open here once Adventure has found their doors.", "HintLabel")
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_col.add_child(l)
	for id in Courses.ids():
		_col.add_child(_course_button(id))
	_col.add_child(LGUi.button("Back", _show_main))
	LGUi.focus_first(_col)


func _course_button(id: String) -> Button:
	if not Progress.course_found(id):
		var locked := LGUi.button("???  (find its door in Adventure)", _show_speedrun, 520)
		locked.disabled = true
		return locked
	var best := Progress.best_time(id)
	var medal := Courses.medal_for(id, best)
	var text := Courses.title(id)
	if best > 0:
		text += "   %s" % Courses.time_text(best)
		if medal > 0:
			text += "  %s" % Courses.MEDALS[medal]
	return LGUi.button(text, _start_course.bind(id), 520)


func _start_course(id: String) -> void:
	if _leaving or LGScenes.is_busy():
		return
	_leaving = true
	Play.open(id, "speedrun")


# --- Settings and about ------------------------------------------------------

func _show_settings() -> void:
	_clear()
	_col.add_child(LGUi.label("Settings", "HeaderMedium"))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.custom_minimum_size = Vector2(560, 470)
	_col.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)
	PauseMenu.add_comfort(rows, 520)
	for row in [["Invert camera left and right", "camera", "invert_x"], ["Invert camera up and down", "camera", "invert_y"]]:
		rows.add_child(LGCycler.make(row[0], SettingsPanel.ON_OFF, LGSettings.get_value(row[1], row[2]), PauseMenu._set_value.bind(row[1], row[2]), 520))
	rows.add_child(LGCycler.make("Best run's ghost", SettingsPanel.ON_OFF, LGSettings.get_value("play", "ghost"), PauseMenu._set_value.bind("play", "ghost"), 520))
	var panel := SettingsPanel.new()
	rows.add_child(panel)
	_col.add_child(LGUi.button("Back", _show_main))
	LGUi.focus_first(_col)


## Credits. Up and down scroll the page, since Back is the only button.
func _show_about() -> void:
	_clear()
	_col.add_child(LGUi.label("About", "HeaderMedium"))
	_about_scroll = ScrollContainer.new()
	_about_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_about_scroll.custom_minimum_size = Vector2(620, 440)
	_col.add_child(_about_scroll)
	var panel := PanelContainer.new()
	panel.theme_type_variation = "GlassPanel"
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_about_scroll.add_child(panel)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.text = ABOUT_TEXT % [GameConfig.TITLE, GameConfig.version(), GameConfig.TITLE]
	panel.add_child(text)
	var back := LGUi.button("Back", _show_main)
	_col.add_child(back)
	back.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if _about_scroll == null or not is_instance_valid(_about_scroll):
		return
	var step := 0
	if event.is_action_pressed("ui_down", true):
		step = 1
	elif event.is_action_pressed("ui_up", true):
		step = -1
	if step != 0:
		_about_scroll.scroll_vertical += step * 60
		get_viewport().set_input_as_handled()


const ABOUT_TEXT := """[center][b]%s[/b]  v%s
A LinuxGroove game

[b]Made by[/b]
The LinuxGroove team

[b]Art, sound, music and fonts[/b]
Kenney (kenney.nl)
Released under CC0. Thank you, Kenney!

Platformer Kit, Cube Pets, New Platformer Pack,
Input Prompts, UI Pack - Adventure, Kenney Fonts,
Music Loops, Music Jingles, Voiceover Pack,
Impact Sounds, Interface Sounds

[b]Made with[/b]
Godot Engine (godotengine.org), MIT
Nakama Godot client by Heroic Labs, Apache-2.0

Copyright (c) 2026 The LinuxGroove team
%s is free software under the MIT license.[/center]"""
