extends Entity

# Configure these in the inspector
export(PackedScene) var KNIGHT_SCENE = preload("res://Entities/chaser/PlasticBottle.tscn")
export(PackedScene) var ARCHER_SCENE = preload("res://Entities/chaser/brute_chaser/brute_chaser.tscn")

onready var stats = $stats
onready var cooldown = $cooldown
onready var animation = $AnimationPlayer
onready var brain = $brain
onready var audio_player = $AudioStreamPlayer2D

export(float, 0.01, 20.0) var cooldown_time = 3.8
export(float, 0.01, 3.0) var anger_cooldown_multiplier = 0.5
export(float, 10, 50) var summon_distance = 30.0
export var summon_pattern = "random" # circle, line, semicircle, random
export(AudioStream) var summon_sound
export(float, -80, 24) var sound_volume_db = 0.0

var stored_input
var pattern_rotations = {
	"circle": [0, 120, 240],
	"line": [0, 180, 0],
	"semicircle": [45, 90, 135],
	"random": []
}

func summon():
	if not stored_input:
		return
	
	# Play summon sound
	if summon_sound and audio_player:
		audio_player.stream = summon_sound
		audio_player.volume_db = sound_volume_db
		audio_player.play()
	
	var pattern = pattern_rotations[summon_pattern]
	
	for i in range(3):  # Always summon 3 enemies like original
		var guard: Entity = null
		
		match stored_input:
			"knight":
				if KNIGHT_SCENE:
					guard = KNIGHT_SCENE.instance()
				else:
					push_error("Knight scene not assigned")
			"archer":
				if ARCHER_SCENE:
					guard = ARCHER_SCENE.instance()
				else:
					push_error("Archer scene not assigned")
		
		if not is_instance_valid(guard):
			continue
			
		get_parent().add_child(guard)
		guard.owner = get_tree().current_scene
		
		guard.global_position = calculate_spawn_position(i, pattern)
		guard.faction = faction
		guard.marked_enemies = marked_enemies.duplicate()
		guard.marked_allies = marked_allies.duplicate()
		
		var force_direction = (guard.global_position - global_position).normalized()
		guard.apply_force(force_direction * 120)
	
	cooldown.start()

func calculate_spawn_position(index: int, pattern: Array) -> Vector2:
	var spawn_pos = global_position
	if summon_pattern == "random":
		spawn_pos += Vector2(rand_range(-1, 1), rand_range(-1, 1)).normalized() * summon_distance
	else:
		var angle_deg = pattern[index]
		var angle_rad = deg2rad(angle_deg)
		spawn_pos += Vector2(cos(angle_rad), sin(angle_rad)) * summon_distance
	return spawn_pos

func _on_stats_health_changed(_type, _result, _net) -> void:
	if stats.HEALTH < stats.MAX_HEALTH / 2:
		cooldown.wait_time = cooldown_time * anger_cooldown_multiplier

func _on_action_lobe_action(action, target) -> void:
	if cooldown.time_left > 0 or animation.is_playing():
		return
		
	if action == "slam":
		animation.play("slam")
	else:
		stored_input = action
		animation.play("summon")
