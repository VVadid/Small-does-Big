extends Light2D
class_name LightSource
# the only reason i can't use Light2D's is because i can't have those auto adjust (easily) based
# on the game options

const LIGHT_TEXTURE := preload("res://Effects/light.png")

export var CUSTOM_PROPERTIES := false

func _init() -> void:
	add_to_group("lights")

func _ready() -> void:
	enabled = global.settings["lighting"]
	
	if CUSTOM_PROPERTIES == true:
		return
	
	#if texture == null:
	texture = LIGHT_TEXTURE
	
	shadow_enabled = global.settings["shadows"]
	shadow_buffer_size = global.settings["shadow_buffer"]
	
	# lowers saturation in daylight, otherwise it looks weird
	match get_tree().current_scene.AMBIENT_LIGHTING:
		1: color.s *= 0.5 # autumn
		3: color.s *= 0.65 # wasteland
