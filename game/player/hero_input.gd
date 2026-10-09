class_name HeroInput
extends RefCounted
## One tick of the hero's controls. The play scene fills it from the pad or
## keyboard (turning the stick into a world direction with the camera); tests
## and the course autopilot fill it themselves.

## World direction on the ground (y is 0), length 0 to 1.
var move := Vector3.ZERO
var jump := false
var jump_held := false
var run := false
var crouch := false
var crouch_pressed := false
var dive := false
var talk := false


func clear() -> void:
	move = Vector3.ZERO
	jump = false
	jump_held = false
	run = false
	crouch = false
	crouch_pressed = false
	dive = false
	talk = false


## Reads the controls for this physics tick. `cam_yaw` is the camera's
## heading, so pushing up always moves away from the camera.
func read(cam_yaw: float, always_run := false) -> void:
	var stick := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	move = Vector3(stick.x, 0.0, stick.y).rotated(Vector3.UP, cam_yaw)
	if move.length() > 1.0:
		move = move.normalized()
	jump = Input.is_action_just_pressed("jump")
	jump_held = Input.is_action_pressed("jump")
	run = always_run != Input.is_action_pressed("run")
	crouch = Input.is_action_pressed("crouch")
	crouch_pressed = Input.is_action_just_pressed("crouch")
	dive = Input.is_action_just_pressed("dive")
	talk = Input.is_action_just_pressed("talk")
