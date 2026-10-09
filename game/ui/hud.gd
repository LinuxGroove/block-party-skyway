class_name Hud
extends Control
## The heads-up display: where you are, stars, coins and gems, hearts, the
## speedrun clock, the button prompts, messages, big "star found" banners,
## the start countdown and speech from islanders and signs.

const PILL := Color(0.1, 0.14, 0.28, 0.8)
const INK_SOFT := Color(1, 1, 1, 0.75)
const KEY_SIZE := 40
const TOAST_TIME := 3.0

var _place: Label
var _place_sub: Label
var _counts: HBoxContainer
var _stars: Label
var _coins: Label
var _gems: Label
var _hearts: HBoxContainer
var _clock_box: PanelContainer
var _clock: Label
var _clock_sub: Label
var _challenge: PanelContainer
var _challenge_label: Label
var _prompts: HBoxContainer
var _toasts: VBoxContainer
var _banner: PanelContainer
var _banner_title: Label
var _banner_sub: Label
var _count: Label
var _speech: PanelContainer
var _speech_name: Label
var _speech_text: Label
var _speech_next: Control
var _context := ["", ""]
var _mode := "adventure"
var _heart_tex: Texture2D
var _heart_empty: Texture2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_heart_tex = load("res://assets/kenney/hud/hud_heart.png")
	_heart_empty = load("res://assets/kenney/hud/hud_heart_empty.png")
	_build_place()
	_build_counts()
	_build_hearts()
	_build_clock()
	_build_prompts()
	_build_middle()
	_build_speech()
	LGInput.device_changed.connect(_on_device_changed)


func _on_device_changed(_family: String) -> void:
	_refresh_prompts()


static func pill(color := PILL) -> PanelContainer:
	var p := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(16)
	box.content_margin_left = 20
	box.content_margin_right = 20
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", box)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func text(t: String, size := 24, color := Color.WHITE, heading := true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if heading:
		l.add_theme_font_override("font", LGTheme.heading_font)
	l.add_theme_constant_override("outline_size", 0)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func icon(path: String, size := 32) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path) if path != "" else null
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _corner(preset: Control.LayoutPreset, offset: Vector2) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	box.position += offset
	box.grow_horizontal = Control.GROW_DIRECTION_BEGIN if preset in [Control.PRESET_TOP_RIGHT, Control.PRESET_BOTTOM_RIGHT] else Control.GROW_DIRECTION_END
	box.grow_vertical = Control.GROW_DIRECTION_BEGIN if preset in [Control.PRESET_BOTTOM_LEFT, Control.PRESET_BOTTOM_RIGHT] else Control.GROW_DIRECTION_END
	return box


func _build_place() -> void:
	var box := _corner(Control.PRESET_TOP_LEFT, Vector2(18, 16))
	var p := pill()
	box.add_child(p)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	p.add_child(col)
	_place = text("", 26)
	col.add_child(_place)
	_place_sub = text("", 15, INK_SOFT)
	col.add_child(_place_sub)


func _build_counts() -> void:
	var box := _corner(Control.PRESET_TOP_RIGHT, Vector2(-18, 16))
	box.alignment = BoxContainer.ALIGNMENT_END
	var p := pill()
	p.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.add_child(p)
	_counts = HBoxContainer.new()
	_counts.add_theme_constant_override("separation", 10)
	p.add_child(_counts)
	_counts.add_child(icon("res://assets/kenney/hud/star.png", 34))
	_stars = text("0", 26)
	_counts.add_child(_stars)
	_counts.add_child(_spacer(10))
	_counts.add_child(icon("res://assets/kenney/hud/hud_coin.png", 34))
	_coins = text("0", 26)
	_counts.add_child(_coins)
	_counts.add_child(_spacer(10))
	_counts.add_child(icon("res://assets/kenney/hud/gem_blue.png", 30))
	_gems = text("0", 26)
	_counts.add_child(_gems)
	_challenge = pill(Color(0.42, 0.45, 0.55, 0.85))
	_challenge.size_flags_horizontal = Control.SIZE_SHRINK_END
	_challenge.visible = false
	box.add_child(_challenge)
	_challenge_label = text("", 22)
	_challenge.add_child(_challenge_label)


