extends Control

@onready var player_list_container: VBoxContainer = $VBoxContainer/PlayerList/PlayerListContainer
@onready var ready_button: Button = $VBoxContainer/LobbyControls/ReadyButton
@onready var start_game_button: Button = $VBoxContainer/LobbyControls/StartGameButton
@onready var leave_lobby_button: Button = $VBoxContainer/LobbyControls/LeaveLobbyButton
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var multiplayer_ui: Control = $MultiplayerUI

# Connection UI elements
@onready var server_list: ItemList = $MultiplayerUI/VBoxContainer/ServerBrowser/ServerList
@onready var refresh_button: Button = $MultiplayerUI/VBoxContainer/ServerBrowser/ServerBrowserButtons/RefreshButton
@onready var join_button: Button = $MultiplayerUI/VBoxContainer/ServerBrowser/ServerBrowserButtons/JoinButton
@onready var direct_connect_button: Button = $MultiplayerUI/VBoxContainer/DirectConnect/DirectConnectButton
@onready var ip_input: LineEdit = $MultiplayerUI/VBoxContainer/DirectConnect/IPInput
@onready var port_input: LineEdit = $MultiplayerUI/VBoxContainer/DirectConnect/PortInput
@onready var host_button: Button = $MultiplayerUI/VBoxContainer/Host

var network_handler: Node
var players: Dictionary = {}  # player_id -> player_info
var local_player_ready: bool = false
var discovered_servers: Array = []
var is_connected: bool = false

func _ready():
	# Verify UI elements are loaded
	_verify_ui_elements()
	
	# Find network handler
	print("Lobby: Looking for NetworkHandler node...")
	network_handler = get_node("NetworkHandler")
	print("Lobby: NetworkHandler found: ", network_handler)
	
	if not network_handler:
		print("Warning: Network handler not found!")
		# Try alternative ways to find it
		network_handler = get_tree().get_first_node_in_group("network_handler")
		print("Lobby: Found via group: ", network_handler)
		if not network_handler:
			return
	
	# Connect network handler signals
	network_handler.server_created.connect(_on_server_created)
	network_handler.server_joined.connect(_on_server_joined)
	network_handler.server_left.connect(_on_server_left)
	network_handler.connection_failed.connect(_on_connection_failed)
	network_handler.peer_connected.connect(_on_peer_connected)
	network_handler.peer_disconnected.connect(_on_peer_disconnected)
	network_handler.server_discovered.connect(_on_server_discovered)
	network_handler.servers_updated.connect(_on_servers_updated)
	
	# Connect UI signals with null checks
	if ready_button:
		ready_button.pressed.connect(_on_ready_pressed)
	if start_game_button:
		start_game_button.pressed.connect(_on_start_game_pressed)
	if leave_lobby_button:
		leave_lobby_button.pressed.connect(_on_leave_lobby_pressed)
	
	# Connect connection UI signals with null checks
	if refresh_button:
		refresh_button.pressed.connect(_on_refresh_pressed)
		print("Lobby: Refresh button signal connected")
	if join_button:
		join_button.pressed.connect(_on_join_pressed)
		print("Lobby: Join button signal connected")
	if direct_connect_button:
		direct_connect_button.pressed.connect(_on_direct_connect_pressed)
		print("Lobby: Direct connect button signal connected")
	if host_button:
		host_button.pressed.connect(_on_host_pressed)
		print("Lobby: Host button signal connected")
	else:
		print("Lobby: Host button is null!")
	if server_list:
		server_list.item_selected.connect(_on_server_selected)
		print("Lobby: Server list signal connected")
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_multiplayer_peer_connected)
	multiplayer.peer_disconnected.connect(_on_multiplayer_peer_disconnected)
	
	# Initialize lobby
	_update_lobby_ui()
	_show_connection_ui()
	
	# Disable the high_level_ui script's signal connections to prevent conflicts
	_disable_ui_script_signals()

func _verify_ui_elements():
	print("Verifying UI elements:")
	print("  ready_button: ", ready_button)
	print("  start_game_button: ", start_game_button)
	print("  leave_lobby_button: ", leave_lobby_button)
	print("  server_list: ", server_list)
	print("  refresh_button: ", refresh_button)
	print("  join_button: ", join_button)
	print("  direct_connect_button: ", direct_connect_button)
	print("  host_button: ", host_button)
	print("  ip_input: ", ip_input)
	print("  port_input: ", port_input)
	print("  multiplayer_ui: ", multiplayer_ui)

