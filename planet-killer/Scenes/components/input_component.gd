class_name InputComponent
extends Node

var input_horizontal: float = 0.0
@onready var timer = $Timer

func _process(_delta: float) -> void:
	input_horizontal = Input.get_axis("Left","Right")

func get_crouch_input() -> bool:
	return Input.is_action_pressed("Crouch")


func get_jump_input() -> bool:
	return Input.is_action_just_pressed("Jump")
	
func get_sprint_input() -> bool:
	return Input.is_action_pressed("Sprint")

func get_hit_input() -> bool:
	if Input.is_action_just_pressed("Hit"):
		timer.start()
		return true 
	if timer.is_stopped():
		return false
	return false
