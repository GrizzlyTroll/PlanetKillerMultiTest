extends Node

const DEFAULT_PORT: int = 42069
const MAX_PLAYERS: int = 8

var peer: ENetMultiplayerPeer
var server_info: Dictionary = {}
var discovered_servers: Array[Dictionary] = []
var discovery_server: UDPServer
var discovery_client: PacketPeerUDP

signal server_created
signal server_joined
signal server_left
signal connection_failed
signal server_discovered(server_info: Dictionary)
signal servers_updated
signal peer_connected(id: int)
signal peer_disconnected(id: int)

func _ready():
	# Add to group for easy finding
	add_to_group("network_handler")
	
	# Wait for the next frame to ensure multiplayer API is ready
	await get_tree().process_frame
	_setup_multiplayer_signals()

func _setup_multiplayer_signals():
	# Set up multiplayer connection signals with null check
	if multiplayer:
		multiplayer.connected_to_server.connect(_on_connected_to_server)
		multiplayer.connection_failed.connect(_on_connection_failed)
		multiplayer.server_disconnected.connect(_on_server_disconnected)
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		print("Multiplayer signals connected successfully")
	else:
		print("Error: Multiplayer API still not available after frame delay")

func start_server(port: int = DEFAULT_PORT) -> void:
	# Check if multiplayer API is available
	print("NetworkHandler: start_server called, checking multiplayer API...")
	print("NetworkHandler: multiplayer = ", multiplayer)
	print("NetworkHandler: is_inside_tree() = ", is_inside_tree())
	print("NetworkHandler: get_tree() = ", get_tree())
	
	# Check if server is already running
	if peer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		print("NetworkHandler: Server already running, ignoring duplicate start_server call")
		return
	
	if not multiplayer:
		print("Error: Multiplayer API not available")
		connection_failed.emit()
		return
	
	# Try multiple ports if the default is busy
	var ports_to_try = [port, port + 1, port + 2, port + 3, port + 4]
	var server_started = false
	
	for test_port in ports_to_try:
		peer = ENetMultiplayerPeer.new()
		var result = peer.create_server(test_port, MAX_PLAYERS)
		
		if result == OK:
			multiplayer.multiplayer_peer = peer
			server_info = {
				"name": "Planet Killer Server",
				"port": test_port,
				"players": 1,
				"max_players": MAX_PLAYERS,
				"map": "Main World"
			}
			start_server_discovery(test_port)
			server_created.emit()
			print("Server started on port: ", test_port)
			server_started = true
			break
		else:
			print("Failed to create server on port ", test_port, ": ", _get_error_message(result))
			peer = null
	
	if not server_started:
		print("Failed to create server on any port. All ports may be in use.")
		connection_failed.emit()

func _get_error_message(error_code: int) -> String:
	match error_code:
		1: return "FAILED - General failure"
		2: return "UNAVAILABLE - Resource unavailable"
		3: return "UNCONFIGURED - Resource not configured"
		4: return "UNAUTHORIZED - Not authorized"
		5: return "PARAMETER_RANGE_ERROR - Parameter out of range"
		6: return "OUT_OF_MEMORY - Out of memory"
		7: return "FILE_NOT_FOUND - File not found"
		8: return "FILE_BAD_DRIVE - Bad drive"
		9: return "FILE_BAD_PATH - Bad path"
		10: return "FILE_NO_PERMISSION - No permission"
		11: return "FILE_ALREADY_IN_USE - File already in use"
		12: return "FILE_CANT_OPEN - Can't open file"
		13: return "FILE_CANT_WRITE - Can't write file"
		14: return "FILE_CANT_READ - Can't read file"
		15: return "FILE_UNRECOGNIZED - Unrecognized file"
		16: return "FILE_CORRUPT - Corrupt file"
		17: return "FILE_MISSING_DEPENDENCIES - Missing dependencies"
		18: return "FILE_EOF - End of file"
		19: return "CANT_OPEN - Can't open"
		20: return "CANT_CREATE - Can't create"
		21: return "QUERY_FAILED - Query failed"
		22: return "ALREADY_IN_USE - Already in use"
		23: return "LOCKED - Locked"
		24: return "TIMEOUT - Timeout"
		25: return "CANT_CONNECT - Can't connect"
		26: return "CANT_RESOLVE - Can't resolve"
		27: return "CONNECTION_ERROR - Connection error"
		28: return "CANT_ACQUIRE_RESOURCE - Can't acquire resource"
		29: return "CANT_FORK - Can't fork"
		30: return "INVALID_DATA - Invalid data"
		31: return "INVALID_PARAMETER - Invalid parameter"
		32: return "ALREADY_EXISTS - Already exists"
		33: return "DOES_NOT_EXIST - Does not exist"
		34: return "DATABASE_CANT_READ - Database can't read"
		35: return "DATABASE_CANT_WRITE - Database can't write"
		36: return "COMPILATION_FAILED - Compilation failed"
		37: return "METHOD_NOT_FOUND - Method not found"
		38: return "LINK_FAILED - Link failed"
		39: return "SCRIPT_FAILED - Script failed"
		40: return "CYCLIC_LINK - Cyclic link"
		41: return "INVALID_DECLARATION - Invalid declaration"
		42: return "DUPLICATE_SYMBOL - Duplicate symbol"
		43: return "PARSE_ERROR - Parse error"
		44: return "BUSY - Busy"
		45: return "SKIP - Skip"
		46: return "HELP - Help"
		47: return "BUG - Bug"
		48: return "PRINTER_ON_FIRE - Printer on fire"
		_: return "UNKNOWN_ERROR (" + str(error_code) + ")"

