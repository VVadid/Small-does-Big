extends Node2D

enum TT {
	CURSOR,
	INPUT_VECTOR,
	BRAIN_TARGET,
	MANUAL
}

export(TT) var TARGETING = TT.INPUT_VECTOR
export var PARENT_BOND = true
export var DEFAULT_HFRAMES = 1
export var DEFAULT_VFRAMES = 1
export var ROTATION_DEADZONE := 5.0 # Degrees where we won't rotate to prevent jitter
export var COYOTE_TIME := 0.15 # Time buffer when changing directions
export var ROTATION_LERP_SPEED := 10.0 # Smooth rotation speed
export var MAINTAIN_LAST_DIRECTION := true # If false, resets to forward when no input

var target_pos = Vector2.ZERO
var source
var reversed = false
var original_offset: Vector2
var original_texture: Texture
var coyote_timer := 0.0
var last_valid_direction := Vector2.RIGHT # Default to facing right
var is_rotating := false

onready var entity = get_parent()
onready var sprite = $anchor/sprite
onready var anchor = $anchor
onready var animation: AnimationPlayer = $AnimationPlayer

signal cant_rotate
signal rotation_started
signal rotation_ended

func _on_held_item_tree_entered():
	get_parent().components["held_item"] = self

func _ready():
	sprite.hframes = DEFAULT_HFRAMES
	sprite.vframes = DEFAULT_VFRAMES
	sprite.frame = 0
	sprite.frame_coords = Vector2.ZERO
	original_offset = sprite.offset
	
	if PARENT_BOND == false:
		source = self
	else:
		if not entity is Node2D:
			source = self
			push_error("held_item could not be bound to parent because parent isn't 2D")
			OS.alert("held_item could not be bound to parent because parent isn't 2D","error")
		else:
			source = entity

func _physics_process(delta: float) -> void:
	if TARGETING != TT.MANUAL and visible:
		update_target_position(delta)
		handle_rotation(delta)
		update_sprite_flipping()
		update_depth_rendering()

func update_target_position(delta: float) -> void:
	match TARGETING:
		TT.CURSOR:
			target_pos = global.get_look_pos()
			coyote_timer = COYOTE_TIME
			last_valid_direction = global_position.direction_to(target_pos)
		
		TT.INPUT_VECTOR:
			if source.input_vector != Vector2.ZERO:
				last_valid_direction = source.input_vector
				coyote_timer = COYOTE_TIME
				target_pos = source.global_position + last_valid_direction * 10
			elif coyote_timer > 0:
				# Coyote time active
				coyote_timer -= delta
				target_pos = source.global_position + last_valid_direction * 10
			elif MAINTAIN_LAST_DIRECTION:
				# Maintain position without updating target
				return
			else:
				# Reset to default forward position
				target_pos = source.global_position + Vector2.RIGHT * 10
		
		TT.BRAIN_TARGET:
			if entity.components["brain"] == null:
				push_error("Can't use BRAIN_TARGET without a brain, switching to INPUT_VECTOR")
				TARGETING = TT.INPUT_VECTOR
				return
			
			if entity.components["brain"].targets.size() > 0:
				var closest_target = entity.components["brain"].get_closest_target()
				if closest_target is Entity:
					target_pos = closest_target.global_position
					last_valid_direction = global_position.direction_to(target_pos)
					coyote_timer = COYOTE_TIME
				else:
					emit_signal("cant_rotate")

func handle_rotation(delta: float) -> void:
	var new_direction = global_position.direction_to(target_pos)
	var target_angle = rad2deg(new_direction.angle())
	var current_angle = rotation_degrees
	
	# Normalize angles for comparison
	var angle_diff = abs(fmod(target_angle - current_angle + 180, 360) - 180)
	
	# Only rotate if beyond deadzone
	if angle_diff > ROTATION_DEADZONE:
		if not is_rotating:
			emit_signal("rotation_started")
			is_rotating = true
		
		# Smooth rotation with lerp
		rotation_degrees = lerp_angle(
			deg2rad(current_angle), 
			deg2rad(target_angle), 
			ROTATION_LERP_SPEED * delta
		)
		rotation_degrees = rad2deg(rotation_degrees)
	elif is_rotating:
		emit_signal("rotation_ended")
		is_rotating = false

func update_sprite_flipping() -> void:
	var should_flip = facing_left()
	
	# Handle base flipping (before reversed flag)
	sprite.flip_v = should_flip
	sprite.offset = original_offset * (-1 if should_flip else 1)
	
	# Apply reversed flag if needed
	if reversed:
		sprite.flip_v = not sprite.flip_v
		sprite.offset *= -1

func facing_left() -> bool:
	# Normalize angle to 0-360 range
	var normalized_angle = fmod(rotation_degrees, 360)
	if normalized_angle < 0:
		normalized_angle += 360
	
	# Left side is between 90 and 270 degrees
	return normalized_angle > 90 and normalized_angle < 270

func update_depth_rendering() -> void:
	show_behind_parent = rotation_degrees < 0

func _on_AnimationPlayer_animation_started(_anim_name: String) -> void:
	original_texture = sprite.texture

func force_rotation(direction: Vector2) -> void:
	"""Forces immediate rotation to face a direction"""
	last_valid_direction = direction
	target_pos = global_position + direction * 10
	rotation_degrees = rad2deg(direction.angle())
	coyote_timer = COYOTE_TIME
