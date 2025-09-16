extends Node2D


@export var k = 0.015
@export var d = 0.03
@export var spread = 0.0002

var springs = []

func _ready() -> void:
	for i in get_children():
		springs.append(i)
		i.initialize()
