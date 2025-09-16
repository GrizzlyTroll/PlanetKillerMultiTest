extends TileMapLayer

var fnl := FastNoiseLite.new()

func _ready() -> void:
	randomize()
	fnl.seed = randi()
	fnl.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	generate_map()

func generate_map() -> void:
	for x in 300:
		for y in 2:
			if y == 0:
				var rand_grass: int = randi_range(0,7)
				set_cell(Vector2i(x,y),2,Vector2(rand_grass,0))
				set_cell(Vector2i(-x,y),2,Vector2(rand_grass,0))
			else:
				var noise_value = fnl.get_noise_2d(x,y)
				print(noise_value)
				if noise_value > -0.5 and noise_value < -0.3:
					set_cell(Vector2i(x,y),1,Vector2(0,0),0)
					set_cell(Vector2i(-x,y),1,Vector2(0,0),0)
				elif noise_value > -0.3 and noise_value < -0.1:
					set_cell(Vector2i(x,y),1,Vector2(1,0),0)
					set_cell(Vector2i(-x,y),1,Vector2(1,0),0)
				elif noise_value > -0.1 and noise_value < 0.1:
					set_cell(Vector2i(x,y),1,Vector2(2,0),0)
					set_cell(Vector2i(-x,y),1,Vector2(2,0),0)
				elif noise_value > 0.1 and noise_value < 0.3:
					set_cell(Vector2i(x,y),1,Vector2(3,0),0)
					set_cell(Vector2i(-x,y),1,Vector2(3,0),0)
				else:
					set_cell(Vector2i(x,y),1,Vector2(4,0),0)
					set_cell(Vector2i(-x,y),1,Vector2(4,0),0)
