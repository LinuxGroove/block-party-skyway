class_name GearsTimedBridge
extends Node3D
## A timed switch: step on the button (or ground pound it) and a row of
## steel steps slides out, one after another, for `seconds`. They blink
## near the end, then fold away and the button pops back up to try again.
##
##   var b := GearsTimedBridge.new()
##   b.button_at = Vector3(0, 0, 4)
##   b.steps = [Vector3(0, 1, 0), Vector3(0, 2, -2)]    # each step's top centre
##   add(b, Vector3.ZERO)

signal started
signal timed_out

## Seconds of warning blinks before the steps go.
const BLINK := 2.0

var level: Level
var button_at := Vector3.ZERO
var steps: Array = []
var step_size := Vector3(2, 0.4, 2)
var seconds := 10.0
## Shown with the clock while the steps are out ("" hides the clock).
var label := "Switch"
## Seconds between one step sliding out and the next.
var stagger := 0.08

var button: PadButton
var time_left := 0.0
var bodies: Array[StaticBody3D] = []
## Out for good (the challenge is won).
var held := false


func _ready() -> void:
	button = level.add(PadButton.new(), button_at) as PadButton
	button.pressed.connect(start)
	for at in steps:
		var b := StaticBody3D.new()
		b.collision_layer = 0
		b.collision_mask = 0
		b.position = at
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = step_size
		shape.shape = box
		shape.position.y = -step_size.y / 2.0
		b.add_child(shape)
		var nx := int(roundf(step_size.x))
		var nz := int(roundf(step_size.z))
		for x in nx:
			for z in nz:
				var m := Kit.model("block-moving")
				m.position = Vector3(x - (nx - 1) / 2.0, -step_size.y, z - (nz - 1) / 2.0)
				m.scale.y = step_size.y / 0.3
				b.add_child(m)
		b.visible = false
		add_child(b)
		bodies.append(b)


func is_running() -> bool:
	return time_left > 0.0


func start() -> void:
	if is_running() or held:
		return
	time_left = seconds
	for i in bodies.size():
		var b := bodies[i]
		b.scale = Vector3(1, 0.05, 1)
		var tw := b.create_tween()
		tw.tween_interval(stagger * i)
		tw.tween_callback(_show_step.bind(b))
		tw.tween_property(b, "scale", Vector3.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_magic.ogg", -6.0)
	started.emit()


func _show_step(b: StaticBody3D) -> void:
	if not is_running() and not held:
		return
	b.visible = true
	b.collision_layer = Kit.LAYER_WORLD


## Keeps the steps out for good, with no clock: the challenge is won.
func hold() -> void:
	if held:
		return
	held = true
	if is_running() and label != "":
		level.countdown.emit("", -1.0)
	time_left = 0.0
	button.down = true
	for b in bodies:
		b.scale = Vector3.ONE
		_show_step(b)


func _physics_process(delta: float) -> void:
	if not is_running() or held:
		return
	time_left -= delta
	if label != "":
		level.countdown.emit(label, maxf(time_left, 0.0))
	if time_left <= BLINK:
		var on := int(time_left * 8.0) % 2 == 0
		for b in bodies:
			if b.collision_layer != 0:
				b.visible = on
	if time_left <= 0.0:
		time_left = 0.0
		for b in bodies:
			b.visible = false
			b.collision_layer = 0
		if label != "":
			level.countdown.emit("", -1.0)
		button.release()
		timed_out.emit()


## Leaving mid-countdown (a restart, a door) takes the clock away with it.
func _exit_tree() -> void:
	if is_running() and not held and label != "" and level:
		level.countdown.emit("", -1.0)