func _on_server_created():
	print("Lobby: Server created")
	is_connected = true
	# Add host to player list
	var host_id = multiplayer.get_unique_id()
	players[host_id] = {
		"id": host_id,
		"name": "Host",
		"ready": false
	}
	_show_lobby_ui()
	_update_lobby_ui()

func _on_server_joined():
	print("Lobby: Joined server")
	is_connected = true
	# Request current player list from server
	if not multiplayer.is_server():
		rpc_id(1, "_request_player_list")
	_show_lobby_ui()

func _on_server_left():
	print("Lobby: Left server")
	is_connected = false
	# Return to main menu or show connection UI
	players.clear()
	_show_connection_ui()
	_update_lobby_ui()

func _on_connection_failed():
	print("Lobby: Connection failed")
	# Show error and return to connection UI
	status_label.text = "Connection failed!"
	_show_connection_ui()

func _on_peer_connected(id: int):
	print("Lobby: Peer connected: ", id)
	# Server adds new player to list
	if multiplayer.is_server():
		players[id] = {
			"id": id,
			"name": "Player " + str(id),
			"ready": false
		}
		_update_lobby_ui()
		# Send updated player list to all clients
		_sync_player_list()

func _on_peer_disconnected(id: int):
	print("Lobby: Peer disconnected: ", id)
	# Remove player from list
	if id in players:
		players.erase(id)
	_update_lobby_ui()
	# Send updated player list to all clients
	if multiplayer.is_server():
		_sync_player_list()

func _on_multiplayer_peer_connected(id: int):
	print("Lobby: Multiplayer peer connected: ", id)

func _on_multiplayer_peer_disconnected(id: int):
	print("Lobby: Multiplayer peer disconnected: ", id)

func _on_ready_pressed():
	local_player_ready = !local_player_ready
	ready_button.text = "Unready" if local_player_ready else "Ready"
	
	# Send ready state to server
	if multiplayer.is_server():
		players[multiplayer.get_unique_id()]["ready"] = local_player_ready
		_update_lobby_ui()
		_check_all_ready()
	else:
		rpc_id(1, "_set_player_ready", local_player_ready)

func _on_start_game_pressed():
	if multiplayer.is_server():
		# Start the game
		rpc("_start_game")
		_start_game_local()

func _on_leave_lobby_pressed():
	# Disconnect from server
	if network_handler:
		network_handler.stop_connection()
	# Reset state
	is_connected = false
	players.clear()
	local_player_ready = false
	# Show connection UI
	_show_connection_ui()
	_update_lobby_ui()

func _update_lobby_ui():
	# Clear player list
	for child in player_list_container.get_children():
		child.queue_free()
	
	# Add players to list
	for player_id in players:
		var player_info = players[player_id]
		var player_label = Label.new()
		var status_text = "Ready" if player_info["ready"] else "Not Ready"
		player_label.text = player_info["name"] + " - " + status_text
		player_label.modulate = Color.GREEN if player_info["ready"] else Color.RED
		player_list_container.add_child(player_label)
	
	# Update start game button
	if multiplayer.is_server():
		var all_ready = _check_all_ready()
		start_game_button.disabled = not all_ready or players.size() < 1
		start_game_button.visible = true
	else:
		start_game_button.visible = false
	
	# Update status
	var ready_count = 0
	for player_id in players:
		if players[player_id]["ready"]:
			ready_count += 1
	
	status_label.text = "Players: %d | Ready: %d/%d" % [players.size(), ready_count, players.size()]

func _check_all_ready() -> bool:
	if players.size() < 1:
		return false
	
	for player_id in players:
		if not players[player_id]["ready"]:
			return false
	return true

func _sync_player_list():
	# Send player list to all clients
	for peer_id in multiplayer.get_peers():
		rpc_id(peer_id, "_receive_player_list", players)

@rpc("any_peer", "reliable")
func _request_player_list():
	# Server sends player list to requesting client
	if multiplayer.is_server():
		rpc_id(multiplayer.get_remote_sender_id(), "_receive_player_list", players)

@rpc("any_peer", "reliable")
func _receive_player_list(player_list: Dictionary):
	# Client receives player list from server
	players = player_list
	_update_lobby_ui()

@rpc("any_peer", "reliable")
func _set_player_ready(ready: bool):
	# Server receives ready state from client
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		if sender_id in players:
			players[sender_id]["ready"] = ready
			_update_lobby_ui()
			_check_all_ready()

