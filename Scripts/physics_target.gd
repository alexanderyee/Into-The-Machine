extends CSGBox3D

var health = 99

func hit_successful(damage):
	health -= damage
	print("target health: " + str(health))
	if health <= 0:
		queue_free()
