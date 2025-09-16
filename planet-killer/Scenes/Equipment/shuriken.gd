extends RigidBody2D

signal hit_target(target, damage)

@export var move_distance: float = 500.0
@export var move_speed: float = 500.0
@export var drop_amount: float = 10

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D# Add this line
@onready var start_position: Vector2 = global_position
@onready var timer: Timer = $Timer


var has_moved: bool = false
var move_direction: int = 1
var damage = 5.0
var hit_targets = []



func _ready() -> void:
	sprite.play("Held")
	gravity_scale = 0.5
func add_momentum(playerspeed: float) -> void:
	if playerspeed >= 0:
		move_speed += playerspeed
	else:
		move_speed -= playerspeed

func handle_horizontal_flip():
	if move_direction == 1:
		sprite.flip_h = false
	else:
		sprite.flip_h = true
	
func _on_timer_timeout() -> void:
	queue_free()
	
func _physics_process(delta: float) -> void:
	handle_horizontal_flip()
	if not has_moved: 
		# Move laterally
		global_position.x += move_direction * move_speed * delta
		# Check if we've moved 48 pixels
		if abs(global_position.x - start_position.x) >= move_distance:
			has_moved = true
			sprite.play("Final")  # Play final frame and stop
			sprite.pause()  # Stop animation on final frame
			timer.start()
			timer.timeout.connect(_on_timer_timeout)
	
