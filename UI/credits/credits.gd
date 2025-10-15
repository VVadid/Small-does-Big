extends ColorRect

var sound_credits := [
	'"Medieval spear swing 2"\n by Still North Media',
	'"Spear throw and stick into ground with slight\nvibration of the wooden spear pole on impact. Version 1"\n by ZapSplat',
	'"Sharp wooden post, stake, dig into soil, ground 4"\n by ZapSplat',
	'"Spear thrown and stick into ground with slight\nvibration of wooden spear pole on impact. Version 5"\n by ZapSplat',
	'"Whoosh Heavy Spear Hammer Large" by EminYILDIRIM',
	'"Fast swing, whoosh into a metal hit, thud or\nclunk, could be\nsword hitting shield or armor. Version 1"\n by ZapSplat'
]

onready var animation: AnimationPlayer = $AnimationPlayer
onready var sfx1 := $sound_credits/VBoxContainer_2/name
onready var sfx2 := $sound_credits/VBoxContainer_2/name_2
onready var times := $fin/times

func _ready() -> void:
	times.text = (
		"final time: " + str(global.total_time) + "\n" +
		"level time: " + str(global.speedrun_time) + "\n"
	)

func start_sound_credits(time: float):
	for i in sound_credits.size()-1:
		if (i / 2.0) != floor(i / 2.0): # is odd
			sfx1.text = sound_credits[i]
		else: # is even
			sfx2.text = sound_credits[i]
		
		yield(get_tree().create_timer(time / sound_credits.size()), "timeout")

func _input(event: InputEvent) -> void:
	if animation.is_playing():
		return
	
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton:
		if event.pressed:
			get_tree().change_scene("res://UI/title_screen/title_screen.tscn")
