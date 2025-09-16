extends Node

const AUTO_SAVE_INTERVAL = 60.0  # Save every 60 seconds
var auto_save_timer: Timer
var auto_save_enabled: bool = true

func _ready():
	# Create auto-save timer
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)
	
	# Load auto-save setting
	load_auto_save_setting()

func start_auto_save():
	"""Start the auto-save timer"""
	if auto_save_enabled:
		auto_save_timer.start()
		print("Auto-save started")

func stop_auto_save():
	"""Stop the auto-save timer"""
	auto_save_timer.stop()
	print("Auto-save stopped")

func _on_auto_save_timer_timeout():
	"""Called when auto-save timer expires"""
	if auto_save_enabled and GameManager.get_current_state() == GameManager.GameState.PLAYING:
		if SaveSystemIntegration:
			SaveSystemIntegration.save_current_game()
			print("Auto-save completed")
		else:
			print("ERROR: SaveSystemIntegration not available for auto-save!")

func set_auto_save_enabled(enabled: bool):
	"""Enable or disable auto-save"""
	auto_save_enabled = enabled
	ConfigFileHandler.save_gameplay_setting("auto_save", enabled)
	
	if enabled:
		start_auto_save()
	else:
		stop_auto_save()

func load_auto_save_setting():
	"""Load auto-save setting from config"""
	var gameplay_settings = ConfigFileHandler.load_gameplay_settings()
	auto_save_enabled = gameplay_settings.get("auto_save", true)

func force_save():
	"""Force an immediate save"""
	if GameManager.get_current_state() == GameManager.GameState.PLAYING:
		if SaveSystemIntegration:
			SaveSystemIntegration.save_current_game()
			print("Force save completed")
		else:
			print("ERROR: SaveSystemIntegration not available for force save!")
