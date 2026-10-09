class_name SilverRush
extends Node3D
## A timed challenge: step on the button, then find every silver coin before
## the time runs out, for a star. Out of time, the coins go and the button
## pops back up to try again.

signal started
signal won

var level: Level
var star_id := ""
var spots: Array = []
var seconds := 30.0
var button_at := Vector3.ZERO

var button: PadButton
var time_left := 0.0
var coins: Array[Pickup] = []
var got := 0


func _ready() -> void:
	button = level.add(PadButton.new(), button_at) as PadButton
	button.pressed.connect(start)
	if level.found_stars.has(star_id):
		level.add_star(star_id, button_at + Vector3.UP * 1.2)
		button.down = true


func is_running() -> bool:
	return not coins.is_empty()


func start() -> void:
	if level.found_stars.has(star_id) or is_running():
		return
	time_left = seconds
	got = 0
	for at in spots:
		var p := Pickup.make("silver")
		level.add(p, at + Vector3.UP * 0.2)
		p.collected.connect(_on_coin)
		coins.append(p)
	level.say("Find %d silver coins!" % spots.size())
	started.emit()


func _on_coin() -> void:
	got += 1
	if got >= spots.size():
		coins.clear()
		time_left = 0.0
		_countdown("", -1.0)
		level.add_star(star_id, button_at + Vector3.UP * 1.2)
		won.emit()
	else:
		level.say("%d of %d silver coins" % [got, spots.size()])


func _physics_process(delta: float) -> void:
	if coins.is_empty():
		return
	time_left -= delta
	_countdown("Silver coins %d/%d" % [got, spots.size()], maxf(time_left, 0.0))
	if time_left <= 0.0:
		for p in coins:
			if is_instance_valid(p):
				p.queue_free()
		coins.clear()
		_countdown("", -1.0)
		button.release()
		level.say("Out of time. Step on the button to try again.")


func _countdown(label: String, secs: float) -> void:
	level.countdown.emit(label, secs)
