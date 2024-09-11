@tool
extends Node3D

@onready var grid_map: GridMap = $GridMap

@export var start : bool = false : set = set_start
func set_start(val:bool) -> void:
	generate()
func _ready():
	generate()
# border size is the size of the outermost layer	
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int) -> void:
	border_size = val
	# we only visualize the border in the editor, not in the game itself
	if Engine.is_editor_hint():
		visualize_border()
		visualize_spawn_room()
		visualize_doors()

@export var num_layers : int = 4
@export var layer_margin : int = 4
@export var min_room_size : int = 2
@export var max_room_size : int = 4
@export var room_margin : int = 4 # min space between secret rooms
@export var spawn_position : Vector3i = Vector3i(-1, 0, 10)
@export var shape : StringName = StringName("")

enum TILES {ROOM, HALLWAY, DOOR, BORDER, SPAWN}


func visualize_border():
	grid_map.clear()
	for layer in range(num_layers):
		var layer_padding = layer * layer_margin
		for i in range(-1 + layer_padding, border_size + 1 - layer_padding):
			# north edge
			grid_map.set_cell_item(Vector3i(i , 0, -1 + layer_padding), TILES.ROOM)
			# south edge
			grid_map.set_cell_item(Vector3i(i, 0, border_size - layer_padding), TILES.ROOM)
			# east edge
			grid_map.set_cell_item(Vector3i(border_size - layer_padding, 0, i), TILES.ROOM)
			# west edge
			grid_map.set_cell_item(Vector3i(-1 + layer_padding, 0, i), TILES.ROOM)

func visualize_spawn_room():
	grid_map.set_cell_item(spawn_position, TILES.SPAWN)

func visualize_doors():
	# door to next layer can't be within view from previous door or spawn
	print(shape)
	if shape == &"Square":
		# if it's a square, we just make sure that the door isn't on the same
		# x or z axis
		var current_position = spawn_position
		var layer_tiles : PackedVector3Array = get_square_room_tiles(current_position)
		print(layer_tiles)
	pass
	
# gets all room tiles within the same layer as position	
func get_square_room_tiles(position : Vector3i):
	var room_tiles : PackedVector3Array = [position]
	
	var current_position = position
	var directions = [Vector3i.FORWARD, Vector3i.RIGHT,
		Vector3i.BACK, Vector3i.LEFT]
	var direction_index = 0
	for i in range(directions.size()):
		if grid_map.get_cell_item(current_position + directions[i]) == TILES.ROOM:
			direction_index = i
			current_position = current_position + directions[i]
			room_tiles.append(current_position)
			break
	var next_position = current_position + directions[direction_index]
	while next_position != position:
		while grid_map.get_cell_item(next_position) == TILES.ROOM:
			room_tiles.append(next_position)
			current_position = next_position
			next_position = current_position + directions[direction_index]
		direction_index = (direction_index + 1) % directions.size() 
		next_position = current_position + directions[direction_index]

func generate():
	visualize_border()
	visualize_spawn_room()
	visualize_doors()


	
