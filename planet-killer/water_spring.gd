extends Node2D

var velocity = 0
var force = 0
var height = position.y
var target_height = position.y + 80
var k = 0.015
var d = 0.03

func water_update(spring_constant, dampening):
	height = position.y
	var x = height - target_height
	var loss = -dampening *  velocity
	force = - spring_constant * x + loss
	
	velocity += force
	
	position.y += velocity
	
func _physics_process(delta: float) -> void:
	water_update(k,d)
