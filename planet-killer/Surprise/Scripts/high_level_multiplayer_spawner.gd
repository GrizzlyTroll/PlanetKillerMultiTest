extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	# Disable automatic spawning since we handle it manually in game.gd
	# multiplayer.peer_connected.connect(spawn_player)
	pass


func spawn_player(id:int) -> void:
	if !multiplayer.is_server(): return
	
	# Check if network_player scene is assigned
	if network_player == null:
		print("Warning: network_player PackedScene not assigned in MultiplayerSpawner")
		return
	
	var player: Node = network_player.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	
	# Set position based on player ID
	player.position = Vector2(100 + (id * 100), 100)
	
	print("MultiplayerSpawner: Spawning player with ID: ", id, " at position: ", player.position)
	
	get_node(spawn_path).call_deferred("add_child", player)
