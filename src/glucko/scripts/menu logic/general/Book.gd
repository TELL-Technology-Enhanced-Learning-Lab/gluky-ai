extends Node3D

var current_page_number = 1

@onready var static_page = $Book/Static
@onready var turning_page = $Book/Turning
@onready var turning_animation = $Book/Turning/AnimationPlayer

@onready var pf1 = $Book/Turning/PageLeft
@onready var pf2 = $Book/Turning/Page/Skeleton3D/Front
@onready var pf3 = $Book/Turning/Page/Skeleton3D/Back
@onready var pf4 = $Book/Turning/PageRight

@onready var ps1 = $Book/Static/PageLeft
@onready var ps2 = $Book/Static/PageRight

@onready var sfx : AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var animationPlayer : AnimationPlayer = $Book/Turning/AnimationPlayer

func _ready():
	turning_page.hide()
	animationPlayer.animation_finished.connect(_on_animation_finished)

func _input(_event):
	if turning_animation.is_playing():
		return
	if Input.is_action_just_pressed("ui_left"):
		turn_left()
	if Input.is_action_just_pressed("ui_right"):
		turn_right()

func turn_right():
	hide_and_show(pf4)
	static_page.hide()
	turning_page.show()
	turning_animation.play("Turn1")
	sfx.play()

func turn_left():
	if current_page_number <= 1:
		return
	hide_and_show(pf1)
	turning_page.show()
	static_page.hide()
	turning_animation.play("Turn2")
	sfx.play()

func hide_and_show(page : Node):
	page.hide()
	await get_tree().create_timer(0.1).timeout
	page.show()

func _on_animation_finished(anim_name):
	if anim_name == "Turn1":
		current_page_number += 2
	if anim_name == "Turn2":
		current_page_number -= 2
	static_page.show()
	turning_page.hide()

func play_page_turn_sound():
	if sfx:
		sfx.play()

func _reset_to_first_page():
	current_page_number = 1
	static_page.show()
	turning_page.hide()

func turn_page(direction: String):
	if direction == "right":
		turn_right()
	elif direction == "left":
		turn_left()
