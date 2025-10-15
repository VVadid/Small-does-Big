extends Node2D

const HURT_COLOR := Color(0.82, 0.15, 0.28)
const HURT_SHADOW := Color(0.0, 0.0, 0.0)
const BLOCK_COLOR := Color(0.15, 0.75, 0.9)
const BLOCK_SHADOW := Color(0.0, 0.0, 0.0)
const HEAL_COLOR := Color(0.2, 0.85, 0.5)
const HEAL_SHADOW := Color(0.0, 0.0, 0.0)

var type: String = "hurt"
var amount: int = 1

onready var label: Label = $Label
onready var animation: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	label.text = str(amount)
	
	match type:
		"block":
			label.add_color_override("font_color", BLOCK_COLOR)
			label.add_color_override("font_color_shadow", BLOCK_SHADOW)
			
		"heal":
			label.add_color_override("font_color", HEAL_COLOR)
			label.add_color_override("font_color_shadow", HEAL_SHADOW)
			
		_:
			label.add_color_override("font_color", HURT_COLOR)
			label.add_color_override("font_color_shadow", HURT_SHADOW)
			
