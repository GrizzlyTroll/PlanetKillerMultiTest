extends Control
class_name AchievementsMenu

## Achievements Menu - Displays all achievements in a scrollable list
## Shows achievement status, progress, and icons

signal achievements_menu_closed

@onready var scroll_container: ScrollContainer = $MainContainer/ContentPanel/VBoxContainer/ScrollContainer
@onready var achievements_container: VBoxContainer = $MainContainer/ContentPanel/VBoxContainer/ScrollContainer/AchievementsContainer
@onready var close_button: Button = $MainContainer/ContentPanel/VBoxContainer/Header/CloseButton
@onready var title_label: Label = $MainContainer/ContentPanel/VBoxContainer/Header/TitleLabel
@onready var progress_label: Label = $MainContainer/ContentPanel/VBoxContainer/Header/ProgressLabel

# Achievement item scene
var achievement_item_scene: PackedScene

func _ready() -> void:
	# Connect signals
	close_button.pressed.connect(_on_close_button_pressed)
	
	# Load achievement item scene
	achievement_item_scene = preload("res://Scenes/UI/AchievementItem.tscn")
	
	# Initially hide the menu
	hide()
	
	# Connect to achievement manager signals
	if AchievementManager:
		AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)
		AchievementManager.achievement_progress_updated.connect(_on_achievement_progress_updated)

## Show the achievements menu
func show_achievements_menu() -> void:
	show()
	_populate_achievements()
	_update_progress_display()

## Hide the achievements menu
func hide_achievements_menu() -> void:
	hide()
	achievements_menu_closed.emit()

## Populate the achievements list
func _populate_achievements() -> void:
	# Clear existing items
	for child in achievements_container.get_children():
		child.queue_free()
	
	# Get all achievements from AchievementManager
	if not AchievementManager:
		push_error("AchievementManager not found")
		return
	
	var all_achievements = AchievementManager.get_all_achievements()
	
	# Sort achievements by unlocked status and then by ID
	var sorted_achievements = []
	for id in all_achievements:
		sorted_achievements.append({"id": id, "data": all_achievements[id]})
	
	sorted_achievements.sort_custom(_sort_achievements)
	
	# Create achievement items
	for achievement_info in sorted_achievements:
		var achievement_item = achievement_item_scene.instantiate()
		if achievement_item:
			achievements_container.add_child(achievement_item)
			achievement_item.configure(achievement_info.data)

## Sort achievements (unlocked first, then by ID)
func _sort_achievements(a: Dictionary, b: Dictionary) -> bool:
	var a_unlocked = a.data.unlocked
	var b_unlocked = b.data.unlocked
	
	if a_unlocked != b_unlocked:
		return b_unlocked  # Unlocked achievements first
	
	return a.id < b.id  # Then sort by ID

## Update the progress display in the header
func _update_progress_display() -> void:
	if not AchievementManager:
		return
	
	var unlocked_count = AchievementManager.get_unlocked_count()
	var total_count = AchievementManager.get_total_count()
	var percentage = (float(unlocked_count) / float(total_count)) * 100.0
	
	progress_label.text = "Progress: %d/%d (%.1f%%)" % [unlocked_count, total_count, percentage]

## Handle close button press
func _on_close_button_pressed() -> void:
	hide_achievements_menu()

## Handle achievement unlocked signal
func _on_achievement_unlocked(_achievement_id: String, _achievement_data: Dictionary) -> void:
	# Update the display if the menu is visible
	if visible:
		_populate_achievements()
		_update_progress_display()

## Handle achievement progress updated signal
func _on_achievement_progress_updated(_achievement_id: String, _progress: float) -> void:
	# Update the display if the menu is visible
	if visible:
		_populate_achievements()
		_update_progress_display()

## Handle input events
func _input(event: InputEvent) -> void:
	if not visible:
		return
	
	# Close menu with ESC key
	if event.is_action_pressed("ui_cancel"):
		hide_achievements_menu()
		get_viewport().set_input_as_handled()
