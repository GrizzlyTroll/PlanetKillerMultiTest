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
	
	get_node(spawn_path).call_deferred("add_child", player)
