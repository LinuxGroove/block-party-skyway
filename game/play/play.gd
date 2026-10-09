class_name Play
extends Node3D
## One visit to a level: an island in Adventure, or a course in Adventure or
## Speedrun. Owns the hero, the camera and the HUD, and turns what happens
## in the level into progress.
##
## Adventure: hearts, checkpoints, stars and secrets; falling off costs a
## heart and brings you back to the last flag, and nothing found is lost.
## Speedrun: a countdown, a clock to the hundredth, the best run's ghost,
## and one button to start again.

const SCENE := "res://game/play/play.tscn"
const TITLE := "res://game/ui/title.tscn"
const MAX_HEARTS := 3
const VOICE := "res://assets/kenney/audio/voice/"
const STAR_JINGLE := "res://assets/kenney/audio/jingles/jingles-steel_05.ogg"
const FINISH_JINGLE := "res://assets/kenney/audio/jingles/jingles-steel_08.ogg"

enum Run { COUNTDOWN, RUNNING, FINISHED }

var level_id := "sunny"
var mode := "adventure"
## Where the hero arrives: {"position": Vector3, "facing": Vector3}, or {}
## for the level's own start.
var arrive := {}

var level: Level
var hero: Hero
var cam: SkyCamera
var hud: Hud
var pause: PauseMenu
var results: ResultsPanel
var hearts := MAX_HEARTS
var respawn_at := Vector3.ZERO
var respawn_facing := Vector3.FORWARD
var run_state := Run.RUNNING
## Seconds on the clock (game time, so tests can run the game faster).
var run_time := 0.0
var countdown := 0.0
## The run being recorded, and the best one played back beside it.
var ghost: Ghost
var best_ghost: Ghost
var ghost_runner: GhostRunner
## Tests drive the hero with this instead of the controls: it gets the play
## scene each physics tick and fills hero.input.
var autopilot := Callable()

var _speech: Array = []
var _speaker := ""
var _speech_done := Callable()
var _leaving := false
var _first_run := true
var _beat := 0


## Opens a level in a mode (fading from the current screen).
static func open(p_level: String, p_mode := "adventure", p_arrive := {}) -> void:
	LGScenes.change_scene(SCENE, Play._setup.bind(p_level, p_mode, p_arrive))


static func _setup(node: Node, p_level: String, p_mode: String, p_arrive: Dictionary) -> void:
	node.level_id = p_level
	node.mode = p_mode
	node.arrive = p_arrive


func is_speedrun() -> bool:
	return mode == "speedrun"


## True for a course (as opposed to an island or a boss's arena).
func is_course() -> bool:
	return Courses.has(level_id)


func is_boss() -> bool:
	return Worlds.is_boss(level_id)


func world() -> String:
	return level.world if level else Worlds.world_of(level_id)


func _ready() -> void:
	hero = Hero.new()
	hero.name = "Hero"
	add_child(hero)
	cam = SkyCamera.new()
	cam.hero = hero
	add_child(cam)
	cam.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	hud.setup(mode)
	pause = PauseMenu.new()
	layer.add_child(pause)
	pause.setup(self)
	results = ResultsPanel.new()
	layer.add_child(results)
	results.setup(self)
	hero.jumped.connect(_on_jumped)
	hero.landed.connect(_on_landed)
	hero.pounded.connect(_on_pounded)
	hero.stepped.connect(_on_stepped)
	_load_level()
	var at := level.spawn
	var face := level.spawn_facing
	var spot := level.arrival(arrive)
	if spot.has("position"):
		at = spot.position
		face = spot.get("facing", face)
	respawn_at = at
	respawn_facing = face
	hero.place(at, face)
	cam.snap()
	LGAudio.play_music(level.music, -6.0)
	_refresh_hud()
	if is_speedrun():
		_start_countdown(3.0)
	elif not is_course():
		hud.banner(level.title, "World %d" % Worlds.number(world()), 2.0)


