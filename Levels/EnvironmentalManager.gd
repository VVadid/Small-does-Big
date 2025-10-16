extends Node

# Environmental Scoring System
var environmental_score = 0
var trash_collected_this_level = 0
var total_trash_in_level = 0
var completion_threshold = 0.8  # 80% for good ending

# Visual state tracking
var world_visual_state = 0  # 0=bad, 1=neutral, 2=good

# Educational facts
var environmental_facts = [
	"Plastic bottles take 450 years to decompose in nature.",
	"Recycling one aluminum can saves enough energy to run a TV for 3 hours.",
	"Over 1 million marine animals die each year from plastic pollution.",
	"Norway recycles 97% of its plastic bottles through a deposit system.",
	"Food waste in landfills produces methane, a powerful greenhouse gas."
]

# Signals
signal score_changed(new_score)
signal level_completed(success)
signal visual_state_changed(new_state)
signal fact_displayed(fact_text)

func _ready():
	randomize()

func add_positive_action():
	environmental_score += 1
	emit_signal("score_changed", environmental_score)
	update_visual_state()
	show_random_fact()

func on_trash_collected():
	trash_collected_this_level += 1
	add_positive_action()
	check_level_completion()

func setup_level(level_name: String, trash_count: int):
	total_trash_in_level = trash_count
	trash_collected_this_level = 0
	print("Environmental: ", trash_count, " trash items in ", level_name)

func check_level_completion():
	var completion_ratio = float(trash_collected_this_level) / total_trash_in_level
	if completion_ratio >= completion_threshold:
		emit_signal("level_completed", true)
	else:
		emit_signal("level_completed", false)

func update_visual_state():
	var completion = float(trash_collected_this_level) / total_trash_in_level
	var new_state = 0
	if completion >= 0.8: new_state = 2
	elif completion >= 0.5: new_state = 1
	if new_state != world_visual_state:
		world_visual_state = new_state
		emit_signal("visual_state_changed", new_state)

func show_random_fact():
	var random_fact = environmental_facts[randi() % environmental_facts.size()]
	emit_signal("fact_displayed", random_fact)

func get_trash_count_text() -> String:
	return str(trash_collected_this_level) + "/" + str(total_trash_in_level)
