extends CharacterBody3D

var positions = [-3, 0, 3]
var currentPosition = 1
var swipeLength = 100
var startSwipe: Vector2
var currentSwipe: Vector2
var swiping = false
var threshold = 50
var swipeDir = 0
var timer: float = 0.0
var glucoseVal = 50

@onready var level = get_parent()
@onready var game_setup = get_parent()
@onready var collection_area: Area3D = $CollectionArea

const JUMP_VEL = 20
const GRAVITY = 40
const FALL_GRAVITY = 50

func _ready() -> void:
	game_setup.update_value(glucoseVal)
	collection_area.body_entered.connect(_on_collection_area_body_entered)
	
func _process(delta: float) -> void:
	swipe()
	
	timer += delta
	if timer >= 1.3:  
		glucoseVal -= 1
		game_setup.update_value(glucoseVal)
		timer = 0.0  
		
	if swipeDir == 1:
		if currentPosition < 2:
			currentPosition += 1
			swipeDir = 0
	elif swipeDir == -1:
		if currentPosition > 0:
			currentPosition -= 1
			swipeDir = 0
	
	position.x = lerpf(position.x, positions[currentPosition], delta*30)
	if velocity.y < 0:
		velocity.y -= FALL_GRAVITY * delta
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

func swipe():
	if Input.is_action_just_pressed("press"):
		if !swiping:
			swiping = true
			startSwipe = get_viewport().get_mouse_position()
	if Input.is_action_pressed("press"):
		if swiping:
			currentSwipe = get_viewport().get_mouse_position()
			if startSwipe.distance_to(currentSwipe) >= swipeLength:
				if abs(startSwipe.y-currentSwipe.y) < threshold:
					if startSwipe.x-currentSwipe.x < 0:
						swipeDir = -1
					else:
						swipeDir = 1
				
				if abs(startSwipe.x-currentSwipe.x) < threshold:
					if startSwipe.y-currentSwipe.y > 0 and is_on_floor():
						velocity.y = JUMP_VEL					
				swiping = false
	else:
		swiping = false

func _on_collection_area_body_entered(body: Node3D) -> void:
	handle_collision(body)

func handle_collision(body: Node3D):
	if body.is_in_group("obstacles"): 
		get_tree().reload_current_scene()
	elif body.is_in_group("healthy foods"):
		glucoseVal = max(0, glucoseVal - 3)
		game_setup.update_value(glucoseVal)
		collect_item(body)
	elif body.is_in_group("sugary foods"):
		glucoseVal = min(100, glucoseVal + 4)
		game_setup.update_value(glucoseVal)
		collect_item(body)
	elif body.is_in_group("power ups"):
		glucoseVal = 50
		game_setup.update_value(glucoseVal)
		collect_item(body)
	   
func collect_item(item: Node3D):
	item.queue_free()