func _load_level() -> void:
	if level:
		remove_child(level)
		level.queue_free()
	level = Levels.make(level_id, mode)
	level.found_stars = Progress.stars.duplicate()
	level.found_gems = Progress.gems.duplicate()
	level.hero = hero
	hero.gravity_scale = level.gravity_scale
	add_child(level)
	move_child(level, 0)
	level.build()
	level.add_environment()
	level.star_found.connect(_on_star)
	level.coins_found.connect(_on_coins)
	level.gem_found.connect(_on_gem)
	level.heart_found.connect(_on_heart)
	level.hurt.connect(_on_hurt)
	level.checkpoint_reached.connect(_on_checkpoint)
	level.course_door.connect(_on_course_door)
	level.finished.connect(_on_finished)
	level.message.connect(_on_message)
	level.speech.connect(_on_speech)
	level.countdown.connect(_on_challenge)
	level.fell.connect(_fell)
	level.travel.connect(_on_travel)
	if level is BossArena:
		(level as BossArena).boss_changed.connect(_on_boss_changed)
		var arena := level as BossArena
		if arena.boss:
			hud.set_boss(arena.boss.boss_name, arena.boss.health, arena.boss.max_health)
	var base: Array = level.camera_base
	cam.set_base(base[0], base[1], base[2], base[3])
	cam.zones.clear()
	for z in level.camera_zones:
		cam.watch_zone(z)


func _physics_process(delta: float) -> void:
	_tick_input()
	if is_speedrun():
		_tick_run(delta)
	if hero.global_position.y < Hero.KILL_Y:
		_fell()
	var t := level.nearest_talker() if _speech.is_empty() and run_state != Run.FINISHED else null
	hud.set_context("talk", t.talk_text() if t else "")


func _tick_input() -> void:
	if autopilot.is_valid():
		autopilot.call(self)
		return
	if not _speech.is_empty():
		hero.input.clear()
		if Input.is_action_just_pressed("talk") or Input.is_action_just_pressed("jump"):
			_next_line()
		return
	if is_speedrun() and Input.is_action_just_pressed("restart"):
		restart_run()
		return
	if run_state != Run.RUNNING or _leaving:
		hero.input.clear()
		return
	hero.input.read(cam.input_yaw(), bool(LGSettings.get_value("play", "always_run")))
	if hero.input.talk and hero.is_on_floor() and not hero.is_locked():
		var t := level.nearest_talker()
		if t:
			hero.input.clear()
			t.talk()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not pause.visible and not results.visible:
		get_viewport().set_input_as_handled()
		pause.open()


func _notification(what: int) -> void:
	# Pause when the window loses focus (a handheld's overlay, alt-tab).
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree() and pause and not pause.visible and not results.visible and DisplayServer.get_name() != "headless":
		pause.open()


# --- Speedrun ----------------------------------------------------------------

func run_msec() -> int:
	return int(round(run_time * 1000.0))


func _start_countdown(seconds: float) -> void:
	run_state = Run.COUNTDOWN
	countdown = seconds
	run_time = 0.0
	_beat = ceili(seconds) + 1
	level.process_mode = Node.PROCESS_MODE_DISABLED
	hero.lock(seconds + 1.0)
	ghost = Ghost.new()
	ghost.hero = GameConfig.hero_index()
	if ghost_runner:
		ghost_runner.queue_free()
		ghost_runner = null
	best_ghost = Progress.load_ghost(level_id) if bool(LGSettings.get_value("play", "ghost")) else null
	if best_ghost:
		ghost_runner = GhostRunner.new()
		ghost_runner.ghost = best_ghost
		add_child(ghost_runner)
	_refresh_hud()


func _tick_run(delta: float) -> void:
	match run_state:
		Run.COUNTDOWN:
			countdown -= delta
			var beat := ceili(countdown)
			if beat != _beat and beat >= 0:
				_beat = beat
				if beat > 0:
					hud.show_count(str(beat))
					if beat <= 3:
						LGAudio.play_sfx(VOICE + "%d.ogg" % beat, -2.0)
			if countdown <= 0.0:
				_go()
		Run.RUNNING:
			run_time += delta
			ghost.record(hero, delta)
			if ghost_runner:
				ghost_runner.sync(run_time)
			hud.set_clock(run_msec(), _clock_sub())


func _go() -> void:
	run_state = Run.RUNNING
	level.process_mode = Node.PROCESS_MODE_INHERIT
	hero.lock(0.0)
	hud.show_count("Go!")
	LGAudio.play_sfx(VOICE + "go.ogg", -2.0)
	if ghost_runner:
		ghost_runner.start()
	get_tree().create_timer(0.6).timeout.connect(_clear_count)


