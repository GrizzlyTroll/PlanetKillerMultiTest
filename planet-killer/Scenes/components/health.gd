class_name Health
extends Node

signal max_health_changed(diff: int)
signal health_changed(diff: int)
signal health_depleted

@export var max_health: int = 10 : set = set_max_health, get = get_max_health
@export var imortality: bool = false : set = set_imortality, get = get_imortality

var imortality_timer: Timer = null

var health: int = max_health : set = set_health, get = get_health

func set_max_health(value: int):
	var clamped_value = 1 if value <= 0 else value
	
	if not clamped_value == max_health:
		var difference = clamped_value - max_health
		max_health = value
		max_health_changed.emit(difference)
		
		if health > max_health:
			health = max_health

func get_max_health() -> int:
	return max_health

func set_imortality(value: bool):
	imortality = value

func get_imortality() -> bool:
	return imortality

func set_temp_imortality(time: float):
	if imortality_timer == null:
		imortality_timer = Timer.new()
		imortality_timer.one_shot = true
		add_child(imortality_timer)
	
	if imortality_timer.timeout.is_connected(set_imortality):
		imortality_timer.timeout.disconnect(set_imortality)
	
	imortality_timer.set_wait_time(time)
	imortality_timer.timeout.connect(set_imortality.bind(false))
	imortality = true
	imortality_timer.start()

func set_health(value: int):
	if value < health and imortality:
		return
	
	var clamped_value = clamp(value, 0, max_health)
	
	if clamped_value != health:
		var difference = clamped_value - health
		health = value
		health_changed.emit(difference)
	
	if health == 0:
		health_depleted.emit()

func get_health():
	return health
