class_name Ghost
extends RefCounted
## A recorded run: where the hero was, which way they faced and what they
## were doing, 20 times a second. Positions rather than button presses,
## since physics isn't guaranteed to come out the same on every computer.
## About 30 KB a minute before compression.

const RATE := 20.0
const VERSION := 1
## The clips a ghost can show, by index.
const CLIPS := ["idle", "walk", "sprint", "jump", "fall", "crouch"]

var hero := 0
var msec := 0
## x, y, z, yaw and pitch per sample.
var frames := PackedFloat32Array()
var clips := PackedByteArray()

var _clock := 0.0


func clear() -> void:
	frames = PackedFloat32Array()
	clips = PackedByteArray()
	msec = 0
	_clock = 0.0


func sample_count() -> int:
	return clips.size()


func duration() -> float:
	return max(sample_count() - 1, 0) / RATE


## Call every physics tick while the run is on.
func record(h: Hero, delta: float) -> void:
	if sample_count() > 0:
		_clock += delta
		if _clock + 0.0001 < 1.0 / RATE:
			return
		_clock -= 1.0 / RATE
	var p := h.global_position
	frames.append_array([p.x, p.y, p.z, atan2(h.facing.x, h.facing.z), h.pose_pitch()])
	var clip := CLIPS.find(h.rig.current_clip() if h.rig else "idle")
	clips.append(maxi(clip, 0))


## Where the ghost is `t` seconds in: {position, yaw, pitch, clip}.
func sample(t: float) -> Dictionary:
	var n := sample_count()
	if n == 0:
		return {}
	var f := clampf(t * RATE, 0.0, n - 1.0)
	var i := int(f)
	var j := mini(i + 1, n - 1)
	var u := f - i
	var a := Vector3(frames[i * 5], frames[i * 5 + 1], frames[i * 5 + 2])
	var b := Vector3(frames[j * 5], frames[j * 5 + 1], frames[j * 5 + 2])
	return {
		"position": a.lerp(b, u),
		"yaw": lerp_angle(frames[i * 5 + 3], frames[j * 5 + 3], u),
		"pitch": lerpf(frames[i * 5 + 4], frames[j * 5 + 4], u),
		"clip": CLIPS[clips[i]] if clips[i] < CLIPS.size() else "idle",
	}


func to_bytes() -> PackedByteArray:
	var data := {"v": VERSION, "hero": hero, "msec": msec, "frames": frames, "clips": clips}
	return var_to_bytes(data).compress(FileAccess.COMPRESSION_GZIP)


static func from_bytes(bytes: PackedByteArray) -> Ghost:
	if bytes.is_empty():
		return null
	var raw := bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var data = bytes_to_var(raw)
	if not data is Dictionary or int(data.get("v", 0)) != VERSION:
		return null
	var g := Ghost.new()
	g.hero = int(data.get("hero", 0))
	g.msec = int(data.get("msec", 0))
	g.frames = data.get("frames", PackedFloat32Array())
	g.clips = data.get("clips", PackedByteArray())
	if g.frames.size() != g.clips.size() * 5:
		return null
	return g
