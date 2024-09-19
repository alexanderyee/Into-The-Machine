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
@export var layer_margin : int = 2
@export var room_margin : int = 2 # min space between secret rooms
@export var spawn_position : Vector3i = Vector3i(10, 0, 11)
var shape : StringName = &"Square"
enum TILES {ROOM, HALLWAY, DOOR, BORDER, SPAWN}

func visualize_border():
	grid_map.clear()
	var actual_num_layers = 0
	for layer in range(num_layers):
		var layer_padding = layer * layer_margin
		if layer_padding < border_size - layer_padding:
			actual_num_layers += 1
		for i in range(layer_padding, border_size - layer_padding):
			# north edge
			grid_map.set_cell_item(Vector3i(i , 0, layer_padding), TILES.ROOM)
			# south edge
			grid_map.set_cell_item(Vector3i(i, 0, border_size - layer_padding - 1), TILES.ROOM)
			# east edge
			grid_map.set_cell_item(Vector3i(border_size - layer_padding - 1, 0, i), TILES.ROOM)
			# west edge
			grid_map.set_cell_item(Vector3i(layer_padding, 0, i), TILES.ROOM)
	if actual_num_layers < num_layers:
		print("Warning: invalid num_layers set, setting num_layers to " + str(actual_num_layers))
		num_layers = actual_num_layers

func visualize_spawn_room():
	grid_map.set_cell_item(spawn_position, TILES.SPAWN)

func visualize_doors():
	# door to next layer can't be within view from previous door or spawn
	if shape == &"Square":
		# if it's a square, we just make sure that the door isn't on the same
		# x or z axis
		var current_position = spawn_position
		for i in num_layers - 1:
			var layer_tiles : PackedVector3Array = get_square_room_tiles(current_position)
			# door to next layer can't be on the same side as the spawn door/prev door
			var possible_door_tiles : PackedVector3Array = filter_possible_door_tiles(layer_tiles, current_position)
			var door_tile_position = possible_door_tiles[randi_range(0, possible_door_tiles.size() - 1)]
			grid_map.set_cell_item(door_tile_position, TILES.DOOR)
			# create door room to next layer
			var level_center = Vector3i(border_size / 2, 0, border_size / 2)
			var direction_towards_center : Vector3 = door_tile_position.direction_to(level_center)
			if abs(direction_towards_center.x) > abs(direction_towards_center.z):
				if direction_towards_center.x > 0:
					grid_map.set_cell_item(door_tile_position + Vector3.RIGHT, TILES.DOOR)
					current_position = door_tile_position + Vector3.RIGHT * 2
				else:
					grid_map.set_cell_item(door_tile_position + Vector3.LEFT, TILES.DOOR)
					current_position = door_tile_position + Vector3.LEFT * 2
			else:
				if direction_towards_center.z > 0:
					grid_map.set_cell_item(door_tile_position + Vector3.BACK, TILES.DOOR)
					current_position = door_tile_position + Vector3.BACK * 2
				else:
					grid_map.set_cell_item(door_tile_position + Vector3.FORWARD, TILES.DOOR)
					current_position = door_tile_position + Vector3.FORWARD * 2
	
	
func filter_possible_door_tiles(layer_tiles, prev_door) -> PackedVector3Array:
	var possible_door_tiles : PackedVector3Array = []
	var prev_door_axis : int = find_prev_door_axis(prev_door)
	for room in layer_tiles:
		# can't be on same side as the spawn/prev door
		# TODO: cleaner way to shorten this duplicate code?
		if prev_door_axis == Vector3i.AXIS_X:
			if room.z == prev_door.z:
				continue
		elif prev_door_axis == Vector3i.AXIS_Z:
			if room.x == prev_door.x:
				continue
		
		# can't be on corners or next tile over (assuming padding between layers = 1)
		if is_cell_corner(room): 
			continue
		elif is_next_to_cell_corner(room):
			continue
		possible_door_tiles.append(room)
	
	return possible_door_tiles
	
# returns if a cell is a corner 
func is_cell_corner(cell : Vector3i) -> bool:
	if grid_map.get_cell_item(cell + Vector3i.FORWARD) == TILES.ROOM or grid_map.get_cell_item(cell + Vector3i.BACK) == TILES.ROOM:
		if grid_map.get_cell_item(cell + Vector3i.RIGHT) == TILES.ROOM or grid_map.get_cell_item(cell + Vector3i.LEFT) == TILES.ROOM:
			return true
	elif grid_map.get_cell_item(cell + Vector3i.RIGHT) == TILES.ROOM or grid_map.get_cell_item(cell + Vector3i.LEFT) == TILES.ROOM:
		if grid_map.get_cell_item(cell + Vector3i.FORWARD) == TILES.ROOM or grid_map.get_cell_item(cell + Vector3i.BACK) == TILES.ROOM:
			return true
	return false

func is_next_to_cell_corner(cell : Vector3i) -> bool:
	var adjacent_cells = []
	adjacent_cells.append(cell + Vector3i.FORWARD)
	adjacent_cells.append(cell + Vector3i.BACK)
	adjacent_cells.append(cell + Vector3i.LEFT)
	adjacent_cells.append(cell + Vector3i.RIGHT)
	for c in adjacent_cells:
		if is_cell_corner(c):
			return true
	return false

func find_prev_door_axis(door : Vector3i) -> int:
	if (grid_map.get_cell_item(door + Vector3i.FORWARD) == TILES.ROOM):
		return Vector3i.AXIS_Z
	return Vector3i.AXIS_X

# gets all room tiles within the same layer as position	
func get_square_room_tiles(position : Vector3i) -> PackedVector3Array:
	var room_tiles : PackedVector3Array = [position]

	var current_position = position
	var directions = [Vector3i.FORWARD, Vector3i.RIGHT,
		Vector3i.BACK, Vector3i.LEFT]
	# evaluate each position
	var possible_paths = [current_position]
	var tiles_visited = []
	while !possible_paths.is_empty():
		current_position = possible_paths[0]
		tiles_visited.append(current_position)
		possible_paths = []
		for d in directions:
			var adjacent_cell = grid_map.get_cell_item(current_position + d)
			if adjacent_cell == TILES.ROOM and !tiles_visited.has(current_position + d):
				possible_paths.append(current_position + d)
		if possible_paths.size() > 1:
			print("well, this shouldn't happen")
		
	return tiles_visited

func generate():
	visualize_border()
	visualize_doors()
	visualize_spawn_room()
	
