extends ProgressBar

@onready var player: Node = get_parent().get_parent()

func _ready():
	player.health_change.connect(update)
	update()

func update():
	value = player.get_health() * 100 / player.max_health
	if value == 0:
		pass
