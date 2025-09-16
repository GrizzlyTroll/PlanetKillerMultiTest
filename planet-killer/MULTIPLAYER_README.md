# Planet Killer - Multiplayer LAN System

## Overview
This multiplayer system allows players to connect over a local area network (LAN) to play Planet Killer together. The system includes server discovery, direct connection options, and synchronized gameplay.

## Features
- **LAN Server Discovery**: Automatically finds servers on your local network
- **Direct Connection**: Connect directly to a server using IP address and port
- **Host Server**: Create your own server for others to join
- **Player Synchronization**: Real-time position, health, and animation sync
- **Network Authority**: Each player controls their own character

## How to Test

### Method 1: Using the Test Scene
1. Open the project in Godot
2. Run the `MultiplayerTest.tscn` scene
3. Follow the on-screen instructions

### Method 2: Using the Main Game
1. Run the main game scene (`game.tscn`)
2. Press the multiplayer menu key (default: check input map)
3. Use the multiplayer UI to host or join

### Testing Steps

#### Host a Server:
1. Click "Host Server" button
2. The game will create a server on port 42069
3. Other players can now discover and join your server

#### Join a Server:
1. Click "Refresh" to search for available servers
2. Select a server from the list
3. Click "Join Server"

#### Direct Connect:
1. Enter the server's IP address (e.g., 192.168.1.100)
2. Enter the port (default: 42069)
3. Click "Connect"

## Network Configuration

### Default Settings:
- **Port**: 42069
- **Discovery Port**: 42070 (Port + 1)
- **Max Players**: 8
- **Protocol**: ENet (UDP)

### Firewall Considerations:
- Ensure port 42069 is open for game traffic
- Ensure port 42070 is open for server discovery
- Windows Firewall may need to allow Godot through

## Troubleshooting

### Common Issues:

1. **"No servers found"**
   - Check if the host has started a server
   - Verify both players are on the same network
   - Check firewall settings

2. **"Connection failed"**
   - Verify the IP address is correct
   - Check if the port is available
   - Ensure firewall allows the connection

3. **Players not moving**
   - Check network authority is set correctly
   - Verify RPC functions are working
   - Check console for error messages

### Debug Information:
- Check the Godot console for network messages
- Look for "Server created", "Peer connected", etc.
- Monitor network traffic if needed

## Technical Details

### Network Architecture:
- **Server-Client Model**: One player hosts, others connect
- **Authority System**: Each player controls their own character
- **RPC Synchronization**: Position, health, and animations sync via RPC calls

### Key Components:
- `highlevelnetworkhandler.gd`: Core networking logic
- `high_level_ui.gd`: Multiplayer lobby interface
- `player.gd`: Player synchronization and authority
- `game.gd`: Game scene multiplayer integration

### RPC Functions:
- `_update_player_position()`: Syncs player position and velocity
- `_update_player_health()`: Syncs player health
- `_update_player_animation()`: Syncs animation state
- `_sync_damage()`: Syncs damage between players

## Development Notes

### Adding New Features:
1. Add RPC functions for new synchronized data
2. Update authority checks in player script
3. Test with multiple clients

### Performance Considerations:
- Use `rpc_unreliable` for frequent updates (position)
- Use `rpc` for important updates (health, damage)
- Consider bandwidth limitations for mobile devices

## Future Enhancements:
- Chat system
- Player names and customization
- Server password protection
- Spectator mode
- Replay system
