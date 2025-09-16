extends Node

## Achievement Test Script
## Use this script to test the achievement system

@export var test_interval: float = 3.0
var test_timer: Timer

func _ready() -> void:
	# Set up GameManager integration
	if GameManager:
		GameManager.change_game_state(GameManager.GameState.PLAYING)
		GameManager.recreate_pause_menu_for_scene()
	
	# Create a timer to test achievements
	test_timer = Timer.new()
	test_timer.wait_time = test_interval
	test_timer.timeout.connect(_test_achievement)
	add_child(test_timer)
	
	# Start testing after a short delay
	await get_tree().create_timer(2.0).timeout
	test_timer.start()
	
	print("Achievement test script loaded. Press F1-F7 to test specific achievements.")

## Test different achievements
func _test_achievement() -> void:
	if not AchievementManager:
		print("AchievementManager not found!")
		return
	
	var test_cases = [
		{"id": "first_dig", "type": "unlock"},
		{"id": "dig_10_blocks", "type": "increment", "value": 5},
		{"id": "first_wood", "type": "unlock"},
		{"id": "first_stone", "type": "unlock"},
		{"id": "first_cave", "type": "unlock"}
	]
	
	var current_test = test_cases[test_timer.timeout.get_connections().size() % test_cases.size()]
	
	match current_test.type:
		"unlock":
			AchievementManager.unlock(current_test.id)
		"increment":
			var value = current_test.get("value", 1.0)
			AchievementManager.increment(current_test.id, value)

## Manual test functions that can be called from the editor or other scripts

func test_first_dig() -> void:
	"""Test the first dig achievement"""
	if AchievementManager:
		AchievementManager.unlock("first_dig")
		print("Testing first_dig achievement")

func test_digging_progress() -> void:
	"""Test digging progress achievements"""
	if AchievementManager:
		AchievementManager.increment("dig_10_blocks", 5)
		AchievementManager.increment("dig_100_blocks", 5)
		AchievementManager.increment("dig_1000_blocks", 5)
		print("Testing digging progress achievements")

func test_first_wood() -> void:
	"""Test the first wood achievement"""
	if AchievementManager:
		AchievementManager.unlock("first_wood")
		print("Testing first_wood achievement")

func test_first_stone() -> void:
	"""Test the first stone achievement"""
	if AchievementManager:
		AchievementManager.unlock("first_stone")
		print("Testing first_stone achievement")

func test_first_cave() -> void:
	"""Test the first cave achievement"""
	if AchievementManager:
		AchievementManager.unlock("first_cave")
		print("Testing first_cave achievement")

func show_achievements_menu() -> void:
	"""Show the achievements menu"""
	if GameManager:
		GameManager.open_achievements()
		print("Showing achievements menu")

func reset_achievements() -> void:
	"""Reset all achievements"""
	if AchievementManager:
		AchievementManager.reset_achievements()
		print("All achievements reset")

## Input handling for testing
func _input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	
	match event.keycode:
		KEY_F1:
			test_first_dig()
		KEY_F2:
			test_digging_progress()
		KEY_F3:
			test_first_wood()
		KEY_F4:
			test_first_stone()
		KEY_F5:
			test_first_cave()
		KEY_F6:
			show_achievements_menu()
		KEY_F7:
			reset_achievements()
