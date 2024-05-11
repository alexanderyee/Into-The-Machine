extends CanvasLayer

@onready var CurrentWeaponLabel = $"VBoxContainer/HBoxContainer/Current Weapon"
@onready var AmmoLabel = $VBoxContainer/HBoxContainer2/Ammo
@onready var WeaponStackLabel = $"VBoxContainer/HBoxContainer3/Weapon Stack"



func _on_weapons_manager_update_ammo(Ammo):
	AmmoLabel.set_text(str(Ammo[0]) + " / " + str(Ammo[1]))


func _on_weapons_manager_update_weapon_stack(Weapon_Stack):
	WeaponStackLabel.set_text("")
	for weapon_string in Weapon_Stack:
		WeaponStackLabel.text += "\n" + weapon_string
	

func _on_weapons_manager_weapon_changed(Weapon_Name):
	CurrentWeaponLabel.set_text(Weapon_Name)
