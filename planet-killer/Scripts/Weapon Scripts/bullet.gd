extends Area2D

var travel_distance = 0.0



func _physics_process(delta: float) -> void:
	const speed = 1000.0
	const range = 1000.0
	
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta
	
	travel_distance += speed * delta
	if travel_distance > range: queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemies"): queue_free()