static func _spacer(w: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.x = w
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _build_hearts() -> void:
	var box := _corner(Control.PRESET_BOTTOM_LEFT, Vector2(18, -16))
	_hearts = HBoxContainer.new()
	_hearts.add_theme_constant_override("separation", 6)
	_hearts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hearts)


func _build_clock() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	holder.position.y = 14
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	_clock_box = pill()
	_clock_box.visible = false
	holder.add_child(_clock_box)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", -4)
	_clock_box.add_child(col)
	_clock = text("0.00", 46)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_clock)
	_clock_sub = text("", 15, INK_SOFT)
	_clock_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_clock_sub)


func _build_prompts() -> void:
	var box := _corner(Control.PRESET_BOTTOM_RIGHT, Vector2(-18, -16))
	_prompts = HBoxContainer.new()
	_prompts.add_theme_constant_override("separation", 10)
	_prompts.alignment = BoxContainer.ALIGNMENT_END
	_prompts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_prompts)


func _build_middle() -> void:
	_toasts = VBoxContainer.new()
	_toasts.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	_toasts.position.y -= 150
	_toasts.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toasts.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toasts.alignment = BoxContainer.ALIGNMENT_END
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toasts)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(col)
	_count = text("", 120, Color("ffd23f"))
	_count.add_theme_constant_override("outline_size", 14)
	_count.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.25))
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count.visible = false
	col.add_child(_count)
	_banner = pill(Color(0.1, 0.14, 0.28, 0.88))
	_banner.visible = false
	_banner.position.y = -120
	col.add_child(_banner)
	var bcol := VBoxContainer.new()
	_banner.add_child(bcol)
	_banner_title = text("", 44, Color("ffd23f"))
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bcol.add_child(_banner_title)
	_banner_sub = text("", 24)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bcol.add_child(_banner_sub)


func _build_speech() -> void:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	holder.position.y -= 100
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.grow_vertical = Control.GROW_DIRECTION_BEGIN
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)
	_speech = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(LGTheme.PARCHMENT, 0.97)
	box.border_color = Color("8a5a32")
	box.set_border_width_all(4)
	box.set_corner_radius_all(14)
	box.set_content_margin_all(18)
	box.content_margin_left = 26
	box.content_margin_right = 26
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.shadow_size = 8
	_speech.add_theme_stylebox_override("panel", box)
	_speech.custom_minimum_size = Vector2(720, 0)
	_speech.visible = false
	_speech.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_speech)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_speech.add_child(col)
	_speech_name = text("", 22, Color("8a5a32"))
	col.add_child(_speech_name)
	_speech_text = text("", 26, LGTheme.INK, false)
	_speech_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_text.custom_minimum_size.x = 660
	col.add_child(_speech_text)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	_speech_next = row


# --- What the play scene calls -----------------------------------------------

func setup(mode: String) -> void:
	_mode = mode
	_hearts.visible = mode == "adventure"
	_counts.get_parent().visible = mode == "adventure"
	_clock_box.visible = mode == "speedrun"
	_refresh_prompts()


func set_place(title: String, sub: String) -> void:
	_place.text = title.to_upper()
	_place_sub.text = sub.to_upper()
	_place_sub.visible = sub != ""


func set_counts(stars: int, total_stars: int, coins: int, gems: int, total_gems: int) -> void:
	_stars.text = "%d / %d" % [stars, total_stars]
	_coins.text = str(coins)
	_gems.text = "%d / %d" % [gems, total_gems]


func set_hearts(n: int, most: int) -> void:
	for c in _hearts.get_children():
		_hearts.remove_child(c)
		c.queue_free()
	for i in most:
		var r := icon("", 44)
		r.texture = _heart_tex if i < n else _heart_empty
		_hearts.add_child(r)


func set_clock(msec: int, sub: String) -> void:
	_clock.text = Courses.time_text(msec)
	_clock_sub.text = sub.to_upper()
	_clock_sub.visible = sub != ""


func set_challenge(label: String, seconds: float) -> void:
	_challenge.visible = seconds >= 0.0
	if seconds >= 0.0:
		_challenge_label.text = "%s  %d" % [label.to_upper(), ceili(seconds)]