@rpc("any_peer", "reliable")
func _start_game():
	# All clients start the game
	print("Lobby: Starting game!")
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _start_game_local():
	# Local start game function
	print("Lobby: Starting game locally!")
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

# Connection UI functions
func _show_connection_ui():
	if multiplayer_ui:
		multiplayer_ui.visible = true
	# Hide lobby controls
	if ready_button:
		ready_button.visible = false
	if start_game_button:
		start_game_button.visible = false
	if leave_lobby_button:
		leave_lobby_button.visible = false
	if player_list_container and player_list_container.get_parent():
		player_list_container.get_parent().visible = false

func _show_lobby_ui():
	if multiplayer_ui:
		multiplayer_ui.visible = false
	# Show lobby controls
	if ready_button:
		ready_button.visible = true
	if start_game_button:
		start_game_button.visible = true
	if leave_lobby_button:
		leave_lobby_button.visible = true
	if player_list_container and player_list_container.get_parent():
		player_list_container.get_parent().visible = true

func _on_refresh_pressed():
	print("Lobby: Refreshing server list")
	discovered_servers.clear()
	if server_list:
		server_list.clear()
	if network_handler:
		network_handler.start_client_discovery()

func _on_join_pressed():
	if not server_list:
		print("Lobby: Server list not available")
		return
		
	var selected_indices = server_list.get_selected_items()
	if selected_indices.size() == 0:
		print("Lobby: No server selected")
		return
	
	var server_index = selected_indices[0]
	if server_index >= discovered_servers.size():
		print("Lobby: Invalid server index")
		return
	
	var server_info = discovered_servers[server_index]
	print("Lobby: Joining server: ", server_info)
	if network_handler:
		network_handler.start_client(server_info.get("ip", "127.0.0.1"), server_info.get("port", 42069))

func _on_direct_connect_pressed():
	var ip = "127.0.0.1"
	var port = 42069
	
	if ip_input:
		ip = ip_input.text.strip_edges()
		if ip.is_empty():
			ip = "127.0.0.1"
	
	if port_input:
		var port_text = port_input.text.strip_edges()
		if not port_text.is_empty():
			port = port_text.to_int()
	
	print("Lobby: Direct connecting to ", ip, ":", port)
	if network_handler:
		network_handler.start_client(ip, port)

func _on_host_pressed():
	print("Lobby: _on_host_pressed() called!")
	print("Lobby: Hosting server")
	if network_handler:
		print("Lobby: Network handler exists, calling start_server() directly")
		network_handler.start_server()
	else:
		print("Lobby: Network handler is null in _on_host_pressed()")

func _on_server_selected(index: int):
	if join_button:
		join_button.disabled = false

func _on_server_discovered(server_info: Dictionary):
	print("Lobby: Server discovered: ", server_info)
	discovered_servers.append(server_info)
	_update_server_list()

func _on_servers_updated():
	_update_server_list()

func _update_server_list():
	if not server_list:
		return
		
	server_list.clear()
	for server in discovered_servers:
		var server_name = server.get("name", "Unknown Server")
		var player_count = server.get("players", 0)
		var max_players = server.get("max_players", 8)
		var ip = server.get("ip", "Unknown")
		var port = server.get("port", 42069)
		
		var display_text = "%s (%d/%d) - %s:%d" % [server_name, player_count, max_players, ip, port]
		server_list.add_item(display_text)
	
	if join_button:
		join_button.disabled = true

# Deferred functions to ensure proper timing
func _start_server_deferred():
	print("Lobby: _start_server_deferred called")
	if network_handler:
		print("Lobby: Network handler found, calling start_server()")
		network_handler.start_server()
	else:
		print("Lobby: Network handler is null!")

func _start_client_deferred(ip: String, port: int):
	print("Lobby: _start_client_deferred called with ", ip, ":", port)
	if network_handler:
		print("Lobby: Network handler found, calling start_client()")
		network_handler.start_client(ip, port)
	else:
		print("Lobby: Network handler is null!")

func _disable_ui_script_signals():
	# Disconnect the high_level_ui script's signal connections to prevent conflicts
	# The high_level_ui script has its own signal connections that conflict with ours
	print("Lobby: Disabling UI script signal connections to prevent conflicts")
	
	# We can't easily disconnect signals from another script, so we'll just log this
	# The main issue is that both scripts are handling the same button press
