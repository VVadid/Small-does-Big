extends "res://Components/sound_player/sound_player.gd"

const FOOTSTEP_GRASS = preload("res://Entities/footstep_grass.wav")
const FOOTSTEP_WOOD = preload("res://Entities/footstep_wood.wav")
const FOOTSTEP_STONE = preload("res://Entities/footstep_stone.wav")
const FOOTSTEP_CARPET = preload("res://Entities/footstep_carpet.wav")
const FOOTSTEP_DIRT = preload("res://Entities/footstep_dirt.wav")
const FOOTSTEP_SAND = preload("res://Entities/footstep_sand.wav")
const FOOTSTEP_METAL = preload("res://Entities/footstep_metal.wav")
const FOOTSTEP_SNOW = preload("res://Entities/footstep-snow.wav")

export(float, 0.0, 9.9) var RATE = 0.33
export(float, -9.9, 9.9) var OFFSET = -0.33
export var CONSTANT_RATE = true # PROBLEM_NOTE: setting CONSTANT_RATE to false doesn't work properly
export(float, -84.0, 12.0) var VOLUME_ADJUST = 0

var old_speed = 0
var base_rate = RATE

var playing = false

onready var entity = get_parent()
onready var delay = $delay

func _init():
	OFFSET = clamp(RATE - OFFSET, 0.01, 1.0)

func _ready():
	if RATE == 0:
		delay.queue_free()
		set_process(false)

func _process(_delta: float):
	if RATE == 0: return
	
	if CONSTANT_RATE == false:
		var speed = get_parent().get_speed()
		if speed != old_speed:
			old_speed = speed
			RATE = base_rate * (speed / get_parent().TOP_SPEED)
	
	OFFSET = clamp(RATE - OFFSET, 0.01, 1.0)
	
	if playing == true: return
	elif entity.input_vector != Vector2.ZERO:
		if RATE - OFFSET <= 0: 
			delay.wait_time = 0.001
		else: 
			delay.wait_time = 1 / (RATE - OFFSET)
		delay.start()
		
		playing = true

func _on_delay_timeout() -> void:
	footstep()
	if entity.input_vector == Vector2.ZERO or RATE == 0:
		playing = false
	else:
		delay.wait_time = 1 / RATE
		delay.start()

func footstep():
	var audio
	var bg := refs.background
	if bg == null:
		push_warning("bg == null")
		return
	var bg_tiles = refs.background_tiles
	if bg_tiles == null:
		push_warning("bg_tiles == null")
		return
	
	var cell_id = -1
	cell_id = bg_tiles.get_cellv(bg_tiles.world_to_map(entity.global_position + Vector2(0, 6)))
	
	match cell_id:
		-1: 
			# no tile; use the background TextureRect's id instead
			match bg.ID:
				-1: pass # nothing
				0: audio = FOOTSTEP_GRASS # autumn
				1: audio = FOOTSTEP_STONE # underground
				2: audio = FOOTSTEP_SAND # wasteland
				3: audio = FOOTSTEP_GRASS # offworld
				4: audio = FOOTSTEP_METAL # site
				5: audio = FOOTSTEP_SNOW
		0: audio = FOOTSTEP_DIRT
		1: audio = FOOTSTEP_WOOD
		2: audio = FOOTSTEP_CARPET
		3, 4: audio = FOOTSTEP_METAL
		5: audio = FOOTSTEP_GRASS  # New tile type that uses grass sound
		6: audio = FOOTSTEP_SAND  # New tile type that uses SAND sound
		7: audio = FOOTSTEP_SNOW
		8: audio = FOOTSTEP_SNOW
		9: audio = FOOTSTEP_STONE
	
	if audio == null: return
	
	var sfx = Sound.new()
	sfx.stream = AudioStreamRandomPitch.new()
	sfx.stream.audio_stream = audio
	sfx.volume_db = VOLUME_ADJUST
	sfx.bus = "footsteps"
	add_sound(sfx)
