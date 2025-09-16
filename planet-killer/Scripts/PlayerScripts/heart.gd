extends Control

@onready var heart_texture = $TextureRect
@onready var heart_animation = $AnimatedSprite2D

var heart_full = load("res://Assets/Icons/heart_full.png")
var heart_empty = load("res://Assets/Icons/heart_empty.png")

func _ready():
	# Start with full heart
	heart_texture.texture = heart_full
	# Hide AnimatedSprite2D initially
	heart_animation.visible = false

func lose_heart():
	# Change to empty heart
	heart_texture.texture = heart_empty

func gain_heart():
	# Change back to full heart
	heart_texture.texture = heart_full

func play_hit_animation():
	# Show AnimatedSprite2D and play hit animation
	heart_animation.visible = true
	heart_animation.play("hearthit")
	await heart_animation.animation_finished
	heart_animation.visible = false
