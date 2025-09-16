class_name MovementComponent
extends Node

@export_subgroup("Settings")
@export var speed:float=150
@export var sprint_multiplier: float = 2.0

func handle_horizantal_movement(body: CharacterBody2D, direction: float, is_sprinting: bool = false) -> void:
	var current_speed = speed
	if is_sprinting:
		current_speed *= sprint_multiplier
	
	body.velocity.x = direction * current_speed
