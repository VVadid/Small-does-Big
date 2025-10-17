extends KinematicBody2D

# Dialogue states
var player_in_range := false
var is_chatting := false
var dialog_node = null

# Add this export for timeline
export(String) var timeline_to_play := ""

# Sprite references
onready var sprite = $Root
onready var shadow = $Root/Shadow
onready var body = $Root/Body
onready var clothes = $Root/Clothes
onready var acc = $Root/Acc
onready var hair = $Root/Hair

# Add this to prevent multiple dialogues
func _ready():
	add_to_group("npc_chat_characters")
	$E.visible

func _process(_delta):
	# Flip all sprite components based on player position
	if player_in_range:
		var player = get_tree().get_nodes_in_group("player")[0]
		var flip_state = player.global_position.x < global_position.x
		sprite.flip_h = flip_state
		shadow.flip_h = flip_state
		body.flip_h = flip_state
		clothes.flip_h = flip_state
		acc.flip_h = flip_state
		hair.flip_h = flip_state
		
	# Show/hide E based on player's movement ability
	if player_in_range:
		var player = get_tree().get_nodes_in_group("player")[0]
		$E.visible = player.movement_enabled
	else:
		$E.visible = false
		
	# Dialogue trigger with additional check
	if (player_in_range and 
		Input.is_action_just_pressed("interact") and 
		!is_chatting and 
		!is_anyone_chatting() and
		player.movement_enabled):  # Only allow interaction if player can move
		prepare_for_dialogue()

# Check if any NPC is already chatting
func is_anyone_chatting() -> bool:
	for npc in get_tree().get_nodes_in_group("npc_chat_characters"):
		if npc.is_chatting:
			return true
	return false

func prepare_for_dialogue():
	is_chatting = true
	var player = get_tree().get_nodes_in_group("player")[0]
	
	# 1. Force idle animation and stop movement
	player.force_idle()  # Calls both animation and movement freeze
	
	# 2. Start dialogue after one frame delay
	yield(get_tree(), "idle_frame")
	start_dialogue()

func start_dialogue():
	var dialog_control = $DialogicControl
	# Use the custom timeline if specified
	if timeline_to_play != "":
		dialog_node = dialog_control.start_specific_dialogue(timeline_to_play)
	else:
		dialog_node = dialog_control.start_dialogue()
		
	dialog_node.connect("timeline_end", self, "_on_dialogue_end", [], CONNECT_ONESHOT)

func _on_dialogue_end(_timeline_name):
	is_chatting = false
	# Re-enable player movement
	var player = get_tree().get_nodes_in_group("player")[0]
	player.enable_movement()
	
	if dialog_node:
		dialog_node.queue_free()

func _on_DetectionArea_body_entered(body):
	if body.has_method("player"):
		player_in_range = true
		# E visibility will be handled in _process based on movement_enabled

func _on_DetectionArea_body_exited(body):
	if body.has_method("player"):
		player_in_range = false
		$E.visible = false
