extends Node3D  

@onready var _skin: CharacterSkin = $PlayerSkin

func _ready() -> void:
	add_to_group("player")
	

func _process(_delta: float) -> void:
	update_animation_state()

func update_animation_state() -> void:
	if not _skin:
		return

	_skin.idle()
	_skin.run_tilt = 0.0 
