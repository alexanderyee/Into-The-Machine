@tool
extends Node3D

@onready var grid_map: GridMap = $GridMap

@export var start : bool = false : set = set_start
func set_start(val:bool) -> void:
	generate()
	
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	# we only visualize the border in the editor, not in the game itself
	if Engine.is_editor_hint():
		visualize_border()
	
func visualize_border():
	grid_map.set_cell_item()
	
func generate():
	print("generating...")
	
