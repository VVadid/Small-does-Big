extends Control

export(String, "TimelineDropdown") var timeline: String = ""
export(String, "TimelineDropdown") var no_star_timeline: String = "NoStar"

func start_dialogue():
	if timeline.empty():
		printerr("No timeline selected!")
		return null
	
	var dialog = Dialogic.start(timeline)
	get_parent().add_child(dialog)
	return dialog

func start_specific_dialogue(specific_timeline: String):
	var dialog = Dialogic.start(specific_timeline)
	get_parent().add_child(dialog)
	return dialog
