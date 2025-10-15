extends Entity

enum S {
	DOWN,
	UP
}

export(S) var state:int

onready var brain := $brain
onready var animation := $AnimationPlayer
onready var sound_player := $sound_player
onready var cooldown := $cooldown
onready var down_timer := Timer.new()  # Add a timer for the delay

func _ready():
	# Configure and add the down timer
	down_timer.wait_time = 0.01  # 1 second delay
	down_timer.one_shot = true
	add_child(down_timer)
	down_timer.connect("timeout", self, "_on_down_timer_timeout")

func _on_brain_think() -> void:
	if state == S.UP and brain.targets.size() == 0:
		# lower - but first wait 1 second
		if cooldown.time_left != 0:
			cooldown.start()
			return
		if not down_timer.is_stopped():
			return  # Already waiting to go down
		down_timer.start()  # Start the 1 second delay
	elif state == S.DOWN and brain.targets.size() != 0:
		# rise - immediate
		down_timer.stop()  # Cancel any pending down action
		animation.play("rise")
		sound_player.play_sound("rise")
		state = S.UP  # Make sure to update the state

func _on_down_timer_timeout():
	# This is called after the 1 second delay
	animation.play_backwards("rise")
	sound_player.play_sound("lower")
	state = S.DOWN  # Make sure to update the state

var chaser: Entity
func _process(_delta: float) -> void:
	chaser = refs.ysort.find_node("chaser", true)
	if chaser:
		brain.add_target(chaser)
