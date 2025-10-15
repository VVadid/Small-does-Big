extends Node2D

export var LEVEL := "level"
export var DISPLAY_NAME := ""
export var STAR_REQUIREMENT = 0
export var WORLD_ENTRANCE := false
export var CUSTOM_SCENE_PATH := ""
export var REQUIRED_LEVEL := ""
export var CUSTOM_LETTER := ""
export var SET_HUB_POS := true

var player = null
var pressed := false
var open := false
var letter

onready var info = $Node2D/info
onready var header = $Node2D/info/header
onready var sprite = $Area2D/Sprite  # Sprite node with frames

func _ready() -> void:
	if CUSTOM_LETTER != "":
		letter = CUSTOM_LETTER
	elif "LETTER" in get_tree().current_scene:
		letter = get_tree().current_scene.LETTER
	else:
		letter = "A"
	
	if (
		global.stars >= STAR_REQUIREMENT and
		(REQUIRED_LEVEL == "" or REQUIRED_LEVEL in global.cleared_levels)
	):
		open = true
	
	info.visible = false
	var enter_text: String = ""
	
	# Set the correct frame based on level state
	if global.stars < STAR_REQUIREMENT: 
		sprite.frame = 0  # Frame 1 - Locked
		if REQUIRED_LEVEL != "" and not REQUIRED_LEVEL in global.cleared_levels:
			enter_text = "complete %s first" % REQUIRED_LEVEL
		else:
			var missing_stars = STAR_REQUIREMENT - global.stars
			if missing_stars == 1:
				enter_text = "you need 1 more core"
			else:
				enter_text = "you need %s more cores" % missing_stars
	elif global.stars >= STAR_REQUIREMENT: 
		if global.cleared_levels.has(LEVEL):
			if global.perfected_levels.has(LEVEL):
				sprite.frame = 3  # Frame 4 - Perfect
			else:
				sprite.frame = 2  # Frame 3 - Completed
		else:
			sprite.frame = 1  # Frame 2 - Open
		enter_text = "press [E] to enter"
	
	if DISPLAY_NAME == "":
		header.text = LEVEL.to_lower()
	else:
		header.text = DISPLAY_NAME
	header.text += "\n" + enter_text

func _input(event: InputEvent) -> void:
	if player == null or not open:
		return
	
	if Input.is_action_just_pressed("interact"):
		pressed = true
		return
	
	if Input.is_action_just_released("interact") and pressed == true:
		if SET_HUB_POS:
			global.player_hub_pos[letter] = global_position + Vector2(0, 16)
		
		if CUSTOM_SCENE_PATH == "":
			global.goto_scene("res://Levels/%s/%s.tscn" % [letter, LEVEL])
		else:
			global.goto_scene(CUSTOM_SCENE_PATH)

func _on_Area2D_body_entered(body: Node) -> void:
	if refs.player == null: return
	elif body != refs.player: return
	player = body
	info.visible = true

func _on_Area2D_body_exited(body: Node) -> void:
	if refs.player == null: return
	elif body != refs.player: return
	player = null
	info.visible = false
