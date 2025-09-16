extends Control

# UI References
@onready var subtitle_label: Label = $VBoxContainer/Subtitle
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var details_label: Label = $VBoxContainer/DetailsLabel
@onready var chunk_info: Label = $VBoxContainer/ChunkInfo
@onready var block_info: Label = $VBoxContainer/BlockInfo
@onready var tip_label: Label = $VBoxContainer/TipLabel
@onready var cancel_button: Button = $VBoxContainer/CancelButton

# World generation parameters
var world_generator: Node
var total_chunks: int = 1
var current_chunk: int = 0
var total_blocks: int = 0
var current_blocks: int = 0
var generation_steps: Array[String] = [
	"Initializing noise generators...",
	"Setting up world parameters...",
	"Generating initial terrain...",
	"Creating biomes...",
	"Adding surface features...",
	"Finalizing world...",
	"Spawning player...",
	"World ready!"
]
var current_step: int = 0

var loading_tips: Array[String] = [
	"Tip: Use WASD to move and SPACE to jump",
	"Tip: Right-click to break blocks",
	"Tip: The world is infinite - explore as far as you want!",
	"Tip: Dig deep to find rare materials",
	"Tip: Different biomes have different resources",
	"Tip: Caves are more common at greater depths",
	"Tip: Use the drill tool for faster mining",
	"Tip: The world is 1,200 blocks deep!"
]
var current_tip: int = 0

func _ready() -> void:
	print("Loading scene started")
	
	# Set up the progress bar
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	
	# Connect cancel button
	cancel_button.pressed.connect(_on_cancel_button_pressed)
	
	# Start background animation
	start_background_animation()
	
	# Start the world generation process
	start_world_generation()

func start_background_animation() -> void:
	"""Start subtle background animations"""
	# Create a simple pulsing effect on the background
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($BackgroundPattern, "modulate:a", 0.1, 2.0)
	tween.tween_property($BackgroundPattern, "modulate:a", 0.3, 2.0)
	
	# Start tip rotation
	start_tip_rotation()

func start_tip_rotation() -> void:
	"""Start rotating through loading tips"""
	# Show initial tip
	update_tip()
	
	# Create timer to rotate tips
	var timer = Timer.new()
	timer.wait_time = 3.0  # Change tip every 3 seconds
	timer.timeout.connect(update_tip)
	add_child(timer)
	timer.start()

func update_tip() -> void:
	"""Update the displayed tip"""
	tip_label.text = loading_tips[current_tip]
	current_tip = (current_tip + 1) % loading_tips.size()

func start_world_generation() -> void:
	"""Start the world generation process with progress updates"""
	print("Starting world generation with loading screen...")
	
	# Step 1: Initialize noise generators
	update_status("Initializing noise generators...", 5.0)
	await get_tree().create_timer(0.5).timeout
	
	# Step 2: Set up world parameters
	update_status("Setting up world parameters...", 10.0)
	await get_tree().create_timer(0.3).timeout
	
	# Step 3: Create the world generator
	update_status("Creating world generator...", 15.0)
	create_world_generator()
	await get_tree().create_timer(0.5).timeout
	
	# Step 4: Generate initial terrain
	update_status("Generating initial terrain...", 25.0)
	await generate_initial_terrain()
	
	# Step 5: Create biomes
	update_status("Creating biomes...", 50.0)
	await get_tree().create_timer(0.5).timeout
	
	# Step 6: Add surface features
	update_status("Adding surface features...", 70.0)
	await get_tree().create_timer(0.5).timeout
	
	# Step 7: Finalize world
	update_status("Finalizing world...", 85.0)
	await get_tree().create_timer(0.5).timeout
	
	# Step 8: Spawn player
	update_status("Spawning player...", 95.0)
	await get_tree().create_timer(0.3).timeout
	
	# Step 9: Complete
	update_status("World ready!", 100.0)
	await get_tree().create_timer(1.0).timeout
	
	# Transition to the game
	transition_to_game()

func create_world_generator() -> void:
	"""Create the world generator node"""
	# Create a temporary world generator for progress tracking
	world_generator = Node.new()
	world_generator.name = "WorldGenerator"
	add_child(world_generator)
	
	# Set up basic parameters
	total_chunks = 1  # Start with just the spawn chunk
	total_blocks = 64 * 20  # 64 blocks wide, 20 blocks deep initially

func generate_initial_terrain() -> void:
	"""Simulate initial terrain generation with progress updates"""
	var columns_per_update = 8
	var total_columns = 64
	
	for i in range(0, total_columns, columns_per_update):
		var progress = 25.0 + (float(i) / float(total_columns)) * 20.0
		var current_column = min(i + columns_per_update, total_columns)
		
		# Update block count
		current_blocks += columns_per_update * 20
		update_block_info()
		
		# Update chunk info
		current_chunk = 1
		update_chunk_info()
		
		# Small delay to show progress
		await get_tree().create_timer(0.1).timeout

func update_status(status: String, progress: float) -> void:
	"""Update the status display and progress bar"""
	subtitle_label.text = "Generating World..."
	status_label.text = status
	progress_bar.value = progress
	details_label.text = "Step %d of %d" % [current_step + 1, generation_steps.size()]

func update_chunk_info() -> void:
	"""Update the chunk information display"""
	chunk_info.text = "Chunks: %d/%d" % [current_chunk, total_chunks]

func update_block_info() -> void:
	"""Update the block information display"""
	block_info.text = "Blocks: %d" % current_blocks

func transition_to_game() -> void:
	"""Transition to the actual game scene"""
	print("Transitioning to game scene...")
	
	# Change to the procedural test scene
	get_tree().change_scene_to_file("res://Scenes/procedural_test.tscn")

func _on_cancel_button_pressed() -> void:
	"""Handle cancel button press"""
	print("Loading cancelled by user")
	get_tree().change_scene_to_file("res://Scenes/TitleScreen.tscn")

func _input(event: InputEvent) -> void:
	"""Handle input during loading"""
	# Allow ESC to cancel loading and return to title screen
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_button_pressed()
