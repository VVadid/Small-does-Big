extends Thinker

export var max_ammo = 10
var ammo = max_ammo
export var cooldown_time = 0.175
export var reload_time = 1.25
export var ads_dist_ratio = 0.6
export var ads_dist_max = 70
export var ads_zoom = 0.92
export var ads_zoom_speed = 0.2
export var BULLET: PackedScene

onready var cooldown = $cooldown
onready var reload = $reload
onready var spawner = $spawner # used for muzzle flash

func _ready() -> void:
	cooldown.wait_time = cooldown_time
	reload.wait_time = reload_time
	#cooldown.start()

func _on_reload_timeout() -> void:
	ammo = max_ammo
	
	global.emit_signal("update_item_info", # set a condition to null to hide it
		display_name, # current item
		str(ammo) + " / " + str(max_ammo), # extra info 
		null, # item bar max 
		null, # item bar value 
		null # bar timer duration
		)

func get_ready():
	if cooldown.time_left > 0: return false
	elif ammo <= 0: return false
	else: return true

func selected():
	.selected()
	global.emit_signal("update_item_info", # set a condition to null to hide it
		display_name, # current item
		str(ammo) + " / " + str(max_ammo), # extra info 
		null, # item bar max 
		null, # item bar value 
		null # bar timer duration
	)

func unselected():
	reload.stop()
	var camera: Camera2D = refs.camera
	camera.distance_ratio = camera.DEFAULT_DISTANCE_RATIO
	camera.distance_max = camera.DEFAULT_DISTANCE_MAX
	camera.zoom_to(Vector2(1, 1), ads_zoom_speed)

func primary():
	.primary()
	if get_ready() == false:
		if ammo <= 0 && reload.time_left == 0:
			reload()
		return
	
	var bullet: Projectile = BULLET.instance()
	bullet.setup(player, global.get_look_pos())
	refs.ysort.add_child(bullet)
	ammo -= 1
	cooldown.start()
	reload.stop()
	global.emit_signal("update_item_info", # set a condition to null to hide it
		display_name, # current item
		str(ammo) + " / " + str(max_ammo), # extra info 
		null, # item bar max 
		null, # item bar value 
		null # bar timer duration
	)
	spawner.spawn()

func secondary():
	var camera := refs.camera
	
	if Input.is_action_pressed("secondary_action"):
		camera.distance_ratio = ads_dist_ratio
		camera.distance_max = ads_dist_max
		camera.zoom_to(Vector2(ads_zoom, ads_zoom), ads_zoom_speed)
	else:
		camera.distance_ratio = camera.DEFAULT_DISTANCE_RATIO
		camera.distance_max = camera.DEFAULT_DISTANCE_MAX
		camera.zoom_to(Vector2(1, 1), ads_zoom_speed)

func reload():
	if reload.time_left > 0:
		return
	
	.reload()
	reload.start()
	global.emit_signal("update_item_info", # set a condition to null to hide it
		display_name, # current item
		null, # extra info 
		reload.wait_time, # item bar max 
		reload.time_left, # item bar value 
		reload.wait_time # bar timer duration
	)
	
	sound_player.play_sound("reload")
