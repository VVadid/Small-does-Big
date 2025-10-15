extends "res://Entities/Item_Pickups/item.gd"

export(int) var healing := 1

func on_pickup(player):
	if player.components["stats"] == null:
		return
	
	player.stats.MAX_HEALTH += 1
	player.components["stats"].change_health(healing, 0, "heal")
	queue_free()
