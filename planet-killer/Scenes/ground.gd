extends TileMapLayer

var fnl := FastNoiseLite.new()

func _ready() -> void:
	randomize()
	fnl.seed = randi()
	fnl.frequency = 0.050
	fnl.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	generate_map()

func generate_map() -> void:
	for x in 300:
		for y in 300:
			if y < 1:
				pass
			else:
				set_cell(Vector2i(x,y),0,Vector2i(1,1),0)
