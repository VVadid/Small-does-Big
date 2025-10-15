extends KinematicBody2D

# Dialogue System Variables
var is_chatting := false
var dialog_node = null

# Exported Configuration
export(NodePath) var player_target_position_path  # For main dialogue
export(NodePath) var no_star_position_path  # For NoStar dialogue
export(String, "Up", "Down") var player_vertical_facing = "Down"
export(AudioStream) var end_dialogue_sound
export(String) var dialogue_id := ""  # Must be unique!
export(bool) var persist_music_after_death := true
export(int) var required_stars := 0  # Number of stars needed to activate main dialogue
export(String) var no_star_dialogue := "NoStar"  # Timeline to play when not enough stars

func _ready():
	add_to_group("npc_chat_characters")
	# Generate stable unique ID if not set
	if dialogue_id == "":
		dialogue_id = "npc_%s_%s" % [name, str(get_path()).hash()]

func _on_DetectionArea_body_entered(body):
	if (body.is_in_group("player") 
		and !is_chatting 
		and !is_anyone_chatting()
		and !global.played_dialogues.get(dialogue_id, false)):
		
		if global.stars >= required_stars:
			prepare_for_dialogue(body)
		else:
			play_no_star_dialogue(body)

func play_no_star_dialogue(player):
	is_chatting = true
	player.disable_movement()
	
	# Move player to no star position if specified
	if no_star_position_path:
		var target_position = get_node(no_star_position_path).global_position
		yield(move_player_to_position(player, target_position), "completed")
	
	# Final preparation before dialogue
	player.velocity = Vector2.ZERO
	player.input_vector = Vector2.ZERO
	player.set_physics_process(false)
	set_player_facing(player)
	yield(get_tree(), "idle_frame")
	
	# Start the "NoStar" dialogue
	var dialog_control = $DialogicControl
	dialog_node = dialog_control.start_specific_dialogue(no_star_dialogue)
	dialog_node.connect("timeline_end", self, "_on_no_star_dialogue_end", [player], CONNECT_ONESHOT)
	global.is_player_in_dialogue = true

func _on_no_star_dialogue_end(_timeline_name, player):
	global.is_player_in_dialogue = false
	is_chatting = false
	if is_instance_valid(player):
		player.enable_movement()
	
	# Don't queue_free here - we want to keep the NPC for future interactions
	if dialog_node:
		dialog_node.queue_free()

func is_anyone_chatting() -> bool:
	for npc in get_tree().get_nodes_in_group("npc_chat_characters"):
		if npc.is_chatting:
			return true
	return false

func prepare_for_dialogue(player):
	is_chatting = true
	player.disable_movement()
	
	# Player movement if specified
	if player_target_position_path:
		var target_position = get_node(player_target_position_path).global_position
		yield(move_player_to_position(player, target_position), "completed")
	
	# Final preparation before dialogue
	player.velocity = Vector2.ZERO
	player.input_vector = Vector2.ZERO
	player.set_physics_process(false)
	set_player_facing(player)
	yield(get_tree(), "idle_frame")
	
	start_dialogue(player)

func set_player_facing(player):
	match player_vertical_facing:
		"Up":
			player.last_movement_was_upward = true
			player.play_animation("stand_back")
		"Down":
			player.last_movement_was_upward = false
			player.play_animation("stand")

func move_player_to_position(player, target_pos):
	player.set_physics_process(true)
	player.movement_enabled = true
	
	var distance_threshold = 5.0
	while player.global_position.distance_to(target_pos) > distance_threshold:
		var direction = (target_pos - player.global_position).normalized()
		player.input_vector = direction
		player.move_and_slide(player.input_vector * player.speed)
		yield(get_tree(), "physics_frame")
	
	player.velocity = Vector2.ZERO
	player.input_vector = Vector2.ZERO
	player.disable_movement()

func start_dialogue(player):
	# Mark as played immediately when dialogue starts
	global.played_dialogues[dialogue_id] = true
	
	# Start Dialogic dialogue
	dialog_node = $DialogicControl.start_dialogue()
	dialog_node.connect("timeline_end", self, "_on_dialogue_end", [player], CONNECT_ONESHOT)
	global.is_player_in_dialogue = true
	
	# Pause enemy targeting
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_node("Brain"):
			var brain = enemy.get_node("Brain")
			var player_ref = get_tree().get_nodes_in_group("player")[0]
			if brain.targets.has(player_ref):
				brain.remove_target(player_ref)

func _on_dialogue_end(_timeline_name, player):
	global.is_player_in_dialogue = false
	
	# Play end sound if available
	if end_dialogue_sound:
		if persist_music_after_death:
			global.play_persistent_sound(end_dialogue_sound)
		else:
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = end_dialogue_sound
			get_tree().root.add_child(audio_player)
			audio_player.play()
			audio_player.connect("finished", audio_player, "queue_free")
	
	# Cleanup
	is_chatting = false
	if is_instance_valid(player):
		player.enable_movement()
	
	if dialog_node:
		dialog_node.queue_free()
	
	queue_free()
