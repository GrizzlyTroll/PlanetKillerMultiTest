extends CharacterBody2D

@export var speed: float = 80.0
@export var ray_length: float = 29.0
@export var knockback := 500


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wall_ray: RayCast2D = $WallRay
@onready var detection_area: Area2D = $DetectionArea
@onready var player_colision: Area2D = $PlayerColision

var player_in_range = false
var player_seen = false
var direction: int = 1
var player: Node = null
var invincible = false
var invincible_timer = Timer
var hit_cooldown = false
var hit_cooldown_timer = Timer
var hit_done = false
var health = 50


const damage = 20.0
const max_health = 50



func _ready() -> void:
	hit_cooldown_timer = Timer.new()
	hit_cooldown_timer.wait_time = 3 
	hit_cooldown_timer.one_shot = true
	hit_cooldown_timer.timeout.connect(on_hit_cooldown_timer_timeout)
	add_child(hit_cooldown_timer)
	player = get_tree().get_first_node_in_group("Player")
	
	if detection_area:
		detection_area.body_entered.connect(_on_body_entered)
		detection_area.body_exited.connect(_on_body_exited)
	if player_colision:
		player_colision.body_entered.connect(_on_body_entered_player)
		player_colision.body_exited.connect(_on_body_exited_player)
	if sprite:
		sprite.play("Idle")
	if wall_ray:
		wall_ray.target_position = Vector2(direction * ray_length,0)


func _physics_process(delta: float) -> void:
	 # Store the previous wall state
	var was_on_wall = is_on_wall()
	# Apply gravity
	if not is_on_floor():
		velocity.y += 980 * delta
	# Movement logic
	if player and is_instance_valid(player):
		var to_player = player.global_position - global_position
		direction = sign(to_player.x)
		velocity.x = direction * speed
		if player_in_range:
			velocity.x = 0
			if not hit_cooldown:
				if not hit_done:
					sprite.play("Hit")
					player.knockback = position.direction_to(player.position) * knockback
					hit_done = true
				elif hit_done:
					sprite.play("Idle")
				player.handle_health(true, damage,false)
				hit_cooldown = true
				hit_cooldown_timer.start()
		# Move the charactera
	move_and_slide()
	# Check if we just hit a wall and change direction
	if is_on_wall() and not was_on_wall:
		direction *= -1
	
	# Animation and sprite flipping
	sprite.flip_h = direction < 0

	if not player_in_range:
		if velocity.x != 0:
			if sprite.animation != "Walk":
				sprite.play("Walk")
		else:
			if sprite.animation != "Idle":
				sprite.play("Idle")
	if self.position.y > 500:
		queue_free()
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		player_seen = true
	

func _on_body_exited(body: Node) -> void:
	if body == player:
		player = null
		player_seen = false
	

func _on_body_entered_player(body: Node) -> void:
	player_in_range = true


func _on_body_exited_player(body: Node) -> void:
	if body == player:
		player_in_range = false
	

func on_hit_cooldown_timer_timeout():
	hit_cooldown = false
	hit_done = false
	

func _on_health_health_depleted() -> void:
	queue_free()
