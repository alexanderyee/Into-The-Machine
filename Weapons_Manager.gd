extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

@onready var Animation_Player = get_node("%AnimationPlayer")
@onready var bullet_point = get_node("%Bullet_Point")

var debug_bullet = preload("res://bullet_debug.tscn")
var Current_Weapon = null
var Weapon_Stack = [] # current weapons held by player
var Weapon_Indicator = 0
var Next_Weapon: String
var Weapon_List = {}

@export var _weapon_resources: Array[Weapon_Resource]
@export var Start_Weapons: Array[String]

enum {NULL, HITSCAN, PROJECTILE}

func _ready():
	Initialize(Start_Weapons) # enter the state machine

func _input(event):
	if (event.is_action_pressed("Weapon_Down")):
		Weapon_Indicator = min(Weapon_Indicator + 1, Weapon_Stack.size() - 1)
		exit(Weapon_Stack[Weapon_Indicator])
		
	if (event.is_action_pressed("Weapon_Up")):
		Weapon_Indicator = max(Weapon_Indicator - 1, 0)
		exit(Weapon_Stack[Weapon_Indicator])
		
	if (event.is_action_pressed("Shoot")):
		shoot()
	
	if (event.is_action_pressed("Reload")):
		reload()
	
	
func Initialize(_start_weapons: Array):
	# init weapon_list dictionary, mapping weapon names to Weapon_Resource
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
	
	for i in _start_weapons:
		Weapon_Stack.push_back(i) # add our start weapons
	
	Current_Weapon = Weapon_List[Weapon_Stack[0]] # set current weapon to first weapon in our stack
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	enter()
	
func enter():
	# called when first "entering" into a weapon
	Animation_Player.queue(Current_Weapon.Activate_Anim)
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	
	pass
	
func Change_Weapon(weapon_name: String):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()
	
func exit(_next_weapon: String):
	# in order to change weapons, call exit
	if _next_weapon != Current_Weapon.Weapon_Name:
		if Animation_Player.get_current_animation() != Current_Weapon.Deactivate_Anim:
			Animation_Player.play(Current_Weapon.Deactivate_Anim)
			Next_Weapon = _next_weapon
	

func _on_animation_player_animation_finished(anim_name):
	if anim_name == Current_Weapon.Deactivate_Anim:
		Change_Weapon(Next_Weapon)
	if anim_name == Current_Weapon.Shoot_Anim and Current_Weapon.Auto_Fire == true:
		if Input.is_action_pressed("Shoot"):
			shoot()
		

func shoot():
	# animation length enforces fire rate
	if Current_Weapon.Current_Ammo != 0 and !Animation_Player.is_playing():
		Animation_Player.play(Current_Weapon.Shoot_Anim)
		Current_Weapon.Current_Ammo -= 1
		emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
		var camera_collision = get_camera_collision()
		match Current_Weapon.Type:
			NULL:
				print("Weapon type not chosen!")
			HITSCAN:
				hitscan_collision(camera_collision)
			PROJECTILE:
				pass
	else:
		reload()
	
func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif !Animation_Player.is_playing():
		if Current_Weapon.Reserve_Ammo != 0:
			Animation_Player.play(Current_Weapon.Reload_Anim)
			var Reload_Amount = min(
					Current_Weapon.Magazine - Current_Weapon.Current_Ammo,
					Current_Weapon.Reserve_Ammo)
			Current_Weapon.Current_Ammo += Reload_Amount
			Current_Weapon.Reserve_Ammo -= Reload_Amount
			
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
		else:
			Animation_Player.play(Current_Weapon.Out_Of_Ammo_Anim)

func get_camera_collision() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	var ray_origin = camera.project_ray_origin(viewport / 2)
	var ray_end = ray_origin + camera.project_ray_normal(viewport / 2) * Current_Weapon.Weapon_Range
	var new_intersection = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var intersection = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	if not intersection.is_empty():
		var collision_point = intersection.position
		return collision_point
	else:
		return ray_end

func hitscan_collision(collision_point):
	var bullet_point_origin = bullet_point.global_position
	var bullet_direction = (collision_point - bullet_point_origin).normalized()
	var new_intersection = PhysicsRayQueryParameters3D.create(bullet_point_origin, collision_point + bullet_direction * 2)
	var bullet_collision = get_world_3d().direct_space_state.intersect_ray(new_intersection)
	
	if bullet_collision:
		var hit_indicator = debug_bullet.instantiate()
		var world = get_tree().get_root().get_child(0)
		world.add_child(hit_indicator)
		hit_indicator.global_translate(bullet_collision.position)
		
		hitscan_damage(bullet_collision.collider)
		
func hitscan_damage(collider):
	if collider.is_in_group("target") and collider.has_method("hit_successful"):
		print("hit")
		collider.hit_successful(Current_Weapon.Damage)
