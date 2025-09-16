class_name PlayerOne
extends CharacterBody2D

# --- Exported Nodes & Components ---
@export_subgroup("Nodes")
@export var player_inventory: Resource


@export var gravity_component: GravityComponent
@export var input_component: InputComponent
@export var movement_component: MovementComponent
@export var animation_component: AnimationComponent
@export var jump_component: JumpComponent
@export var inv: Resource
@export var speed = 300.0
@export var min_knockback := 100
@export var slow_knockback := 1.1
@onready var gc := $GrappleController

#audio
@onready var audio_player = $FootstepPlayer
@onready var audio_player_pistol = $BulletNoise

# --- Ui Variables
@onready var sprite:AnimatedSprite2D = $AnimatedSprite2D
@onready var label = $Camera2D/Label
@onready var health_ui = $HealthBarUI
@onready var pickup_area = $PickupArea
# --- Wall Slide Settings ---
@export var wall_slide_speed := 110.0
@export var wall_jump_force := Vector2(250, -400)

#kami
@onready var particle_effect = $Kami
#walking particles
@onready var walking_particles = $walking_particles

@onready var multiplayer_menu = $HighLevelUI
#audio cues
var footstep_sounds = {
	"Grass": preload("res://Sounds/footstep_grass.wav"),
}
var pistol_sound = {
	"Bullet": preload("res://Sounds/silenced_pistol_sound_effect.wav")
}
var player_hurt_sound = preload("res://Sounds/PlayerNoises/PlayerHurt.wav")

#audiosteps
var footstep_timer: Timer
var footstep_pitch_variation = 0.2
var normal_pitch_range = 0.9  # Normal walking pitch range
var sprint_pitch_range = 0.3  # Sprint pitch range (more variation)
var last_footstep_time = 0.0
var footstep_delay = .8  # Time between footsteps
# --- State Variables ---
var invincible = false
var is_wall_sliding := false
var wall_direction := 0 # -1 = left wall, 1 = right wall
const max_health = 100.0
var health = max_health
var dead = false
var current_axe = null
# --- Dodge Variables ---
var is_dodging := false
var dodge_timer := 0.0
var dodge_cooldown := 0.0
var dodge_speed := 400.0
var dodge_duration := 0.3
var dodge_cooldown_time := 1.25
var is_crouching := false
var dodge_direction := 0
var is_sprinting: bool = false
var knockback:Vector2



# --- Signals ---
signal health_change
signal hit

func _enter_tree() -> void:
	# Set multiplayer authority based on the player's unique ID
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
		print("Player: Set authority to ", name.to_int(), " for player named: ", name)
	else:
		# Fallback for non-numeric names
		set_multiplayer_authority(1)
		print("Player: Set fallback authority to 1 for player named: ", name)

func _ready() -> void:
	player_inventory = preload("res://inventory/inventory.gd").new()
	
	multiplayer_menu.hide()
	# Initialize inventory properly
	
	
	# Make sure items array exists
	if player_inventory.items == null:
		player_inventory.items = []
	
	player_inventory.items.resize(12)  # 12 slots
	
	print("Player inventory created: ", player_inventory)  # Debug line
	print("Items array: ", player_inventory.items)  # Debug line
	
	if pickup_area:
		pickup_area.body_entered.connect(_on_pickup_area_entered)
	if audio_player != null:
		# Test if sound files load
		for sound_name in footstep_sounds:
			if footstep_sounds[sound_name] != null:
				var random_pitch = 1.0 + (randf() - 0.5) * footstep_pitch_variation
				audio_player.pitch_scale = random_pitch
				
				if is_sprinting:
					random_pitch += 0.2  # Make sprint footsteps higher pitched
					audio_player.pitch_scale = random_pitch
		# Test sound immediately
		audio_player.stream = footstep_sounds["Grass"]
		audio_player.volume_db = 0  # Set volume to normal
		audio_player.play()
	
	# Set up footstep sounds
	footstep_timer = Timer.new()
	footstep_timer.wait_time = 0
	footstep_timer.one_shot = true
	footstep_timer.timeout.connect(_on_footstep_timer_timeout)
	add_child(footstep_timer)
	audio_player.stream = footstep_sounds["Grass"]  # Default
