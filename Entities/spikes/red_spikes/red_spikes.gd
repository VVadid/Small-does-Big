extends Entity

onready var activation := $activation as Area2D
onready var animation := $AnimationPlayer as AnimationPlayer

func _ready():
	$pokey.visible = false

func _on_activation_body_entered(body: Node) -> void:
	if animation.is_playing() == true:
		return
	
	var ss = get_world_2d().direct_space_state
	var raycast = ss.intersect_ray(global_position, body.global_position, [], 1)
	if raycast and raycast.collider == refs.world_tiles:
		return
	
	animation.play("spikes")
	activation.queue_free()
