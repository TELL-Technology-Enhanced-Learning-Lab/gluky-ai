extends Node3D

@export var player_path: NodePath

@export var height: float = 1.6
@export var distance: float = 4.0
@export var side_offset: float = 0.0

@export var follow_speed: float = 6.0
@export var look_speed: float = 8.0


var current_bounds: AABB


@onready var player: Node3D = get_node_or_null(player_path)
@onready var camera: Camera3D = $Camera3D


func _ready():
	if camera:
		camera.current = true


func set_bounds_from_area(area: Area3D):
	var shape_node = area.get_node_or_null("CollisionShape3D")
	if not shape_node:
		return

	var shape = shape_node.shape

	if shape is BoxShape3D:
		var extents = shape.size * 0.5
		var center = area.global_position

		current_bounds = AABB(
			center - extents,
			shape.size
		)


func _process(delta):
	if not player or not camera:
		return


	var target_pos = player.global_position
	target_pos.y += height
	target_pos.x += side_offset


	if current_bounds.size != Vector3.ZERO:

		target_pos.x = clamp(
			target_pos.x,
			current_bounds.position.x,
			current_bounds.position.x + current_bounds.size.x
		)

		target_pos.y = clamp(
			target_pos.y,
			current_bounds.position.y,
			current_bounds.position.y + current_bounds.size.y
		)

		target_pos.z = clamp(
			target_pos.z,
			current_bounds.position.z,
			current_bounds.position.z + current_bounds.size.z
		)


	global_position = global_position.lerp(
		target_pos,
		follow_speed * delta
	)


	var cam_target = Vector3(0, 0, distance)

	camera.position = camera.position.lerp(
		cam_target,
		follow_speed * delta
	)


	var look_target = player.global_position
	look_target.y += height * 0.8


	var target_transform = camera.global_transform.looking_at(
		look_target,
		Vector3.UP
	)

	camera.global_transform = camera.global_transform.interpolate_with(
		target_transform,
		look_speed * delta
	)
