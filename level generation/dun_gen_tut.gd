@tool
extends Node3D

@onready var grid_map: GridMap = $GridMap

@export var start : bool = false : set = set_start
func set_start(val:bool) -> void:
	generate()
	
@export_range(0,1) var survival_chance : float = 0.25
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int) -> void:
	border_size = val
	# we only visualize the border in the editor, not in the game itself
	if Engine.is_editor_hint():
		visualize_border()

@export var num_rooms : int = 4
@export var room_margin : int = 1 # min space between rooms
@export var room_recursion_limit : int = 15 # max num attempts to generate rooms
@export var min_room_size : int = 2
@export var max_room_size : int = 4

var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []

func visualize_border():
	grid_map.clear()
	for i in range(-1, border_size + 1):
		# north edge
		grid_map.set_cell_item(Vector3i(i, 0, -1), 3)
		# south edge
		grid_map.set_cell_item(Vector3i(i, 0, border_size), 3)
		# east edge
		grid_map.set_cell_item(Vector3i(border_size, 0, i), 3)
		# west edge
		grid_map.set_cell_item(Vector3i(-1, 0, i), 3)
		
	
func generate():
	room_tiles.clear()
	room_positions.clear()
	visualize_border()
	for i in num_rooms:
		make_room(room_recursion_limit) # TODO probably a smarter way to do this
	
	var rpv2 : PackedVector2Array = []
	var del_graph : AStar2D = AStar2D.new()
	var mst_graph : AStar2D = AStar2D.new()
	
	for p in room_positions:
		rpv2.append(Vector2(p.x, p.z))
		del_graph.add_point(del_graph.get_available_point_id(), Vector2(p.x, p.z))
		mst_graph.add_point(mst_graph.get_available_point_id(), Vector2(p.x, p.z))
	
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(rpv2))
	
	for i in delaunay.size() / 3:
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		del_graph.connect_points(p1, p2)
		del_graph.connect_points(p2, p3)
		del_graph.connect_points(p1, p3)
	
	var visited_points : PackedInt32Array = []
	visited_points.append(randi() % room_positions.size())
	while visited_points.size() != mst_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points:
			for c in del_graph.get_point_connections(vp):
				if !visited_points.has(c):
					var con : PackedInt32Array = [vp, c]
					possible_connections.append(c)
		var connection : PackedInt32Array = possible_connections.pick_random()
		for pc in possible_connections:
			if rpv2[pc[0]].distance_squared_to(rpv2[pc[1]]) <\
			rpv2[connection[0]].distance_squared_to(rpv2[connection[1]]):
				connection = pc
		
		visited_points.append(connection[1])
		mst_graph.connect_points(connection[0], connection[1])
		del_graph.disconnect_points(connection[0], connection[1])
	
	var hallway_graph : AStar2D = mst_graph
	
	for p in del_graph.get_point_ids():
		for c in del_graph.get_point_connections(p):
			if c > p:
				var kill : float = randf()
				if survival_chance > kill:
					hallway_graph.connect_points(p, c)
	
	create_hallways(hallway_graph)
	
func create_hallways(hallway_graph: AStar2D):
	var hallways : Array[PackedVector3Array] = []
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c > p:
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
					
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
	
