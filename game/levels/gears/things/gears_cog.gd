class_name GearsCog
extends Area3D
## One of Bolt's lost golden cogs. Touch it and it spins off home to his
## machine.

signal found(cog: GearsCog)

var level: Level
## Where it goes when found (its slot on the machine).
var home := Vector3.ZERO
var is_home := false

var _model: Node3D
var _t := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Kit.LAYER_HERO
	# Set before entering the tree: things appear from inside physics signals.
	monitorable = false


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55
	shape.shape = sphere
	shape.position.y = 0.45
	add_child(shape)
	var holder := Node3D.new()
	holder.position.y = 0.45
	add_child(holder)
	_model = Kit.model("factory:cog-a", 0.8)
	# Stood on its edge, so it rolls round like a coin.
	_model.rotation.x = PI / 2.0
	holder.add_child(_model)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("ffc93c")
	gold.metallic = 0.6
	gold.roughness = 0.3
	gold.emission_enabled = true
	gold.emission = Color("a86a00")
	gold.emission_energy_multiplier = 0.4
	for m in _model.find_children("*", "MeshInstance3D", true, false):
		(m as MeshInstance3D).material_override = gold
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	var holder := _model.get_parent() as Node3D
	holder.rotation.y = _t * (0.8 if is_home else 2.4)
	if not is_home:
		holder.position.y = 0.45 + sin(_t * 2.0) * 0.1


func _on_body_entered(body: Node3D) -> void:
	if body != level.hero or is_home:
		return
	go_home()


func go_home() -> void:
	if is_home:
		return
	is_home = true
	set_deferred("monitoring", false)
	LGAudio.play_sfx("res://assets/kenney/audio/sfx/sfx_gem.ogg", -2.0)
	# A cog riding a platform leaves it to fly home.
	if get_parent() != level:
		reparent.call_deferred(level)
		_fly.call_deferred()
	else:
		_fly()


func _fly() -> void:
	var tw := create_tween()
	var mid := (position + home) / 2.0 + Vector3.UP * 4.0
	tw.tween_property(self, "position", mid, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position", home, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_arrived)


func _arrived() -> void:
	found.emit(self)