# --- Health Functions ---
	if has_node("PlayerNoises"):
		$PlayerNoises.stream = player_hurt_sound
		$PlayerNoises.volume_db = -10
	if has_node("BulletNoise"):
		$BulletNoise.stream = play_bullet_sound()
func get_health() -> float:
	return health
	

func _on_pickup_area_entered(body):
	if body.is_in_group("pickup_items"):
		var item = body
		if inv.add_item(item.item_data):
			item.queue_free()
			
			
func create_droppable_item(item_data: Resource, position: Vector2):
	var dropped_item = preload("res://Scenes/PlayerStuff/droppable_item.tscn").instantiate()
	dropped_item.item_data = item_data
	dropped_item.global_position = position
	add_child(dropped_item)
# Function to drop items
func drop_item(item: Resource, slot_index: int = -1):
	if item:
		# Create droppable item
		var dropped_item = preload("res://Scenes/PlayerStuff/droppable_item.tscn").instantiate()
		dropped_item.item_data = item
		dropped_item.global_position = global_position + Vector2(randf_range(-20, 20), -10)
		get_tree().current_scene.add_child(dropped_item)
		
		# Remove from inventory if slot specified
		if slot_index >= 0:
			inv.remove_item(slot_index)
func _on_footstep_timer_timeout():
	audio_player.stop()
	
func play_hurt_sound():
	$PlayerNoises.play()
	
func play_bullet_sound():
	$BulletNoise.play()
	
func play_footstep_sound():
	var tile_type = get_tile_type_at_position()
	if tile_type in footstep_sounds:
		audio_player.stream = footstep_sounds[tile_type]
		
		# Set pitch scale between 0.7 and 1.1
		var random_volume = randf_range(-8, -5)
		audio_player.volume_db = random_volume
		var random_pitch = randf_range(0.8, 1.1)
		audio_player.pitch_scale = random_pitch
		
		audio_player.play()
		

func get_tile_type_at_position():
	# Get the tile at player's feet - with proper caps
	var world_pos = global_position
	
	# Check all your tilemaps with proper caps
	var tilemaps = {
		"Grass": get_node("../World/Grass"),
	}
	
	for tile_type in tilemaps:
		var tilemap = tilemaps[tile_type]
		if tilemap != null:
			var local_pos = tilemap.to_local(world_pos)
			var cell = tilemap.local_to_map(local_pos)
			var tile_data = tilemap.get_cell_tile_data(cell)

			if tile_data != null:
				return tile_type

	return "Grass"  # Default fallback

func _on_body_entered(body: Node):
	# If dodging, ignore enemy collisions
	if is_dodging and body.has_method("take_damage"):
		# Don't take damage from enemies while dodging
		return
		
#func shoot_particle_effect():
	#if particle_effect != null:
		#particle_effect.emitting = true
		#
		## Set direction through Process Material
		#if particle_effect.process_material != null:
			#var material = particle_effect.process_material as ParticleProcessMaterial
			#if material != null:
				## Set direction based on player facing
				#if sprite.flip_h:  # Player facing left
					#material.direction = Vector3(-1, 0, 0)
				#else:  # Player facing right
					#material.direction = Vector3(1, 0, 0)
	#else:

func handle_health(is_hit: bool, damage: float, dodging: bool) -> void:
	if is_hit and not dodging and not invincible:
		health -= damage
		
		# ADD THIS - Play hurt sound when taking damage
		play_hurt_sound()
		
		hit.emit()
		health_change.emit()
		if health_ui:
			var health_precentage = (health/ max_health)*100
			health_ui.update_health(health_precentage)
		animation_component.handle_hit_animation(is_hit)
		is_hit = false

# --- Axe Functions ---
#func _input(event):
	#
	#if event.is_action_pressed("ParticleEffect"):
		#shoot_particle_effect()
		#if event.is_action_pressed("SwingAxe"):  # Add this input action
			#swing_axe()

func swing_axe():
	if current_axe != null:
		current_axe.swing_axe()

