extends TextureButton

@export var target_scene: String
var _scene

func _ready():
	_scene = load(target_scene)

func _pressed():
	get_tree().change_scene_to_packed(_scene)
