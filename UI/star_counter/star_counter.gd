extends Control

onready var label = $Label

func _ready() -> void:
	label.text = "Verdant Core: " + str(global.stars)