# --- Particles ---
func update_particles():
# Check if the player is on the floor AND moving
	var is_moving_horizontally = abs(velocity.x) > 1.0 # Use a small threshold to avoid emitting particles when stationary
	update_particles()
	if is_on_floor() and is_moving_horizontally:
		# Start emitting particles
		walking_particles.emitting = false
	else:
		# Stop emitting particles
		walking_particles.emitting = true
		update_particles()

# --- Drill Functions ---


# --- Fireball Functions ---
func shoot_fireball() -> void:
	var fireball = preload("res://Scenes/Equipment/Shuriken.tscn").instantiate()
	fireball.add_momentum(velocity.x) 
	fireball.global_position = global_position  # or wherever you want it to start
	if not sprite.flip_h:
		fireball.move_direction = 1
	else:
		fireball.move_direction = -1 
	get_parent().add_child(fireball)

# --- Wall Mechanics ---
func detect_wall() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0:
		is_wall_sliding = true
		wall_direction = sign(get_wall_normal().x)
	else:
		is_wall_sliding = false
		wall_direction = 0

func handle_wall_slide() -> void:
	if is_wall_sliding and velocity.y > wall_slide_speed:
		velocity.y = wall_slide_speed

func handle_wall_jump() -> void:
	if is_wall_sliding and input_component.get_jump_input():
		velocity = Vector2(-wall_direction * wall_jump_force.x, wall_jump_force.y)
		is_wall_sliding = false
		

# Modify your movement section
	if not animation_component.hitting and not dead and not is_wall_sliding:
		if not is_dodging:
			movement_component.handle_horizantal_movement(self, input_component.input_horizontal, is_sprinting)
			jump_component.handle_jump(self, input_component.get_jump_input())
	elif not dead and not is_wall_sliding:
		velocity.x = 0

# --- Player Physics ---
func _physics_process(delta: float) -> void:
	# Only process input for the local player
	if not is_multiplayer_authority():
		# For remote players, just apply gravity and move
		gravity_component.handle_gravity(self, delta)
		move_and_slide()
		return
	
	# Debug: Only log occasionally to avoid spam
	if Engine.get_process_frames() % 60 == 0:  # Log every 60 frames (about once per second)
		print("Player: ", name, " is processing input (authority: ", get_multiplayer_authority(), ")")

	if Input.is_action_pressed("MultiplayerMenu"): multiplayer_menu.show()
	
	if is_on_floor() and abs(velocity.x) > 10:
		if footstep_timer.is_stopped():
			 # Different timing for sprinting
			if is_sprinting:
				footstep_timer.wait_time = 0.3  # Faster footsteps when sprinting
			else:
				footstep_timer.wait_time = 0.5  # Normal footsteps when walking
			
			footstep_timer.start()
			play_footstep_sound()

	
	if Input.is_action_just_pressed("Fireball"):
		shoot_fireball()
	is_sprinting = input_component.get_sprint_input()
	
	if Input.is_action_pressed("Sprint"):
		is_sprinting = true
	
	# Update your existing movement calls to include is_sprinting:
	if not animation_component.hitting and not dead and not is_wall_sliding and not is_dodging and not is_crouching:
			movement_component.handle_horizantal_movement(self, input_component.input_horizontal, is_sprinting)
			jump_component.handle_jump(self, input_component.get_jump_input())
	label.visible = false
	
	# --- Wall Mechanics ---
	detect_wall()
	handle_wall_slide()
	handle_wall_jump()


	if dodge_cooldown > 0:
		dodge_cooldown -= get_process_delta_time()
	
	# Handle dodge duration
	if dodge_timer > 0:
		dodge_timer -= get_process_delta_time()
	if dodge_timer <= 0:
		is_dodging = false
		invincible = false
	
	if Input.is_action_just_pressed("Dodge") and dodge_cooldown <= 0 and not is_dodging and not dead:
		is_dodging = true
		invincible = true
		dodge_timer = dodge_duration
		dodge_cooldown = dodge_cooldown_time
		dodge_direction = sign(input_component.input_horizontal) 
		velocity.x = dodge_direction * dodge_speed
		#animation_component.handle_dodge()
		$AnimatedSprite2D.play("Dodge")
	
	# --- Normal Movement (if not wall jumping) ---
	if not animation_component.hitting and not dead and not is_wall_sliding and not is_dodging and not is_crouching:
		movement_component.handle_horizantal_movement(self, input_component.input_horizontal, is_sprinting)
		jump_component.handle_jump(self, input_component.get_jump_input())
	elif not dead and not is_wall_sliding:
		velocity.x = 0
		

	# --- Health Check ---
	if health <= 0:
		label.visible = true
		dead = true
		velocity.x = 0
		input_component.set_process(false)
		is_crouching = false
	
	elif health > 0:
		input_component.set_process(true)
		if not is_dodging: movement_component.handle_horizantal_movement(self, input_component.input_horizontal, is_sprinting)
		jump_component.handle_jump(self, input_component.get_jump_input())

	# --- Gravity ---
	gravity_component.handle_gravity(self, delta)
	is_crouching = input_component.get_crouch_input()
	
	# --- Additional Movement Check ---
	if not animation_component.hitting and not dead:
		movement_component.handle_horizantal_movement(self, input_component.input_horizontal, is_sprinting)
		jump_component.handle_jump(self, input_component.get_jump_input())
	elif not dead:
		velocity.x = 0

	# --- Animation Handling ---

	animation_component.handle_animation(
		self,
		jump_component.is_jumping,
		gravity_component.is_falling,
		input_component.input_horizontal,
		false,
		is_dodging,
		is_crouching,
		is_sprinting,
		dead
		)
	if knockback.length() > min_knockback and not dead:
		knockback /= slow_knockback
		velocity = knockback
		move_and_slide()
		return
	
	# --- Move Character ---
	move_and_slide()
	
	# --- Network Synchronization ---
	if is_multiplayer_authority():
		_sync_player_state()

