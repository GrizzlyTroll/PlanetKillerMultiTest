extends ConfirmationDialog
class_name WorldDeletionDialog

## World Deletion Dialog - Confirmation dialog for deleting world saves
## Prevents accidental deletion of world saves

signal world_deletion_confirmed(world_name: String)

var world_name: String = ""

func _ready() -> void:
	# Set up dialog
	dialog_text = "Are you sure you want to delete this world?"
	dialog_autowrap = true
	
	# Connect signals
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)

## Show the deletion dialog for a specific world
func show_deletion_dialog(target_world_name: String) -> void:
	world_name = target_world_name
	dialog_text = "Are you sure you want to delete the world '%s'?\n\nThis action cannot be undone!" % world_name
	popup_centered()

## Handle confirmation
func _on_confirmed() -> void:
	world_deletion_confirmed.emit(world_name)
	hide()

## Handle cancellation
func _on_canceled() -> void:
	hide()
