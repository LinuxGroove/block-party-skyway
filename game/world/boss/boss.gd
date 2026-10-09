class_name Boss
extends Node3D
## Base for bosses: health, a short spell after each hit when the boss
## neither takes another nor hurts the hero (who is bouncing off it), and a
## body that hurts the hero to touch unless it's open to a stomp.
##
## A boss subclass moves in think() and decides when it can be hit by
## setting `open` (stunned, dizzy, its weak spot showing). While open,
## landing on it (a jump or a ground pound) or diving into it is a hit;
## every other touch hurts the hero. Bosses tell the hero what to do with
## level.say() as they go.

signal health_changed(health: int, max_health: int)
signal defeated

var level: Level
var boss_name := ""
var max_health := 3
var health := 3
## True while a hit counts (stunned, dizzy, weak spot showing).
var open := false
## Seconds after a hit before the next can land.
var invulnerable := 0.0
var beaten := false
## Seconds since the fight started; bosses wait a little before acting.
var time := 0.0

var _touch: Area3D
var _touch_size := Vector3.ONE
var _touch_lift := 0.0
## Ticks since the hero was last above the body (touches show up late).
var _above := 99


func _ready() -> void:
	health = max_health


## The body the hero touches: a box of `size`, its bottom `lift` above the
## boss's feet. Call once from the subclass's _ready().
func make_body(size: Vector3, lift := 0.0) -> Area3D:
	_touch_size = size
	_touch_lift = lift
	_touch = Area3D.new()
	_touch.collision_layer = 0
	_touch.collision_mask = Kit.LAYER_HERO
	_touch.monitorable = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position.y = lift + size.y / 2.0
	_touch.add_child(shape)
	add_child(_touch)
	_touch.body_entered.connect(_on_touched)
	return _touch


func hero() -> Hero:
	return level.hero


func _physics_process(delta: float) -> void:
	if beaten:
		return
	time += delta
	invulnerable = maxf(invulnerable - delta, 0.0)
	think(delta)
	if level.hero and _touch and level.hero.global_position.y > _touch.global_position.y + _touch_lift + _touch_size.y * 0.6:
		_above = 0
	else:
		_above += 1
	if _touch and level.hero and _touch.overlaps_body(level.hero):
		_on_touched(level.hero)


## The boss's own behaviour, every physics tick. Override.
func think(_delta: float) -> void:
	pass


func _on_touched(body: Node3D) -> void:
	if beaten or body != level.hero:
		return
	var h := level.hero
	var above := _above <= 3 and h.velocity.y < 1.0
	if open and invulnerable <= 0.0 and (h.is_pounding() or h.is_diving() or above):
		if not h.is_diving():
			h.bounce(13.0)
		hit()
	elif invulnerable <= 0.0:
		level.hurt_hero(global_position)


## Takes one hit. Returns false if it didn't count.
func hit() -> bool:
	if beaten or invulnerable > 0.0:
		return false
	health -= 1
	invulnerable = 1.2
	open = false
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/impactPunch_medium_000.ogg", 0.0, 0.05)
	health_changed.emit(health, max_health)
	if health <= 0:
		beaten = true
		_on_beaten()
		defeated.emit()
	else:
		_on_hit()
	return true


## After a hit that didn't finish the boss. Override (get angrier).
func _on_hit() -> void:
	pass


## The boss is beaten: by default it squashes flat and vanishes.
func _on_beaten() -> void:
	if _touch:
		_touch.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1.4, 0.15, 1.4), 0.2)
	tw.tween_interval(0.6)
	tw.tween_property(self, "scale", Vector3.ONE * 0.01, 0.3)
	tw.tween_callback(hide)
