extends Entity

const ROCKET := preload("res://Entities/Attacks/Projectile/rocket/rocket.tscn")
const SKELETON := preload("res://Entities/skeleton/skeleton.tscn")
const POISON_DROP := preload("res://Entities/Attacks/Projectile/poison_drop/poison_drop.tscn")

export var lunge_force: float
export var rage_threshold: int
export var rage_speed_mult: float
export var burrow_speed_mult: float

onready var animation: AnimationPlayer = $AnimationPlayer
onready var stats: Node = $stats
onready var collision: CollisionShape2D = $CollisionShape2D
onready var original_top_speed: int = TOP_SPEED

var attacking := false
var target_path: NodePath
var enraged := false
var queued_burrow := false

func set_attacking(to: bool):
	attacking = to

func _physics_process(delta: float) -> void:
	if attacking == false:
		if input_vector == Vector2.ZERO:
			animation.play("stand")
		else:
			animation.play("walk")

func _on_action_lobe_action(action, target) -> void:
	if attacking == true:
		return
	target_path = target.get_path()
	attacking = true
	TOP_SPEED = 0
	animation.play(action)

func lunge():
	var target: Entity = get_node_or_null(target_path)
	if target != null:
		apply_force(global_position.direction_to(target.global_position).normalized() * lunge_force)

func shoot():
	var target: Entity = get_node_or_null(target_path)
	if target != null:
		var rocket: Projectile = ROCKET.instance()
		rocket.setup(self, target.global_position)
		refs.ysort.add_child(rocket)

func burrow():
	var skele: Entity = SKELETON.instance()
	skele.position = global_position
	skele.marked_allies.append(self)
	marked_allies.append(skele)
	refs.ysort.add_child(skele)
	
	var target: Entity = get_node_or_null(target_path)
	if target != null:
		var target_pos: Vector2 = global_position.move_toward(target.global_position, 110)
		var ss := get_world_2d().direct_space_state
		while true:
			var test := ss.intersect_ray(target_pos.move_toward(global_position, 20), target_pos,[], 1)
			if test.has("collider"):
				target_pos = target_pos.move_toward(global_position, 16)
			else:
				break
		global_position = target_pos

func poison():
	var directions := [
		Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(1, -1), Vector2(0, -1), Vector2(-1, -1),
		Vector2(-1, 0), Vector2(-1, 1)
	]
	for i in 8:
		var poison: Projectile = POISON_DROP.instance()
		poison.setup(self, global_position + directions[i] * 99)
		refs.ysort.add_child(poison)

func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if queued_burrow == false:
		TOP_SPEED = original_top_speed
		attacking = false
	elif queued_burrow == true:
		queued_burrow = false
		attacking = true
		TOP_SPEED = 0
		animation.play("burrow")

func _on_hurtbox_got_hit(by_area, type) -> void:
	if stats.HEALTH <= rage_threshold and enraged == false:
		original_top_speed *= rage_speed_mult
		TOP_SPEED = original_top_speed
		$brain/action_lobe/attack.COOLDOWN *= 1.0 - abs(rage_speed_mult - 1.0)
		$brain/action_lobe/shoot.COOLDOWN *= 1.0 - abs(rage_speed_mult - 1.0)
		animation.playback_speed = rage_speed_mult
		enraged = true

func _on_brain_lost_target() -> void:
	if not attacking:
		attacking = true
		TOP_SPEED = 0
		animation.play("burrow")
	else:
		var target: Entity = get_node_or_null(target_path)
		if target == null:
			return
		elif is_inside_tree():
			var ss := get_world_2d().direct_space_state
			if ss.intersect_ray(global_position, target.global_position, [], 1).has("collider"):
				queued_burrow = true
