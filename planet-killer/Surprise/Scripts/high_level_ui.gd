extends Control

@onready var server_list: ItemList = $VBoxContainer/ServerBrowser/ServerList
@onready var refresh_button: Button = $VBoxContainer/ServerBrowser/ServerBrowserButtons/RefreshButton
@onready var join_button: Button = $VBoxContainer/ServerBrowser/ServerBrowserButtons/JoinButton
@onready var host_button: Button = $VBoxContainer/Host
@onready var direct_connect_button: Button = $VBoxContainer/DirectConnect/DirectConnectButton
@onready var ip_input: LineEdit = $VBoxContainer/DirectConnect/IPInput
@onready var port_input: LineEdit = $VBoxContainer/DirectConnect/PortInput
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var player_count_label: Label = $VBoxContainer/PlayerCountLabel

var selected_server: Dictionary = {}
var network_handler: Node

func _ready():
	# Find the network handler in the scene
	network_handler = get_node("/root/Game/MultiplayerNodes/NetworkHandler")
	if not network_handler:
		# Try alternative paths
		network_handler = get_node("../MultiplayerNodes/NetworkHandler")
	if not network_handler:
		# Try finding it in the current scene
		network_handler = get_node("../Game/MultiplayerNodes/NetworkHandler")
	if not network_handler:
		# Try finding it by searching the scene tree
		network_handler = get_tree().get_first_node_in_group("network_handler")
	
	if network_handler:
		# Connect network handler signals
		network_handler.server_created.connect(_on_server_created)
		network_handler.server_joined.connect(_on_server_joined)
		network_handler.server_left.connect(_on_server_left)
		network_handler.connection_failed.connect(_on_connection_failed)
		network_handler.server_discovered.connect(_on_server_discovered)
		network_handler.servers_updated.connect(_on_servers_updated)
	else:
		print("Warning: Network handler not found!")
	
	# Connect UI signals
	refresh_button.pressed.connect(_on_refresh_pressed)
	join_button.pressed.connect(_on_join_pressed)
	server_list.item_selected.connect(_on_server_selected)
	
	# Set default values
	if network_handler:
		port_input.text = str(network_handler.DEFAULT_PORT)
	ip_input.placeholder_text = "Enter IP address (e.g., 192.168.1.100)"
	
	# Start server discovery
	if network_handler:
		network_handler.start_client_discovery()
	
	# Update UI
	_update_ui()

func _on_server_pressed() -> void:
	status_label.text = "Starting server..."
	status_label.modulate = Color.YELLOW
	if network_handler:
		network_handler.start_server()
	# Don't hide immediately - wait for server_created signal

func _on_client_pressed() -> void:
	# This is now handled by the server browser
	pass

func _on_refresh_pressed() -> void:
	status_label.text = "Searching for servers..."
	status_label.modulate = Color.YELLOW
	if network_handler:
		network_handler.discovered_servers.clear()
	server_list.clear()
	if network_handler:
		network_handler.start_client_discovery()

func _on_join_pressed() -> void:
	if selected_server.is_empty():
		status_label.text = "Please select a server first!"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "Connecting to server..."
	status_label.modulate = Color.YELLOW
	if network_handler:
		var port = selected_server.get("port", network_handler.DEFAULT_PORT)
		network_handler.start_client(selected_server.get("ip", "localhost"), port)

func _on_direct_connect_pressed() -> void:
	var ip = ip_input.text.strip_edges()
	var port_text = port_input.text.strip_edges()
	
	if ip.is_empty():
		status_label.text = "Please enter an IP address!"
		status_label.modulate = Color.RED
		return
	
	if port_text.is_empty():
		status_label.text = "Please enter a port number!"
		status_label.modulate = Color.RED
		return
	
	var port = port_text.to_int()
	if port <= 0 or port > 65535:
		status_label.text = "Invalid port number!"
		status_label.modulate = Color.RED
		return
	
	status_label.text = "Connecting to " + ip + ":" + str(port) + "..."
	status_label.modulate = Color.YELLOW
	if network_handler:
		network_handler.start_client(ip, port)

func _on_server_selected(index: int) -> void:
	if network_handler and index >= 0 and index < network_handler.discovered_servers.size():
		selected_server = network_handler.discovered_servers[index]
		join_button.disabled = false
		_update_server_info()

func _on_server_created() -> void:
	status_label.text = "Server created successfully!"
	status_label.modulate = Color.GREEN
	# Go to lobby instead of hiding
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

func _on_server_joined() -> void:
	status_label.text = "Connected to server!"
	status_label.modulate = Color.GREEN
	# Go to lobby instead of hiding
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")

func _on_server_left() -> void:
	status_label.text = "Disconnected from server"
	status_label.modulate = Color.RED
	show()

func _on_connection_failed() -> void:
	status_label.text = "Failed to connect to server"
	status_label.modulate = Color.RED

func _on_server_discovered(server_info: Dictionary) -> void:
	_update_server_list()

func _on_servers_updated() -> void:
	_update_server_list()

func _update_server_list() -> void:
	server_list.clear()
	
	if network_handler:
		for server in network_handler.discovered_servers:
			var server_text = "%s (%d/%d players)" % [
				server.get("name", "Unknown Server"),
				server.get("players", 0),
				server.get("max_players", 8)
			]
			server_list.add_item(server_text)
		
		if network_handler.discovered_servers.is_empty():
			status_label.text = "No servers found. Try refreshing or host your own!"
			status_label.modulate = Color.WHITE
		else:
			status_label.text = "Found %d server(s)" % network_handler.discovered_servers.size()
			status_label.modulate = Color.GREEN

func _update_server_info() -> void:
	if not selected_server.is_empty():
		player_count_label.text = "Players: %d/%d" % [
			selected_server.get("players", 0),
			selected_server.get("max_players", 8)
		]
		player_count_label.visible = true
	else:
		player_count_label.visible = false

func _update_ui() -> void:
	join_button.disabled = true
	player_count_label.visible = false
	status_label.text = "Ready to connect"
	status_label.modulate = Color.WHITE

func _exit_tree():
	# Clean up when leaving the scene
	if network_handler:
		network_handler.stop_client_discovery()
