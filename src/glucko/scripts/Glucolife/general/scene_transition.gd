extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready():
	color_rect.modulate.a = 0
	layer = 100

func change_scene(scene_path: String):
	var current_scene = get_tree().current_scene.scene_file_path
	if current_scene == scene_path:
		return
	
	if current_scene.begins_with("res://scenes/glucolife rooms/"):
		GlucolifeDataManager._save_data()
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.15)
	await tween.finished
	
	get_tree().change_scene_to_file(scene_path)
	
	await get_tree().process_frame
	
	tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.15)