func _clear_count() -> void:
	if run_state == Run.RUNNING:
		hud.show_count("")


func _clock_sub() -> String:
	var best := Progress.best_time(level_id)
	var next := Courses.next_medal(level_id, best)
	if next.is_empty():
		return "Best %s" % Courses.time_text(best)
	return "%s %s" % [Courses.MEDALS[next[0]], Courses.time_text(next[1])]


## Starts the run again from the top, straight away.
func restart_run() -> void:
	if _leaving:
		return
	results.close()
	_load_level()
	hero.place(level.spawn, level.spawn_facing)
	cam.snap()
	hud.show_count("")
	_start_countdown(3.0 if _first_run else 1.0)


func _finish_run() -> void:
	run_state = Run.FINISHED
	_first_run = false
	var msec := run_msec()
	ghost.msec = msec
	var old := Progress.best_time(level_id)
	var is_best := Progress.record_time(level_id, msec, ghost)
	hero.lock(9999.0)
	hero.rig.play_once("emote-yes")
	if ghost_runner:
		ghost_runner.stop()
	LGAudio.play_sfx(FINISH_JINGLE, -2.0)
	if is_best and old > 0:
		LGAudio.play_sfx(VOICE + "new_highscore.ogg", 0.0)
	hud.set_clock(msec, _clock_sub())
	results.show_result(level_id, msec, old, is_best)


# --- Adventure ---------------------------------------------------------------

func _on_star(id: String) -> void:
	var fresh := Progress.add_star(id)
	hero.lock(1.8)
	hero.rig.play_once("emote-yes")
	LGAudio.play_sfx(STAR_JINGLE, -2.0)
	var sub := Worlds.star_name(id)
	var next := Worlds.neighbour(world(), 1)
	if is_boss() and next != "" and Worlds.is_built(next):
		sub = "The Skyway to %s is back!" % Worlds.world_name(next)
	elif is_boss() and next == "":
		sub = "The Sky Isles' stars are free!"
	hud.banner("Star found!" if fresh else "Found it again", sub, 3.0 if is_boss() else 2.0)
	_refresh_hud()
	if (is_course() or is_boss()) and not is_speedrun():
		_leaving = true
		get_tree().create_timer(3.4 if is_boss() else 2.6).timeout.connect(back_to_island)


func _on_coins(n: int) -> void:
	Progress.add_coins(n)
	_refresh_hud()


func _on_gem(id: String) -> void:
	var fresh := Progress.add_gem(id)
	var have := 0
	var gems := Worlds.gem_ids(world())
	for g in gems:
		if Progress.has_gem(g):
			have += 1
	hud.banner("Hidden gem found!" if fresh else "Found it again", "%d of %d in %s" % [have, gems.size(), Worlds.world_name(world())], 2.0)
	_refresh_hud()


func _on_heart() -> void:
	hearts = mini(hearts + 1, MAX_HEARTS)
	_refresh_hud()


func _on_hurt(_from: Vector3) -> void:
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_hurt.ogg", -2.0)
	if is_speedrun():
		return
	hearts -= 1
	if hearts <= 0:
		hearts = MAX_HEARTS
		hud.toast("Ouch! Back to the last flag.")
		respawn()
	_refresh_hud()


func _fell() -> void:
	if is_speedrun():
		restart_run()
		return
	hearts -= 1
	if hearts <= 0:
		hearts = MAX_HEARTS
	hud.toast("Whoops! Back to the last flag.")
	respawn()
	_refresh_hud()


## Puts the hero back at the last flag.
func respawn() -> void:
	hero.place(respawn_at + Vector3.UP * 0.1, respawn_facing)
	hero.safe_time = 1.0
	cam.snap()


func _on_checkpoint(at: Vector3, facing: Vector3) -> void:
	respawn_at = at
	respawn_facing = facing
	hearts = MAX_HEARTS
	if not is_course() and not is_boss():
		Progress.island_spot = {"level": level_id, "position": at, "facing": facing}
	Progress.save()
	_refresh_hud()


