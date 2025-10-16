extends Area2D

export var trash_type = "plastic"  # plastic, paper, organic, etc.

onready var sprite = $Sprite  # Make sure you have a Sprite node

func _ready():
	add_to_group("trash")
	connect("body_entered", self, "_on_body_entered")
	
	# Randomize the sprite frame when spawned
	randomize_sprite_frame()

func randomize_sprite_frame():
	if sprite and sprite.hframes > 1:
		# Set a random frame from available frames (0 to hframes-1)
		var random_frame = randi() % sprite.hframes
		sprite.frame = random_frame
		print("Trash spawned with frame: ", random_frame)  # Optional debug

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Player is near trash - ready for E key pickup
		pass

func collect_trash(player):
	# Add to environmental score
	if has_node("/root/EnvironmentalManager"):
		get_node("/root/EnvironmentalManager").on_trash_collected()
	
	# Visual feedback
	show_collection_effect()
	
	# Remove the trash
	queue_free()

func show_collection_effect():
	# Create a simple collection effect
	var effect = Node2D.new()
	get_parent().add_child(effect)
	
	var label = Label.new()
	label.text = "+1"
	label.add_color_override("font_color", Color(0, 1, 0))
	label.rect_position = global_position - Vector2(10, 20)
	effect.add_child(label)
	
	# Animate and remove
	var tween = Tween.new()
	effect.add_child(tween)
	tween.interpolate_property(label, "rect_position", 
		label.rect_position, label.rect_position - Vector2(0, 30), 0.8)
	tween.interpolate_property(label, "modulate", 
		Color(1,1,1,1), Color(1,1,1,0), 0.8)
	tween.start()
	
	yield(tween, "tween_completed")
	effect.queue_free()
