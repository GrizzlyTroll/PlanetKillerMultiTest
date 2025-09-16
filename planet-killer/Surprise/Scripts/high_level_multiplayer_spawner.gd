extends MultiplayerSpawner

@export var network_player: PackedScene
var spawn_counter: int = 0

func _ready() -> void:
	# Set the network_player scene programmatically if not already set
	if network_player == null:
		network_player = preload("res://Scenes/PlayerStuff/Player.tscn")
		print("MultiplayerSpawner: Set network_player scene programmatically")
	
	print("MultiplayerSpawner: network_player is now: ", network_player)
	
	# Connect to peer connected signal for automatic spawning
	multiplayer.peer_connected.connect(_on_peer_connected)
	print("MultiplayerSpawner: Connected to peer_connected signal")


func _on_peer_connected(id: int) -> void:
	print("MultiplayerSpawner: Peer connected: ", id)
	if multiplayer.is_server():
		print("MultiplayerSpawner: Server spawning player for peer: ", id)
		# Use the built-in spawn method
		spawn(id)

# This function is called by the MultiplayerSpawner when it needs to spawn a player
func _spawn_player(id: int) -> Node:
	print("MultiplayerSpawner: _spawn_player called with ID: ", id)
	
	# Check if network_player scene is assigned
	if network_player == null:
		print("Warning: network_player PackedScene not assigned in MultiplayerSpawner")
		return null
	
	print("MultiplayerSpawner: Instantiating player scene...")
	var player: Node = network_player.instantiate()
	player.name = str(id)
	player.set_multiplayer_authority(id)
	
	# Set position based on spawn counter for consistent spacing
	spawn_counter += 1
	player.position = Vector2(100 + (spawn_counter * 100), 100)
	
	print("MultiplayerSpawner: Spawning player with ID: ", id, " at position: ", player.position)
	
	# Add the player to the spawn path so it gets synchronized
	var spawn_node = get_node(spawn_path)
	if spawn_node:
		spawn_node.add_child(player)
		print("MultiplayerSpawner: Player added to spawn node for synchronization")
	else:
		print("MultiplayerSpawner: Warning - spawn node not found!")
	
	return player