func _on_course_door(course_id: String) -> void:
	if _leaving:
		return
	_leaving = true
	hero.lock(9999.0)
	if Courses.has(course_id):
		Progress.find_course(course_id)
	Progress.island_spot = {"level": level_id, "door": course_id}
	Progress.save()
	Play.open(course_id, "adventure")


## Through a Skyway gate to another world's island.
func _on_travel(id: String, p_arrive: Dictionary) -> void:
	if _leaving:
		return
	_leaving = true
	hero.lock(9999.0)
	Progress.island_spot = {"level": id, "door": str(p_arrive.get("door", ""))}
	Progress.save()
	Play.open(id, "adventure", p_arrive)


func _on_finished() -> void:
	if is_speedrun():
		_finish_run()
	else:
		level.collect_star(str(Courses.get_def(level_id).star))


## From a course or the boss's arena back out of its door on the island.
func back_to_island() -> void:
	_leaving = true
	Progress.save()
	var island := str(Worlds.get_def(world()).island)
	Progress.island_spot = {"level": island, "door": level_id}
	Play.open(island, "adventure", {"door": level_id})


func quit_to_title() -> void:
	_leaving = true
	get_tree().paused = false
	Progress.save()
	LGScenes.change_scene(TITLE)


func _on_message(text: String) -> void:
	hud.toast(text)


func _on_challenge(label: String, seconds: float) -> void:
	hud.set_challenge(label, seconds)


func _on_boss_changed(boss_name: String, health: int, max_health: int) -> void:
	hud.set_boss(boss_name, health, max_health)


func _on_speech(speaker: String, lines: Array, done: Callable) -> void:
	if lines.is_empty():
		if done.is_valid():
			done.call()
		return
	_speech = lines.duplicate()
	_speaker = speaker
	_speech_done = done
	hero.lock(9999.0)
	hud.show_speech(speaker, str(_speech[0]))


func _next_line() -> void:
	_speech.pop_front()
	LGUi.click()
	if not _speech.is_empty():
		hud.show_speech(_speaker, str(_speech[0]))
		return
	hud.hide_speech()
	hero.lock(0.0)
	var done := _speech_done
	_speech_done = Callable()
	if done.is_valid():
		done.call()


func speech_open() -> bool:
	return not _speech.is_empty()


func _refresh_hud() -> void:
	var w := world()
	var stars := Progress.star_count(w)
	var gems := 0
	for g in Worlds.gem_ids(w):
		if Progress.has_gem(g):
			gems += 1
	hud.set_counts(stars, Worlds.star_ids(w).size(), Progress.coins, gems, Worlds.gem_ids(w).size())
	hud.set_hearts(hearts, MAX_HEARTS)
	if is_speedrun():
		var best := Progress.best_time(level_id)
		hud.set_place(level.title, "Speedrun  ·  best %s" % Courses.time_text(best) if best > 0 else "Speedrun  ·  no time yet")
		hud.set_clock(run_msec(), _clock_sub())
	elif is_course() or is_boss():
		hud.set_place(level.title, "Adventure  ·  " + Worlds.world_name(w))
	elif level is Island:
		var left: int = (level as Island).secrets_left()
		hud.set_place("World %d  ·  %s" % [Worlds.number(w), level.title], "Adventure  ·  %d secrets left in this world" % left if left > 0 else "Adventure  ·  every secret found")


# --- Sounds ------------------------------------------------------------------

func _on_jumped(kind: String) -> void:
	match kind:
		"high", "pound", "bounce":
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_jump-high.ogg", -6.0, 0.05)
		"dive":
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_throw.ogg", -6.0, 0.05)
		"pound_spin":
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_disappear.ogg", -8.0, 0.05)
		_:
			LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_jump.ogg", -8.0, 0.08)


func _on_landed(speed: float) -> void:
	if speed > 20.0:
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", -2.0, 0.05)
	elif speed > 6.0:
		LGAudio.play_sfx("res://assets/kenney/audio/sfx/footstep_grass_000.ogg", -4.0, 0.1)


func _on_pounded(at: Vector3) -> void:
	level.on_pounded(at)


func _on_stepped() -> void:
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/footstep_grass_00%d.ogg" % (randi() % 4), -14.0, 0.1)
