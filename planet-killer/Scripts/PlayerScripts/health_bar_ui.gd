extends Control

@onready var heart_container = $HeartContainer

var hearts = []
var max_hearts = 5
var current_hearts = 5

func _ready():
	# Get all heart nodes
	for i in range(max_hearts):
		var heart = heart_container.get_child(i)
		hearts.append(heart)

func update_health(health_percentage):
	var new_hearts = int(ceil(health_percentage * max_hearts / 100.0))
	
	if new_hearts < current_hearts:
		# Lost health
		for i in range(current_hearts - new_hearts):
			if current_hearts - i - 1 >= 0:
				hearts[current_hearts - i - 1].lose_heart()
				hearts[current_hearts - i - 1].play_hit_animation()
	
	current_hearts = new_hearts
