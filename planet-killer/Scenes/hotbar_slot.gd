extends Button

@export var slot_index: int = 0
var player: Node

func _ready():
	# Connect right-click for dropping
	button_down.connect(_on_button_down)

func _on_button_down():
	if Input.is_action_just_pressed("ui_accept"):  # Right-click
		drop_item()

func drop_item():
	if player and player.inv:
		var item = player.inv.get_item(slot_index)
		if item:
			player.drop_item(item, slot_index)
