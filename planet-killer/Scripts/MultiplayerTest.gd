extends Node2D

@onready var ui = $HighLevelUI
@onready var game = $Game

func _ready():
	# Connect UI signals to handle scene transitions
	ui.server_created.connect(_on_server_created)
	ui.server_joined.connect(_on_server_joined)
	ui.server_left.connect(_on_server_left)

func _on_server_created():
	print("Test: Server created, switching to game scene")
	ui.visible = false
	game.visible = true

func _on_server_joined():
	print("Test: Joined server, switching to game scene")
	ui.visible = false
	game.visible = true

func _on_server_left():
	print("Test: Left server, returning to lobby")
	ui.visible = true
	game.visible = false