func start_client(ip_address: String = "localhost", port: int = DEFAULT_PORT) -> void:
	# Check if multiplayer API is available
	if not multiplayer:
		print("Error: Multiplayer API not available")
		connection_failed.emit()
		return
	
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip_address, port)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("Connecting to server: ", ip_address, ":", port)
	else:
		print("Failed to create client: ", _get_error_message(result))
		connection_failed.emit()

func stop_connection() -> void:
	if peer:
		peer.close()
		if multiplayer:
			multiplayer.multiplayer_peer = null
		peer = null
	
	stop_server_discovery()
	discovered_servers.clear()
	servers_updated.emit()
	print("Connection stopped")

func check_port_availability(port: int) -> bool:
	var test_peer = ENetMultiplayerPeer.new()
	var result = test_peer.create_server(port, 1)
	test_peer.close()
	return result == OK

func start_server_discovery(port: int) -> void:
	discovery_server = UDPServer.new()
	discovery_server.listen(port + 1, "0.0.0.0")
	print("Server discovery started on port: ", port + 1)

func stop_server_discovery() -> void:
	if discovery_server:
		discovery_server.stop()
		discovery_server = null

func start_client_discovery() -> void:
	discovery_client = PacketPeerUDP.new()
	discovery_client.bind(DEFAULT_PORT + 1)
	
	# Send discovery broadcast
	var discovery_packet = JSON.stringify({"type": "discovery_request"})
	discovery_client.set_dest_address("255.255.255.255", DEFAULT_PORT + 1)
	discovery_client.put_packet(discovery_packet.to_utf8_buffer())
	
	print("Client discovery started")

func stop_client_discovery() -> void:
	if discovery_client:
		discovery_client.close()
		discovery_client = null

func _process(_delta):
	# Handle server discovery
	if discovery_server:
		discovery_server.poll()
		if discovery_server.is_connection_available():
			var client = discovery_server.take_connection()
			var packet = client.get_packet()
			var data = JSON.parse_string(packet.get_string_from_utf8())
			
			if data and data.get("type") == "discovery_request":
				# Send server info back
				var response = JSON.stringify({
					"type": "discovery_response",
					"server_info": server_info
				})
				client.put_packet(response.to_utf8_buffer())
	
	# Handle client discovery
	if discovery_client:
		if discovery_client.get_available_packet_count() > 0:
			var packet = discovery_client.get_packet()
			var data = JSON.parse_string(packet.get_string_from_utf8())
			
			if data and data.get("type") == "discovery_response":
				var server_info = data.get("server_info")
				if server_info:
					# Add IP address to server info
					server_info["ip"] = discovery_client.get_packet_ip()
					
					# Check if server already exists
					var exists = false
					for server in discovered_servers:
						if server.get("port") == server_info.get("port") and server.get("ip") == server_info.get("ip"):
							exists = true
							break
					
					if not exists:
						discovered_servers.append(server_info)
						server_discovered.emit(server_info)
						servers_updated.emit()

func get_discovered_servers() -> Array[Dictionary]:
	return discovered_servers

func is_server() -> bool:
	return multiplayer.is_server()

func is_client() -> bool:
	return multiplayer.is_client() and not multiplayer.is_server()

func get_player_count() -> int:
	if is_server():
		return multiplayer.get_peers().size() + 1  # +1 for server
	return 0

# Multiplayer event handlers
func _on_connected_to_server():
	print("Successfully connected to server")
	server_joined.emit()

func _on_connection_failed():
	print("Failed to connect to server")
	connection_failed.emit()

func _on_server_disconnected():
	print("Disconnected from server")
	server_left.emit()

func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	if is_server():
		server_info["players"] = get_player_count()
	peer_connected.emit(id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	if is_server():
		server_info["players"] = get_player_count()
	peer_disconnected.emit(id)
