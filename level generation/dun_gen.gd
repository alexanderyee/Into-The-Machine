@tool
extends Node3D

@onready var grid_map: GridMap = $GridMap

@export var start : bool = false : set = set_start
func set_start(val:bool) -> void:
	generate()

# border size is the size of the outermost layer	
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int) -> void:
	border_size = val
	# we only visualize the border in the editor, not in the game itself
	if Engine.is_editor_hint():
		visualize_border()

@export var num_layers : int = 4
@export var layer_margin : int = 4
@export var min_room_size : int = 2
@export var max_room_size : int = 4
@export var room_margin : int = 4 # min space between secret rooms
@export var spawn_position : Vector3i = Vector3i(-1, 0, 10)
var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []


func visualize_border():
	grid_map.clear()
	for layer in range(num_layers):
		var layer_padding = layer * layer_margin
		for i in range(-1 + layer_padding, border_size + 1 - layer_padding):
			#TODO: enums for gridmap cell items?
			# north edge
			grid_map.set_cell_item(Vector3i(i , 0, -1 + layer_padding), 0)
			# south edge
			grid_map.set_cell_item(Vector3i(i, 0, border_size - layer_padding), 0)
			# east edge
			grid_map.set_cell_item(Vector3i(border_size - layer_padding, 0, i), 0)
			# west edge
			grid_map.set_cell_item(Vector3i(-1 + layer_padding, 0, i), 0)
	grid_map.set_cell_item(spawn_position, 4)
	
func generate():
	visualize_border()
	
func make_room(rec : int):
	if rec <= 0:
		return
	
	var width : int = randi_range(min_room_size, max_room_size)
	var height : int = randi_range(min_room_size, max_room_size)
	
	var start_pos : Vector3i
	start_pos.x = randi_range(0, border_size - width)
	start_pos.z = randi_range(0, border_size - height)
	
	for row in range(-room_margin, height + room_margin):
		for col in range(-room_margin, width + room_margin):
			var pos : Vector3i = start_pos + Vector3i(col, 0, row)
			if grid_map.get_cell_item(pos) == 0:
				make_room(rec - 1)
				return
			
	var room : PackedVector3Array = []
	for row in height:
		for col in width:
			var pos : Vector3i = start_pos + Vector3i(col, 0, row)
			grid_map.set_cell_item(pos, 0)
			room.append(pos)
	room_tiles.append(room)
	var avg_x : float = start_pos.x + (float(width) / 2)
	var avg_z : float = start_pos.z + (float(height) / 2)
	var pos : Vector3 = Vector3(avg_x, 0, avg_z)
	room_positions.append(pos)
	