func _sync_player_state() -> void:
	# Only the authority (owner) of this player should sync their state
	if not is_multiplayer_authority():
		return
	
	# Sync position and velocity
	rpc("_update_player_position", global_position, velocity)
	
	# Sync health
	rpc("_update_player_health", health)
	
	# Sync animation state
	rpc("_update_player_animation", sprite.animation, sprite.flip_h)

@rpc("any_peer", "unreliable")
func _update_player_position(pos: Vector2, vel: Vector2) -> void:
	# Only update if we're not the authority
	if not is_multiplayer_authority():
		global_position = pos
		velocity = vel

@rpc("any_peer", "reliable")
func _update_player_health(new_health: float) -> void:
	# Only update if we're not the authority
	if not is_multiplayer_authority():
		health = new_health
		health_change.emit()
		if health_ui:
			var health_percentage = (health / max_health) * 100
			health_ui.update_health(health_percentage)

@rpc("any_peer", "unreliable")
func _update_player_animation(anim_name: String, flip: bool) -> void:
	# Only update if we're not the authority
	if not is_multiplayer_authority():
		sprite.animation = anim_name
		sprite.flip_h = flip

func take_damage(damage: float, source_position: Vector2 = Vector2.ZERO) -> void:
	# Only the authority can process damage
	if not is_multiplayer_authority():
		return
	
	# Apply damage
	handle_health(true, damage, is_dodging)
	
	# Apply knockback if source position is provided
	if source_position != Vector2.ZERO:
		var knockback_direction = (global_position - source_position).normalized()
		knockback = knockback_direction * 200.0
	
	# Sync damage to other players
	rpc("_sync_damage", damage, source_position)

@rpc("any_peer", "reliable")
func _sync_damage(damage: float, source_position: Vector2) -> void:
	# Apply damage to non-authority players
	if not is_multiplayer_authority():
		handle_health(true, damage, is_dodging)
		if source_position != Vector2.ZERO:
			var knockback_direction = (global_position - source_position).normalized()
			knockback = knockback_direction * 200.0

func is_local_player() -> bool:
	return is_multiplayer_authority()

func get_player_id() -> int:
	return get_multiplayer_authority()
