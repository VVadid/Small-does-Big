# Melee.gd - Fixed Version
extends Attack
class_name Melee

export(bool) var HOLDS := false
export(int, 0, 200) var RECOIL := 70
export(bool) var ANIMATION_NEVER_BACKWARDS := false
export(bool) var HIDE_HELD_ITEM := true
export(bool) var REVERSE_HELD_ITEM := true

var recoiled := false
var held_item_was_visible := true  # Track original visibility

onready var animation: AnimationPlayer = $animation
onready var sprite: Sprite = $entity_sprite

func setup(new_source := Entity.new(), new_target_pos := Vector2.ZERO):
	.setup(new_source, new_target_pos)
	start_pos = SOURCE.global_position + RANGE * DIRECTION
	visible = false
	
	# Store original visibility state
	if is_instance_valid(SOURCE) and SOURCE.get("components") and SOURCE.components.has("held_item"):
		var held_item = SOURCE.components.held_item
		if is_instance_valid(held_item):
			held_item_was_visible = held_item.visible

func _ready():
	if not is_instance_valid(SOURCE):
		if has_node(SOURCE_PATH):
			SOURCE = get_node(SOURCE_PATH)
		else:
			queue_free()
			return
	
	var held_item = SOURCE.get("components").get("held_item") if SOURCE.get("components") else null
	
	if is_instance_valid(held_item) and HIDE_HELD_ITEM:
		held_item.visible = false
		if held_item.has_node("sprite"):
			held_item.get_node("sprite").visible = false
	
	# Ensure animations exist before playing
	if not animation.has_animation("animation"):
		push_error("Missing 'animation' in AnimationPlayer")
	if not animation.has_animation("animation_reverse"):
		push_error("Missing 'animation_reverse' in AnimationPlayer")
	
	if REVERSE_HELD_ITEM and is_instance_valid(held_item):
		var facing_left = held_item.call("facing_left") if held_item.has_method("facing_left") else false
		
		if facing_left and not ANIMATION_NEVER_BACKWARDS:
			if animation.has_animation("animation"):
				animation.play("animation")
				sprite.position = Vector2(0, -4)
				sprite.rotation_degrees = 0
			else:
				animation.play("RESET")
		else:
			if animation.has_animation("animation_reverse"):
				animation.play("animation_reverse")
				sprite.position = Vector2(0, 4)
				sprite.rotation_degrees = 180
			else:
				animation.play("RESET")
	else:
		if animation.has_animation("animation"):
			animation.play("animation")
		else:
			animation.play("RESET")
	
	visible = true

func _physics_process(_delta):
	if get_node_or_null(SOURCE_PATH) != null and not SOURCE.is_queued_for_deletion():
		global_position = SOURCE.global_position + RANGE * DIRECTION

func death():
	.death()
	
	if get_node_or_null(SOURCE_PATH) != null and not SOURCE.is_queued_for_deletion() and not recoiled:
		SOURCE.apply_force(target_pos.direction_to(SOURCE.global_position).normalized() * RECOIL)
		recoiled = true
	
	if components["hitbox"] != null:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	
	# Delay freeing to ensure visibility restoration
	yield(get_tree().create_timer(0.1), "timeout")
	if death_free:
		queue_free()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if not visible: return
	if global.get_relation(self, area.get_parent()) == "friendly": return
	if "PENETRATES" in area.get_parent(): return
	
	if get_node_or_null(SOURCE_PATH) != null and not SOURCE.is_queued_for_deletion() and not recoiled:
		SOURCE.apply_force(global_position.direction_to(SOURCE.global_position).normalized() * RECOIL)
		recoiled = true

func collided():
	.collided()
	if not visible: return
	
	if get_node_or_null(SOURCE_PATH) != null:
		var spark: Effect = BLOCK_SPARK.instance()
		spark.rotation_degrees = rad2deg(SOURCE.global_position.direction_to(global_position).angle())
		refs.ysort.call_deferred("add_child", spark)
		yield(spark, "ready")
		spark.global_position = global_position.move_toward(target_pos, RANGE)

func _on_Melee_tree_exiting():
	if is_instance_valid(SOURCE) and not SOURCE.is_queued_for_deletion():
		var held_item = SOURCE.get("components").get("held_item") if SOURCE.get("components") else null
		
		if is_instance_valid(held_item):
			# Restore original visibility state
			held_item.visible = held_item_was_visible
			if held_item.has_node("sprite"):
				held_item.get_node("sprite").visible = held_item_was_visible
			
			if REVERSE_HELD_ITEM:
				held_item.set("reversed", not held_item.get("reversed"))
				if held_item.has_node("sprite"):
					var sprite = held_item.get_node("sprite")
					sprite.flip_v = not sprite.flip_v
					sprite.offset *= -1

func _on_animation_animation_finished(anim_name: String) -> void:
	# Small delay before freeing to ensure everything completes
	yield(get_tree().create_timer(0.05), "timeout")
	queue_free()
