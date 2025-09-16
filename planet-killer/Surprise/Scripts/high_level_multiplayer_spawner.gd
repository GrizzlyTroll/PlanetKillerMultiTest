extends MultiplayerSpawner

@export var network_player: PackedScene

func _ready() -> void:
	# Disable automatic spawning since we handle it manually in game.gd
	# multiplayer.peer_connected.connect(spawn_player)
	
	# Set the network_player scene programmatically if not already set
	if network_player == null:
		network_player = preload("res://Scenes/PlayerStuff/Player.tscn")
		print("MultiplayerSpawner: Set network_player scene programmatically")
	
	print("MultiplayerSpawner: network_player is now: ", network_player)


func spawn_player(id:int) -> void:
	print("MultiplayerSpawner: spawn_player called with ID: ", id)
	print("MultiplayerSpawner: Is server: ", multiplayer.is_server())
	
	if !multiplayer.is_server(): 
		print("MultiplayerSpawner: Not server, returning")
		return
	
	# Check if network_player scene is assigned
	if network_player == null:
		print("Warning: network_player PackedScene not assigned in MultiplayerSpawner")
		return
	
	print("MultiplayerSpawner: Instantiating player scene...")
	var player: Node = network_player.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	
	# Set position based on player ID
	player.position = Vector2(100 + (id * 100), 100)
	
	print("MultiplayerSpawner: Spawning player with ID: ", id, " at position: ", player.position)
	print("MultiplayerSpawner: Spawn path: ", spawn_path)
	
	var spawn_node = get_node(spawn_path)
	print("MultiplayerSpawner: Spawn node found: ", spawn_node)
	
	spawn_node.call_deferred("add_child", player)
	print("MultiplayerSpawner: Player added to spawn node")
