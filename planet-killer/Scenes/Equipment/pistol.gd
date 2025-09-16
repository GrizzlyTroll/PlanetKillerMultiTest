extends Area2D

@onready var sprite:= $WeaponPivot/AnimatedSprite2D

var shoot_cooldown:= false
var shoot_firerate_timer:Timer

func _ready() -> void:
	shoot_firerate_timer = Timer.new()
	shoot_firerate_timer.wait_time = 0.5
	shoot_firerate_timer.one_shot = true
	shoot_firerate_timer.timeout.connect(_on_timer_timeout)
	add_child(shoot_firerate_timer)

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("Shoot"):
		if not shoot_cooldown:
			shoot()

func shoot():
	const bullet = preload("res://Scenes/Equipment/bullet.tscn")
	var new_bullet = bullet.instantiate()
	%ShootingPoint.add_child(new_bullet)
	new_bullet.global_position = %ShootingPoint.global_position
	new_bullet.global_rotation = %ShootingPoint.global_rotation
	shoot_cooldown = true
	shoot_firerate_timer.start()
	

func _on_timer_timeout() -> void:
	shoot_cooldown = false
