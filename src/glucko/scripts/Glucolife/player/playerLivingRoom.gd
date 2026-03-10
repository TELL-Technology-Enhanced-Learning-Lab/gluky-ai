extends Node3D  

@onready var _skin: CharacterSkin = $PlayerSkin

@export_group("Dirt System")
@export var enable_dirt: bool = true
@export var check_interval: float = 3.0

@export_group("Dirt Textures")
@export var dirt_textures: Array[Texture2D] = []

@export_group("Dirt Placement")
@export var max_decals: int = 8
@export var sprite_size: Vector2 = Vector2(0.3, 0.3)
@export var random_variation: float = 0.1

@export_group("Dirt Positions")
@export var decal_positions: Array[Vector3] = [
	Vector3(0.2, 0.5, 0.1),
	Vector3(-0.2, 0.5, 0.1),
	Vector3(0.15, 0.3, 0.15),
	Vector3(-0.15, 0.3, 0.15),
	Vector3(0.1, 0.1, 0.1),
	Vector3(-0.1, 0.1, 0.1),
	Vector3(0.0, 0.7, 0.2),
	Vector3(0.2, 0.7, 0.1),
	Vector3(-0.2, 0.7, 0.1),
]

var dirt_timer: Timer
var current_hygiene: float = 100.0
var active_dirt_nodes: Array[Sprite3D] = []
var dirt_parent: Node3D

func _ready() -> void:
	add_to_group("player")
	Glukybot.update_scene("res://scenes/glucolife rooms/Living room.tscn")
	
	if enable_dirt:
		_setup_dirt_system()

func _setup_dirt_system():
	dirt_parent = Node3D.new()
	dirt_parent.name = "DirtSprites"
	add_child(dirt_parent)
	
	if GlucolifeDataManager:
		GlucolifeDataManager.stats_changed.connect(_on_stats_changed)
	
	dirt_timer = Timer.new()
	dirt_timer.wait_time = check_interval
	dirt_timer.timeout.connect(_check_hygiene)
	add_child(dirt_timer)
	dirt_timer.start()
	
	_check_hygiene()

func _on_stats_changed(stats: Dictionary):
	if stats.has("hygiene"):
		current_hygiene = stats.hygiene
		_update_dirt_level()

func _check_hygiene():
	if GlucolifeDataManager:
		var stats = GlucolifeDataManager.get_stats()
		current_hygiene = stats.hygiene
		_update_dirt_level()

func _update_dirt_level():
	if not enable_dirt or dirt_textures.is_empty():
		return
	
	var dirt_level = 1.0 - (current_hygiene / 100.0)
	dirt_level = clamp(dirt_level, 0.0, 1.0)
	
	var target_decals = int(dirt_level * max_decals)
	
	while active_dirt_nodes.size() > target_decals:
		var node = active_dirt_nodes.pop_back()
		if is_instance_valid(node):
			node.queue_free()
	
	while active_dirt_nodes.size() < target_decals:
		_add_dirt_sprite()

func _add_dirt_sprite():
	if dirt_textures.is_empty():
		return
	
	var sprite = Sprite3D.new()
	sprite.texture = dirt_textures[randi() % dirt_textures.size()]
	
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.centered = true
	sprite.double_sided = true
	sprite.pixel_size = 0.01
	
	var pos_index = randi() % decal_positions.size()
	var base_pos = decal_positions[pos_index]
	
	var pos = Vector3(
		base_pos.x + randf_range(-random_variation, random_variation),
		base_pos.y + randf_range(-random_variation, random_variation),
		base_pos.z + randf_range(-random_variation * 0.5, random_variation * 0.5)
	)
	
	sprite.position = pos
	sprite.scale = Vector3(
		sprite_size.x * randf_range(0.8, 1.2),
		sprite_size.y * randf_range(0.8, 1.2),
		1
	)
	sprite.rotation = Vector3(0, randf_range(0, 360), 0)
	
	var material = sprite.material_override
	if not material:
		material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = randf_range(0.6, 1.0)
	sprite.material_override = material
	
	dirt_parent.add_child(sprite)
	active_dirt_nodes.append(sprite)

func _process(_delta: float) -> void:
	update_animation_state()

func update_animation_state() -> void:
	if not _skin:
		return

	_skin.idle()
	_skin.run_tilt = 0.0
