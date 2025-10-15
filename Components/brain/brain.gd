extends Node2D

onready var think_timer = $think_timer
onready var sight = $sight
var movement_lobe: Node
var action_lobe: Node
var memory_lobe: Node
var warning_lobe: Node
var communication_lobe: Node

export(int, 0, 20) var TOLERANCE
export(float, 0.01666, 1.0) var THINK_TIME
export(float, 0, 300) var SIGHT_RANGE
export(int, 1, 99) var MAX_TARGETS
export(bool) var SIGHT_EFFECTS := true
export(bool) var WALLHACKS := false
export var IGNORE_ATTACKS := true
export var IGNORE_INANIMATE := true
export var IGNORE_UNFACTIONED := true
export var IGNORE_ALLIES := true
export var BLACKLIST := []
export var EXCLAIMATION: PackedScene
export var QUESTION: PackedScene
var excluded := []
var targets := []
var target_paths := []
var entities := []
var entity: Entity

signal found_target
signal lost_target
signal think

func _on_brain_tree_entered():
	entity = get_parent()
	entity.components["brain"] = self
	excluded.append(weakref(entity))

func _ready():
	think_timer.wait_time = THINK_TIME
	sight.scale = Vector2(SIGHT_RANGE, SIGHT_RANGE)
	excluded.append(weakref(entity))

func get_closest_target(exclude_self:=true) -> Entity:
	var target: Entity
	var dist = 999
	for i in targets.size():
		if get_node_or_null(target_paths[i]) != null:
			if exclude_self == true and targets[i] == entity:
				continue
			elif global_position.distance_to(targets[i].global_position) < dist:
				target = targets[i]
				dist = global_position.distance_to(targets[i].global_position)
	return target

func is_target_valid(index: int) -> bool:
	if index > targets.size() - 1 or index > target_paths.size() -1:
		return false
	
	var target = targets[index]
	
	if get_node_or_null(target_paths[index]) == null:
		return false
	elif target.is_queued_for_deletion():
		return false
	elif target in entity.marked_allies and IGNORE_ALLIES == true:
		return false
	elif los_check(target) == false and global_position.distance_to(target.global_position) >= 5:
		return false
	else:
		return true

func los_check(target, ignore_low_barriers := true) -> bool:
	if WALLHACKS == true:
		return true
	
	var mask := 3
	if ignore_low_barriers == false:
		mask += 32
	
	var target_pos = target
	if target is Entity:
		target_pos = target.global_position
	
	var excludes := []
	for i in range(excluded.size()-1, -1, -1):
		var excluded_entity = excluded[i].get_ref()
		if excluded_entity == null:
			excluded.remove(i)
		elif not (target is Entity and entity == target):
			excludes.append(excluded_entity)
	
	var ss = get_world_2d().direct_space_state
	var vision = ss.intersect_ray(target_pos, global_position, excludes, mask)
	
	while (
		vision and
		vision.collider is Entity and
		vision.collider.get_collision_mask_bit(1) == false and
		vision.collider.global_position != target_pos
	):
		excludes.append(vision.collider)
		vision = ss.intersect_ray(target_pos, global_position, excludes, mask)
	
	if vision == {}:
		return false
	else:
		vision = ss.intersect_ray(global_position.move_toward(target_pos, 2.5), target_pos, excludes, mask)
	
	if vision:
		if vision.collider is TileMap:
			return false
		elif target is Entity and vision.collider == target and target.INVISIBLE == false:
			return true
		elif target is Vector2 and vision.collider.global_position == target:
			return true
		else:
			return false
	else:
		if target is Entity:
			return false
		elif target is Vector2:
			return true
	
	push_warning("los_check missed all conditions")
	return false

