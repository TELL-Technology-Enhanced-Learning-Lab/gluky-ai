extends Node3D

const TIMER = 100
@onready var level = get_parent()
var speed = 10 
var difficulty_spike = 1
var countdown = TIMER


func _ready():
	if has_obstacle_surfaces():
		var static_body = find_child("StaticBody3D", true, false) as StaticBody3D
		if static_body:
			static_body.add_to_group("obstacles")

func _process(delta: float) -> void:
	countdown -= 1
	if countdown <= 0:
		difficulty_spike += delta
		speed += log(difficulty_spike)
		countdown = TIMER
	position.z -= speed * delta
	
	var camera = get_viewport().get_camera_3d()
	var camera_z = camera.global_position.z
	if position.z < camera_z - 20:
		level.spawnModule(position.z + (level.amount * level.offset))
		queue_free()

func has_obstacle_surfaces() -> bool:
	var mesh_instances = find_children("*", "MeshInstance3D", true, false)
	var found_obstacle = false
	
	for mesh in mesh_instances:
		for i in range(mesh.get_surface_override_material_count()):
			var material = mesh.get_surface_override_material(i)
			if material is StandardMaterial3D:
				var std_mat = material as StandardMaterial3D
				if is_red_material(std_mat):
					found_obstacle = true
					break
		if found_obstacle:
			break
	return found_obstacle

func is_red_material(mat: StandardMaterial3D) -> bool:
	return mat.albedo_color.r > 0.7 and mat.albedo_color.g < 0.3 and mat.albedo_color.b < 0.3
