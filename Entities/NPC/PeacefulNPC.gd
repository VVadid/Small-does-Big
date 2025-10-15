extends KinematicBody2D

# Dialogue lines (edit these)
export(Array, String) var dialogue = [
	"Hello traveler!",
	"Nice weather today."
]

onready var sprite = $Sprite
var player_in_range = false
var player_ref = null

func _ready():
	$InteractionArea.connect("body_entered", self, "_on_player_entered")
	$InteractionArea.connect("body_exited", self, "_on_player_exited")

func _process(_delta):
	if player_ref:
		# Flip sprite to face player
		sprite.flip_h = player_ref.global_position.x < global_position.x

func _on_player_entered(body):
	if body.name == "Player":
		player_in_range = true
		player_ref = body

func _on_player_exited(body):
	if body.name == "Player":
		player_in_range = false
		player_ref = null

func _input(event):
	if event.is_action_pressed("interact") and player_in_range:
		show_dialogue()

func show_dialogue():
	var dialogue_box = preload("res://UI/DialogueBox/DialogueBox.tscn").instance()
	get_parent().add_child(dialogue_box)
	dialogue_box.start_dialogue(dialogue)