func add_target(tar: Entity, force = false) -> void:
	# Only modification - skip player during dialogue
	if tar.truName == "player" and global.is_player_in_dialogue:
		return
	
	if (
		not tar == entity and
		(movement_lobe != null and movement_lobe.get_spring(tar) == null) or
		force == false and
		(tar is Attack and IGNORE_ATTACKS == true) or
		(tar.faction == "" and IGNORE_UNFACTIONED == true) or
		(tar.INANIMATE == true and IGNORE_INANIMATE == true) or
		tar.truName in BLACKLIST or tar.faction in BLACKLIST or
		(global.get_relation(entity, tar) == "friendly" and IGNORE_ALLIES == true)
	):
		excluded.append(weakref(tar))
		return
	elif targets.size() >= MAX_TARGETS:
		return
	
	targets.append(tar)
	target_paths.append(tar.get_path())
	if movement_lobe != null:
		movement_lobe.best_position_paths.append(null)
	
	if is_target_valid(targets.size()-1) == false and force == false:
		targets.pop_back()
		target_paths.pop_back()
		if movement_lobe != null:
			movement_lobe.best_position_paths.pop_back()
		return
	
	if movement_lobe != null:
		movement_lobe.idle_timer.stop()
		movement_lobe.wander_timer.stop()
	
	emit_signal("found_target")
	
	if tar.truName == "player":
		spawn_effect("exclaimation", global_position.move_toward(tar.global_position, 32))

func remove_target(tar):
	if targets == []: return
	
	var target = null
	var target_id = 0
	if tar is int and not targets.size()-1 < tar:
		target_id = tar
		target = targets[target_id]
	elif is_instance_valid(tar):
		target = tar
		target_id = targets.find(target)
	
	if target_id == -1 or target == null: return
	
	if movement_lobe != null and memory_lobe != null:
		if movement_lobe.get_spring(targets[target_id]) != null and memory_lobe.MEMORY_TIME > 0:
			if get_node_or_null(target_paths[target_id]) == null: return
			if entity.is_queued_for_deletion() == true: return
			
			movement_lobe.best_position_paths.remove(target_id)
			memory_lobe.add_memory(targets[target_id].global_position,
				movement_lobe.get_spring(targets[target_id]),
				targets[target_id].get_instance_id()
			)
			
			if targets[target_id].truName == "player":
				spawn_effect("question", global_position.move_toward(targets[target_id].global_position, 32))
	
	targets.remove(target_id)
	target_paths.remove(target_id)
	emit_signal("lost_target")
	
	if targets == []:
		entity.input_vector = Vector2.ZERO
		if movement_lobe != null and movement_lobe.wander_timer.is_inside_tree() == true:
			movement_lobe.wander_timer.start()

func _on_sight_body_entered(body: Node) -> void:
	# Only modification - skip player during dialogue
	if body.truName == "player" and global.is_player_in_dialogue:
		return
	
	if (
		body is Entity and
		not body == entity and
		not body in entities and
		not (body is Attack and IGNORE_ATTACKS == true) and
		not (body.faction == "" and IGNORE_UNFACTIONED == true) and
		not (body.INANIMATE == true and IGNORE_INANIMATE == true) and
		not (body.truName in BLACKLIST or body.faction in BLACKLIST) and
		not (global.get_relation(entity, body) == "friendly" and IGNORE_ALLIES == true)
	):
		entities.append(body)
	
	if body.is_queued_for_deletion() == false and los_check(body) == true:
		add_target(body)

func _on_sight_body_exited(body: Node) -> void:
	var body_id = entities.find(body)
	if body_id != -1:
		entities.remove(body_id)
	
	remove_target(body)

func _on_think_timer_timeout() -> void:
	think_timer.wait_time = THINK_TIME + rand_range(-0.1, 0.1)
	
	if entity.components["sleeper"] != null:
		if entity.components["sleeper"].active == false:
			return
	
	emit_signal("think")
	
	for body in entities:
		if not targets.has(body) and body.is_queued_for_deletion() == false:
			add_target(body)
	
	for i in targets.size():
		if is_target_valid(i) == false:
			remove_target(i)

func spawn_effect(effect: String, pos: Vector2):
	if SIGHT_EFFECTS == false:
		return
	
	var new_effect: Effect
	match effect:
		"exclaimation": new_effect = EXCLAIMATION.instance()
		"question": new_effect = QUESTION.instance()
	
	refs.ysort.call_deferred("add_child", new_effect)
	new_effect.global_position = pos

func get_target_names() -> Array:
	var names := []
	for target in targets:
		names.append(target.get_name())
	return names
