extends Node

## AchievementManager - Global singleton for managing achievements
## Handles unlocking, progress tracking, and persistence of achievements

signal achievement_unlocked(achievement_id: String, achievement_data: Dictionary)
signal achievement_progress_updated(achievement_id: String, progress: float)

# Achievement data structure
class AchievementData:
	var id: String
	var title: String
	var description: String
	var unlocked: bool = false
	var progress: float = 0.0  # 0.0 to 1.0 for incremental achievements
	var icon_locked: String = ""  # Path to locked icon
	var icon_unlocked: String = ""  # Path to unlocked icon
	var max_progress: float = 1.0  # For incremental achievements
	
	func _init(p_id: String, p_title: String, p_description: String, p_icon_locked: String = "", p_icon_unlocked: String = "", p_max_progress: float = 1.0):
		id = p_id
		title = p_title
		description = p_description
		icon_locked = p_icon_locked
		icon_unlocked = p_icon_unlocked
		max_progress = p_max_progress

# Dictionary to store all achievements
var achievements: Dictionary = {}

# Save file path
const SAVE_FILE_PATH = "user://achievements.save"

func _ready() -> void:
	# Ensure this singleton processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Initialize default achievements
	_initialize_achievements()
	
	# Only load from JSON file if we're not using the per-world save system
	# The per-world save system will load achievements via _apply_achievement_data_to_game()
	if not SaveSystemIntegration:
		load_achievements()
	else:
		print("DEBUG: Using per-world save system, skipping JSON achievement load")

## Initialize default achievements
func _initialize_achievements() -> void:
	# First steps achievements
	achievements["first_dig"] = AchievementData.new(
		"first_dig",
		"First Dig",
		"Dig your first block",
		"res://Assets/Icons/HotBarSlot.png",  # Placeholder icon
		"res://Assets/Icons/HotBarIcon.png"   # Placeholder icon
	)
	
	achievements["first_wood"] = AchievementData.new(
		"first_wood",
		"Wood Collector",
		"Collect your first piece of wood",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png"
	)
	
	achievements["first_stone"] = AchievementData.new(
		"first_stone",
		"Stone Mason",
		"Collect your first piece of stone",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png"
	)
	
	# Digging milestones
	achievements["dig_10_blocks"] = AchievementData.new(
		"dig_10_blocks",
		"Novice Digger",
		"Dig 10 blocks",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png",
		10.0
	)
	
	achievements["dig_100_blocks"] = AchievementData.new(
		"dig_100_blocks",
		"Experienced Digger",
		"Dig 100 blocks",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png",
		100.0
	)
	
	achievements["dig_1000_blocks"] = AchievementData.new(
		"dig_1000_blocks",
		"Master Digger",
		"Dig 1000 blocks",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png",
		1000.0
	)
	
	# Exploration achievements
	achievements["first_cave"] = AchievementData.new(
		"first_cave",
		"Cave Explorer",
		"Enter your first cave",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png"
	)
	
	achievements["deep_digger"] = AchievementData.new(
		"deep_digger",
		"Deep Digger",
		"Dig 50 blocks deep",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png",
		50.0
	)
	
	# Combat achievements
	achievements["first_kill"] = AchievementData.new(
		"first_kill",
		"First Blood",
		"Defeat your first enemy",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png"
	)
	
	achievements["kill_10_enemies"] = AchievementData.new(
		"kill_10_enemies",
		"Enemy Hunter",
		"Defeat 10 enemies",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png",
		10.0
	)
	
	# Item achievements
	achievements["craft_first_item"] = AchievementData.new(
		"craft_first_item",
		"Craftsman",
		"Craft your first item",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png"
	)
	
	achievements["collect_all_tools"] = AchievementData.new(
		"collect_all_tools",
		"Tool Collector",
		"Collect all basic tools (axe, shovel, drill)",
		"res://Assets/Icons/HotBarSlot.png",
		"res://Assets/Icons/HotBarIcon.png"
	)

