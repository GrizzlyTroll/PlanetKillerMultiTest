extends Node
class_name AnimationComponent

# --- Exported Nodes ---
@export var sprite: AnimatedSprite2D
@export var player_body: PlayerOne

# --- Animation State ---
var is_hurt: bool = false
var hurt_animation_duration: float = 0.2
var hurt_timer: float = 0.0
var hitting: bool = false
var hit_animation_duration: float = 0.27  # Match your hit animation length
var hit_timer: float = 0.0
var dodge_animation_duration: float = 0.3
var dodge_timer: float = 0.0
var dodging: bool = false
var sprinting: bool = false

# --- Horizontal Flip ---
func handle_horizontal_flip(move_direction: float) -> void:
	if move_direction == 0:
		return
	sprite.flip_h = false if move_direction > 0 else true

func handle_hit_animation(is_hit: bool) -> void:
	pass
# --- Main Animation Handler ---
func handle_animation(
		body: CharacterBody2D,
		is_jumping: bool,
		is_falling: bool,
		move_direction: float,
		is_hitting: bool, 
		is_dodging: bool, 
		is_crouching: bool,
		is_sprinting: bool,
		is_dead: bool
	) -> void:
	if is_dodging and not dodging:
		dodging = true
		dodge_timer = dodge_animation_duration
		
	if dodging:
		dodge_timer -= get_process_delta_time()
		if dodge_timer <= 0:
			dodging = false
			
	# --- Hit Animation Timer ---
	if is_hitting and not hitting:
		hitting = true
		hit_timer = hit_animation_duration

	if hitting:
		hit_timer -= get_process_delta_time()
		if hit_timer <= 0:
			hitting = false

	# --- Play Hit Animation ---
	# priority: Hit → Dodge → Crouch → Jump/Fall/Run/Idle
	if hitting:
		sprite.play("Hit")
		return
	if dodging:
		sprite.play("Dodge")
		return
	if is_crouching and body.is_on_floor():
		handle_horizontal_flip(move_direction)
		sprite.play("Crouch")
		return
		
	# --- Normal Animation Logic ---
	if move_direction != 0 or body.velocity.y != 0:
		handle_horizontal_flip(move_direction)
		if is_jumping:
			sprite.play("Jump")
		elif is_falling:
			sprite.play("Fall")
		elif is_sprinting:
			sprite.play("Sprint")
		else:
			sprite.play("Run")
	else:
		sprite.play("Idle")
	# Dead animations
	if is_dead:
		sprite.play("Dead")
		return
