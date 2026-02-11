extends Node3D

@export var fire_interval: float = 4.0
@export var projectile_speed: float = 25.0
@export var launch_angle: float = 15.0
@export var obstacle_scenes: Array[PackedScene]

@export var recoil_distance: float = 0.5
@export var recoil_duration: float = 0.2
@export var return_duration: float = 0.3

@onready var cannon_mesh: Node3D = $CannonMesh
@onready var spawn_point: Node3D = $SpawnPoint
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var timer: float = 0.0
var original_position: Vector3

func _ready():
	original_position = cannon_mesh.position

func _process(delta):
	timer += delta
	
	if timer >= fire_interval:
		timer = 0.0
		fire_cannon()

func fire_cannon():
	animation_player.play("fire")
	
	if obstacle_scenes.size() > 0:
		var random_index = randi() % obstacle_scenes.size()
		var selected_scene = obstacle_scenes[random_index]
		var obstacle = selected_scene.instantiate()
		get_tree().current_scene.add_child(obstacle)
		
		obstacle.global_position = spawn_point.global_position
		obstacle.global_rotation = spawn_point.global_rotation
		
		var forward = spawn_point.global_transform.basis.z
		var up = spawn_point.global_transform.basis.y
		
		var launch_direction = forward * cos(deg_to_rad(launch_angle)) + up * sin(deg_to_rad(launch_angle))
		launch_direction = launch_direction.normalized()
		
		if obstacle.has_method("apply_impulse"):
			obstacle.apply_impulse(launch_direction * projectile_speed, Vector3.ZERO)
		elif obstacle is RigidBody3D:
			obstacle.linear_velocity = launch_direction * projectile_speed
			
		var removal_timer = get_tree().create_timer(2.0)
		removal_timer.timeout.connect(_remove_obstacle.bind(obstacle))

func _remove_obstacle(obstacle: Node):
	if is_instance_valid(obstacle) and obstacle.is_inside_tree():
		obstacle.queue_free()

func deg_to_rad(degrees: float) -> float:
	return degrees * PI / 180.0