## Unlock an achievement
func unlock(achievement_id: String) -> bool:
	print("🎮 AchievementManager.unlock called with ID: " + achievement_id)
	return unlock_silent(achievement_id, true)

## Unlock an achievement silently (without showing toast)
func unlock_silent(achievement_id: String, show_toast: bool = true) -> bool:
	print("🔧 AchievementManager.unlock_silent called with ID: " + achievement_id + " show_toast: " + str(show_toast))
	
	if not achievements.has(achievement_id):
		push_warning("Achievement ID not found: " + achievement_id)
		print("❌ Achievement ID not found: " + achievement_id)
		return false
	
	var achievement = achievements[achievement_id]
	if achievement.unlocked:
		print("ℹ️ Achievement already unlocked: " + achievement_id)
		return false  # Already unlocked
	
	print("✅ Unlocking achievement: " + achievement.title)
	achievement.unlocked = true
	achievement.progress = achievement.max_progress
	
	# Emit signal
	print("📡 Emitting achievement_unlocked signal...")
	achievement_unlocked.emit(achievement_id, _achievement_to_dict(achievement))
	
	# Show toast notification only if requested
	if show_toast:
		print("🎬 Calling _show_achievement_toast...")
		_show_achievement_toast(achievement)
	else:
		print("🔇 Skipping toast notification (silent unlock)")
	
	# Save achievements
	print("💾 Saving achievements...")
	save_achievements()
	
	print("✅ Achievement unlocked successfully: " + achievement.title)
	return true

## Increment progress toward an achievement
func increment(achievement_id: String, value: float = 1.0) -> bool:
	print("📊 AchievementManager.increment called with ID: " + achievement_id + " value: " + str(value))
	
	if not achievements.has(achievement_id):
		push_warning("Achievement ID not found: " + achievement_id)
		print("❌ Achievement ID not found: " + achievement_id)
		return false
	
	var achievement = achievements[achievement_id]
	if achievement.unlocked:
		print("ℹ️ Achievement already unlocked: " + achievement_id)
		return false  # Already unlocked
	
	print("📈 Updating progress for: " + achievement.title + " from " + str(achievement.progress) + " to " + str(achievement.progress + value))
	achievement.progress += value
	
	# Emit progress signal
	print("📡 Emitting achievement_progress_updated signal...")
	achievement_progress_updated.emit(achievement_id, achievement.progress)
	
	# Check if achievement should be unlocked
	if achievement.progress >= achievement.max_progress:
		print("🎯 Achievement progress reached max, unlocking: " + achievement_id)
		unlock(achievement_id)
		return true
	
	# Save achievements
	print("💾 Saving achievements after increment...")
	save_achievements()
	print("✅ Increment completed for: " + achievement_id)
	return false

## Check if an achievement is unlocked
func is_unlocked(achievement_id: String) -> bool:
	if not achievements.has(achievement_id):
		return false
	return achievements[achievement_id].unlocked

## Get achievement data
func get_achievement(achievement_id: String) -> Dictionary:
	if not achievements.has(achievement_id):
		return {}
	
	return _achievement_to_dict(achievements[achievement_id])

## Get all achievements
func get_all_achievements() -> Dictionary:
	var result = {}
	for id in achievements:
		result[id] = _achievement_to_dict(achievements[id])
	return result

## Get unlocked achievements count
func get_unlocked_count() -> int:
	var count = 0
	for achievement in achievements.values():
		if achievement.unlocked:
			count += 1
	return count

## Get total achievements count
func get_total_count() -> int:
	return achievements.size()

## Get achievement progress as percentage
func get_progress_percentage(achievement_id: String) -> float:
	if not achievements.has(achievement_id):
		return 0.0
	
	var achievement = achievements[achievement_id]
	if achievement.max_progress <= 0:
		return 0.0
	
	return (achievement.progress / achievement.max_progress) * 100.0