## What Talk does right now ("Talk to Pebble"), or "" for nothing.
func set_context(action: String, label: String) -> void:
	if _context == [action, label]:
		return
	_context = [action, label]
	_refresh_prompts()


func _refresh_prompts() -> void:
	if _prompts == null:
		return
	for c in _prompts.get_children():
		_prompts.remove_child(c)
		c.queue_free()
	if _context[1] != "":
		_prompts.add_child(prompt(_context[0], _context[1], Color(0.55, 0.36, 0.12, 0.9)))
	if _mode == "speedrun":
		_prompts.add_child(prompt("restart", "Restart"))
	_prompts.add_child(prompt("jump", "Jump"))
	_prompts.add_child(prompt("run", "Run"))
	_prompts.add_child(prompt("dive", "Dive"))


## A pill with a button and what it does, like [A] Jump.
static func prompt(action: String, what: String, color := PILL) -> PanelContainer:
	var p := pill(color)
	(p.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = 10
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	row.add_child(key_cap(action))
	var l := text(what.to_upper(), 20)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	p.set_meta("action", action)
	p.set_meta("text", what)
	return p


## The prompts showing now, as [action, text] pairs (for tests).
func prompt_lines() -> Array:
	var out := []
	for c in _prompts.get_children():
		if not c.is_queued_for_deletion():
			out.append([c.get_meta("action"), c.get_meta("text")])
	return out


## The button for an action: the controller's glyph on a controller, else
## the key's name on a key cap.
static func key_cap(action: String) -> Control:
	var router: Node = Engine.get_main_loop().root.get_node_or_null("LGInput")
	var tex: Texture2D = router.glyph_for_action(action) if router and router.is_gamepad() else null
	if tex:
		var r := TextureRect.new()
		r.texture = tex
		r.custom_minimum_size = Vector2(KEY_SIZE, KEY_SIZE)
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return r
	var cap := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1, 1, 1, 0.92)
	box.set_corner_radius_all(8)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	cap.add_theme_stylebox_override("panel", box)
	cap.custom_minimum_size = Vector2(KEY_SIZE, KEY_SIZE - 6)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := text(router.label_for_action(action) if router else action, 18, PILL)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cap.add_child(l)
	return cap


func toast(message: String) -> void:
	for c in _toasts.get_children():
		if c.has_meta("text") and c.get_meta("text") == message and not c.is_queued_for_deletion():
			return
	var p := pill()
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.set_meta("text", message)
	var l := text(message, 24)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size.x = minf(message.length() * 13.0, 700.0)
	p.add_child(l)
	_toasts.add_child(p)
	while _toasts.get_child_count() > 3:
		var old := _toasts.get_child(0)
		_toasts.remove_child(old)
		old.queue_free()
	var tw := p.create_tween()
	tw.tween_interval(TOAST_TIME)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)


func banner(title: String, sub: String, seconds := 2.6) -> void:
	_banner_title.text = title.to_upper()
	_banner_sub.text = sub.to_upper()
	_banner_sub.visible = sub != ""
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner.scale = Vector2.ONE * 0.6
	_banner.pivot_offset = _banner.size / 2.0
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(seconds)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.4)
	tw.tween_callback(_banner.hide)


func banner_text() -> String:
	return _banner_title.text if _banner.visible else ""


func show_count(t: String) -> void:
	_count.text = t
	_count.visible = t != ""
	if t != "":
		_count.pivot_offset = _count.size / 2.0
		_count.scale = Vector2.ONE * 1.4
		var tw := _count.create_tween()
		tw.tween_property(_count, "scale", Vector2.ONE, 0.2)


func show_speech(speaker: String, line: String) -> void:
	_speech.visible = true
	_speech_name.text = speaker.to_upper()
	_speech_text.text = line
	for c in _speech_next.get_children():
		_speech_next.remove_child(c)
		c.queue_free()
	var cap := key_cap("talk")
	_speech_next.add_child(cap)


func hide_speech() -> void:
	_speech.visible = false


func speech_showing() -> bool:
	return _speech.visible
