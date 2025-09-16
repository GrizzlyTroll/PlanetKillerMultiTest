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
			if y < 2:
				pass
			elif y >= 1 and y < 15:
				var noise_value = fnl.get_noise_2d(x,y)
				if noise_value < -0.3:
					set_cell(Vector2i(x,y),3,Vector2(0,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(0,0),0)
				elif noise_value > -0.3 and noise_value < -0.1:
					set_cell(Vector2i(x,y),3,Vector2(1,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(1,0),0)
				elif noise_value > -0.1 and noise_value < 0.1:
					set_cell(Vector2i(x,y),3,Vector2(2,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(2,0),0)
				elif noise_value > 0.1 and noise_value < 0.3:
					set_cell(Vector2i(x,y),3,Vector2(3,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(3,0),0)
				else:
					set_cell(Vector2i(x,y),3,Vector2(4,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(4,0),0)
			elif y >= 15 and y < 50:
				var noise_value = fnl.get_noise_2d(x,y)
				if noise_value < -0.3:
					set_cell(Vector2i(x,y),3,Vector2(0,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(0,0),0)
				elif noise_value > -0.3 and noise_value < -0.1:
					set_cell(Vector2i(x,y),3,Vector2(1,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(1,0),0)
				elif noise_value > -0.1 and noise_value < 0.1:
					set_cell(Vector2i(x,y),3,Vector2(2,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(2,0),0)
				elif noise_value > 0.1 and noise_value < 0.3:
					set_cell(Vector2i(x,y),3,Vector2(3,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(3,0),0)
				else:
					set_cell(Vector2i(x,y),4,Vector2(0,2),0)
					set_cell(Vector2i(-x,y),4,Vector2(0,2),0)
			elif y >= 50 and y < 150:
				var noise_value = fnl.get_noise_2d(x,y)
				if noise_value < -0.3:
					set_cell(Vector2i(x,y),3,Vector2(0,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(0,0),0)
				elif noise_value > -0.3 and noise_value < -0.1:
					set_cell(Vector2i(x,y),3,Vector2(1,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(1,0),0)
				elif noise_value > -0.1 and noise_value < 0.1:
					set_cell(Vector2i(x,y),3,Vector2(2,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(2,0),0)
				elif noise_value > 0.1 and noise_value < 0.3:
					set_cell(Vector2i(x,y),4,Vector2(1,1),0)
					set_cell(Vector2i(-x,y),4,Vector2(1,1),0)
				else:
					set_cell(Vector2i(x,y),4,Vector2(0,2),0)
					set_cell(Vector2i(-x,y),4,Vector2(0,2),0)
			elif y >= 150 and y < 200:
				var noise_value = fnl.get_noise_2d(x,y)
				if noise_value < -0.3:
					set_cell(Vector2i(x,y),3,Vector2(0,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(0,0),0)
				elif noise_value >= -0.3 and noise_value < -0.1:
					set_cell(Vector2i(x,y),3,Vector2(1,0),0)
					set_cell(Vector2i(-x,y),3,Vector2(1,0),0)
				elif noise_value >= -0.1 and noise_value < 0.1:
					set_cell(Vector2i(x,y),4,Vector2(0,1),0)
					set_cell(Vector2i(-x,y),4,Vector2(0,1),0)
				elif noise_value >= 0.1 and noise_value < 0.3:
					set_cell(Vector2i(x,y),4,Vector2(1,1),0)
					set_cell(Vector2i(-x,y),4,Vector2(1,1),0)
				elif noise_value >= 0.3:
					set_cell(Vector2i(x,y),4,Vector2(0,2),0)
					set_cell(Vector2i(-x,y),4,Vector2(0,2),0)
			elif y >= 200:
				var noise_value = fnl.get_noise_2d(x,y)
				if noise_value >= -0.49 and noise_value < -0.3:
					set_cell(Vector2i(x,y),4,Vector2(0,0),0)
					set_cell(Vector2i(-x,y),4,Vector2(0,0),0)
				elif noise_value >= -0.3 and noise_value < -0.1:
					set_cell(Vector2i(x,y),4,Vector2(1,0),0)
					set_cell(Vector2i(-x,y),4,Vector2(1,0),0)
				elif noise_value >= -0.1 and noise_value < 0.1:
					set_cell(Vector2i(x,y),4,Vector2(0,1),0)
					set_cell(Vector2i(-x,y),4,Vector2(0,1),0)
				elif noise_value >= 0.1 and noise_value < 0.3:
					set_cell(Vector2i(x,y),4,Vector2(1,1),0)
					set_cell(Vector2i(-x,y),4,Vector2(1,1),0)
				else: 
					set_cell(Vector2i(x,y),4,Vector2(0,2),0) 
					set_cell(Vector2i(-x,y),4,Vector2(0,2),0) 