## Set achievement progress directly
func set_achievement_progress(achievement_id: String, progress: float, max_progress: float = 1.0) -> void:
	"""Set achievement progress directly (used by save system)"""
	if not achievements.has(achievement_id):
		print("ERROR: Achievement not found: " + achievement_id)
		return
	
	var achievement = achievements[achievement_id]
	achievement.progress = progress
	achievement.max_progress = max_progress
	
	# Check if achievement should be unlocked
	if achievement.progress >= achievement.max_progress and not achievement.unlocked:
		print("🎯 Achievement progress reached max, unlocking silently: " + achievement_id)
		unlock_silent(achievement_id, false)  # Silent unlock when loading from save
		return  # unlock_silent already saves achievements
	
	# Emit progress signal
	achievement_progress_updated.emit(achievement_id, achievement.progress)
	
	# Save achievements
	save_achievements()

## Unlock achievement (alias for unlock function for save system compatibility)
func unlock_achievement(achievement_id: String) -> bool:
	"""Unlock achievement (used by save system) - silent unlock to avoid toast replay"""
	return unlock_silent(achievement_id, false)

## Save achievements to file
func save_achievements() -> void:
	# Only save to JSON file if we're not using the per-world save system
	if SaveSystemIntegration:
		# The per-world save system handles saving via the database
		print("DEBUG: Using per-world save system, skipping JSON achievement save")
		return
	
	var save_data = {}
	
	for id in achievements:
		var achievement = achievements[id]
		save_data[id] = {
			"unlocked": achievement.unlocked,
			"progress": achievement.progress
		}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Achievements saved successfully")
	else:
		push_error("Failed to save achievements")

## Load achievements from file
func load_achievements() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No achievement save file found, using defaults")
		return
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("Failed to open achievement save file")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse achievement save file")
		return
	
	var save_data = json.data
	
	for id in save_data:
		if achievements.has(id):
			var achievement = achievements[id]
			var data = save_data[id]
			
			if data.has("unlocked"):
				achievement.unlocked = data.unlocked
			if data.has("progress"):
				achievement.progress = data.progress
	
	print("Achievements loaded successfully")

## Reset all achievements (for testing and new worlds)
func reset_achievements() -> void:
	for achievement in achievements.values():
		achievement.unlocked = false
		achievement.progress = 0.0
	print("DEBUG: All achievements reset to default state")

## Reset all achievements (for testing)
func reset_achievements_for_testing() -> void:
	for achievement in achievements.values():
		achievement.unlocked = false
		achievement.progress = 0.0
	
	save_achievements()
	print("All achievements reset")

## Convert AchievementData to Dictionary for signals
func _achievement_to_dict(achievement: AchievementData) -> Dictionary:
	return {
		"id": achievement.id,
		"title": achievement.title,
		"description": achievement.description,
		"unlocked": achievement.unlocked,
		"progress": achievement.progress,
		"max_progress": achievement.max_progress,
		"icon_locked": achievement.icon_locked,
		"icon_unlocked": achievement.icon_unlocked,
		"progress_percentage": get_progress_percentage(achievement.id)
	}

## Show achievement unlock toast notification
func _show_achievement_toast(achievement: AchievementData) -> void:
	print("🎯 Attempting to show achievement toast for: " + achievement.title)
	
	# Use the existing toast system
	if ToastManager:
		print("✅ ToastManager found, trying to show achievement toast")
		
		# Use the simplified toast API for achievements
		print("✅ Using simplified toast API for achievement")
		ToastManager.show_success(
			"Achievement Unlocked!",
			achievement.title + "\n" + achievement.description,
			5.0
		)
	else:
		print("❌ ToastManager not found, using console fallback")
		# Fallback if toast system is not available
		print("🎉 ACHIEVEMENT UNLOCKED: " + achievement.title + " - " + achievement.description)
