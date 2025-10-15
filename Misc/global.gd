extends Node

var debug: int = 0

# Dialogue system
var played_dialogues := {}  # Dictionary to track played dialogues
var is_player_in_dialogue := false
var persistent_audio_player: AudioStreamPlayer = null
var current_end_music: AudioStream = null  # This declares the missing variable

const OLD_LEVEL_CODES := [
	"A-1", "A-2", "A-3", "A-4", "A-5", "A-6", "A-7", "A-8", "A-9", "A-10", "A-11", 
	"A-12", "A-13", "A-14", "A-15", "A-secret"
]

const DEV_TIMES := {
	"Redwood": 9.3,
	"Midpoint": 11.8,
	"Quickstep": 13.4,
	"Barricade": 16.2,
	"Brick": 9.0,
	"Gauntlet": 22.6,
	"Sprint": 23.8,
	"Timber": 8.8,
	"Army": 7.1,
	"Entrance": 9.1,
	"Ambushed": 8.6,
	"Caged": 22.5,
	"Monarch": 9.4,
	"River": 7.6,
	"Conflict": 23.8,
	"Settlement": 80.9,
	"Horde": 25.3,
	"Duo": 19.1,
	"Spiral": 12.0,
	"Shadow": 21.7,
	"Fortified": 24.3,
	"Vault": 14.2,
	"Pathway": 7.0,
	"Slice": 12.5,
	"Disorderly": 16.5,
	"Across": 13.3,
	"Halls": 30.5,
	"Mythical": 22.4,
	"Ranger": 13.2,
	"Breach": 25.0,
	"Duel": 11.4,
	"Poison": 22.3,
	"Isolated": 11.2,
	"Hex": 11.1,
	"Ghastly": 10.1,
	"Scrapyard": 10.5,
	"Dusk": 11.4,
	"Breakin": 13.4,
	"Infected": 17.2,
	"Longshot": 14.1,
	"Fair": 8.8,
	"Sincerity": 15.8,
	"Maze": 18.5,
	"Haunting": 9.7,
	"Tailend": 5.6,
	"Patrol": 5.8,
	"Scavenge": 14.6,
	"Doctor": 9.3,
	"Scorch": 5.4,
	"Outpost": 17.8,
	"Outgunned": 4.9,
	"Pinned": 20.4,
	"Mined": 12.5,
	"Boom": 24.7,
	"Might": 4.6,
	"Knight": 31.8,
	"Abomination": 20.3,
	"Exploration": 8.9,
	"Automation": 29.8,
	"Even": 17.7,
	"Ricochet": 21.2,
	"Light": 14.1,
	"Cliffside": 32.0,
	"Lost": 24.4,
	"Telefrag": 9.5,
	"Production": 52.2,
	"Ray": 23.3,
	"Airfoce": 13.4,
	"Fugitive": 13.4,
	"Core": 108.8,
}

# all the global variables
var quality_of_this_game = "10 Verdant Orbs# = very bad game"
var the_seed = "Subscribe to Wadid"

# PROBLEM_NOTE: this should probably be in the player
var selection = 0 # for the item bar (0 1 2)
var joy_connected := false
var look_pos := Vector2.RIGHT
var FOV = Vector2(1, 1)
var previous_scene = null # PROBLEM_NOTE i don't think this is used
var player_hub_pos = {"A":Vector2(0, 0)}
var last_ambiance = 0 # PROBLEM_NOTE: this isn't used i don't think
var loader
var thread := Thread.new()

# data vars
var stars := 0
var last_hub = null
var cleared_levels := []
var perfected_levels := []
var level_deaths := {}
var level_times := {}
var total_time := 0.0
var speedrun_time := 0.0
var icon = 0

const ver_phase = ""
const ver_num = 1.3
const ver_hotfix = 0

# for saving things
const SAVE_DIR := "user://saves/"
var save_name: String = "untitled_save"
var saves = []

var settings := {
	"fullscreen": false,
	"perfection_mode": false,
	"pixel_perfect": false,
	"smooth_camera": true,
	"hide_bar": false,
	"volume": 0.50,
	"sound_volume": 0.50,
	"menu_volume": 0.50,
	"ambiance_volume": 0.50,
	"footsteps_volume": 0.50,
	"vsync": true,
	"particles": 3, # 0 = none, 1 = low, 2 = medium, 3 = all
	"gpu_snap": false,
	"spawn_pause": false,
	"lighting": true,
	"shadows": true,
	"shadow_buffer": 512,
	"ambient_lighting": true,
	"damage_numbers": true,
	"show_hud": true,
	"brain_sapping": true,
	"camera_zoom": 1.0,
	"show_fps": false,
	"use_color": false,
	"player_color": Color.white,
}

# should move this and get_relation to Entity.gd probably
const faction_relationships = {
	"player": 
		{
			"solo": "hostile",
			"player": "friendly",
			"monster": "hostile",
			"blue_kingdom": "hostile",
			"army": "hostile",
			"offworld": "hostile",
		},
	"monster":
		{
			"solo": "hostile",
			"player": "hostile",
			"monster": "friendly",
			"blue_kingdom": "hostile",
			"army": "hostile",
			"offworld": "hostile",
		},
	"blue_kingdom":
		{
			"solo": "hostile",
			"player": "hostile",
			"monster": "hostile",
			"blue_kingdom": "friendly",
			"army": "hostile",
			"offworld": "hostile",
		},
	"solo":
		{
			"solo": "hostile",
			"player": "hostile",
			"monster": "hostile",
			"blue_kingdom": "hostile",
			"army": "hostile",
			"offworld": "hostile",
		},
	"army":
		{
			"solo": "hostile",
			"player": "hostile",
			"monster": "hostile",
			"blue_kingdom": "hostile",
			"army": "friendly",
			"offworld": "hostile",
		},
	"offworld":
		{
			"solo": "hostile",
			"player": "hostile",
			"monster": "hostile",
			"blue_kingdom": "hostile",
			"army": "hostile",
			"offworld": "friendly",
		},
	"my_entity": # special: friendly to the same entities (truName), but hostile to everyone else
		{
			"solo": "hostile",
			"player": "hostile",
			"monster": "hostile",
			"blue_kingdom": "hostile",
			"army": "hostile",
			"offworld": "hostile",
		},
}

const VER_INCOMPATIABILITY := []

# cursor sprites preloaded:
const CURSOR_NORMAL = preload("res://UI/cursors/cursor_normal.png")
const CURSOR_IBEAM := preload("res://UI/cursors/cursor_ibeam.png")

signal update_item_info(current_item, extra_info, item_bar_max, item_bar_value, bar_timer_duration)
signal update_item_bar(inventory)
signal update_health()
signal update_camera()
signal paused()
signal unpaused()

func _ready():
	seed(the_seed.hash())
	var v: String = ""
	if ver_phase != "":
		v = ver_phase + " "
	v += "v" + str(ver_num)
	if ver_num == round(ver_num):
		v = v + ".0"
	if ver_hotfix > 0:
		if ver_hotfix == 1:
			v = v + " hotfix"
		else:
			v = v + " hotfix #" + str(ver_hotfix)
	if OS.is_debug_build() == true:
		v = v + " (debug)"
	prints("teralite", v)
	prints("seed:", the_seed, "(%s)" % the_seed.hash())
	
	Input.set_custom_mouse_cursor(CURSOR_NORMAL, Input.CURSOR_ARROW, Vector2(0, 0))
	Input.set_custom_mouse_cursor(CURSOR_IBEAM, Input.CURSOR_IBEAM, Vector2(22.5, 22.5))
	Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	AudioServer.set_bus_layout(load("res://UI/audio_bus_layout.tres"))
	
	var hr = OS.get_time()["hour"]
	if hr > 12: hr -= 12
	if hr == 4 and OS.get_time()["minute"] == 20:
		OS.alert("something terrible is going to happen. do you want to proceed?", "IMPORTANT")
		print("you just got rickrolled!!!!1!")
		OS.shell_open("https://www.youtube.com/watch?v=dQw4w9WgXcQ")
	
	push_warning("quality_of_this_game == -999")
	
	# debug stuffz:
	Engine.time_scale = 1
	#if get_tree().current_scene.get_name() != "test_level":
	#	get_tree().change_scene("res://Levels/test_level.tscn")

func _on_joy_connection_changed(_device_id, connected):
	joy_connected = connected
	if connected:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# PROBLEM_NOTE: should probably move this to the Entity class
func get_relation(me:Entity, other:Entity) -> String:
	if me.marked_enemies.has(other):
		return "hostile"
	if me.marked_allies.has(other):
		return "friendly"
	
	if me.faction == "my_entity" or other.faction == "my_entity":
		if me.truName == other.truName:
			return "friendly"
		else:
			return "hostile"
	
	var faction_one = me.faction
	var faction_two = other.faction
	
	if faction_one == "" or faction_two == "": 
		return ""
	else:
		return faction_relationships[faction_one][faction_two]

func get_empty_save_data():
	return {
		"save_name": "untitled_save",
		"stars": 0,
		"last_hub": null,
		"hub_pos": {"A": Vector2.ZERO},
		"cleared_levels": [],
		"perfected_levels": [],
		"level_deaths": {},
		"level_times": {},
		"ver_phase": ver_phase,
		"ver_num": ver_num,
		"ver_hotfix": ver_hotfix,
		"total_time": 0.0,
		"speedrun_time": 0.0,
		"icon": 0,
		"played_dialogues": {},  # <--- Reset dialogues for new saves
	}

func get_save_data_dict():
	return {
		"save_name": save_name,
		"stars": stars,
		"last_hub": last_hub,
		"hub_pos": player_hub_pos,
		"cleared_levels": cleared_levels,
		"perfected_levels": perfected_levels,
		"level_deaths": level_deaths,
		"level_times": level_times,
		"ver_phase": ver_phase,
		"ver_num": ver_num,
		"ver_hotfix": ver_hotfix,
		"total_time": total_time,
		"speedrun_time": speedrun_time,
		"icon": icon,
		"played_dialogues": played_dialogues,  # <--- Save dialogue states
	}

func update_saves():
	saves = []
	var dir = Directory.new()
	if not dir.dir_exists(SAVE_DIR): dir.make_dir_recursive(SAVE_DIR)
	
	dir.open(SAVE_DIR)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			saves.append(file)
	dir.list_dir_end()

func write_save(entered_save_name, data):
	var new_save_name = entered_save_name
	if new_save_name == "":
		new_save_name = "untitled_save"
	
	save_name = new_save_name
	
	# makes saves directory if it does not exist
	var dir = Directory.new()
	if not dir.dir_exists(SAVE_DIR): dir.make_dir_recursive(SAVE_DIR)
	
	var save_file = File.new()
	var error = save_file.open(SAVE_DIR + save_name, File.WRITE)
	if error == OK:
		# load works
		save_file.store_var(data)
		save_file.close()
	else:
		# load failed
		push_error("could not open save '%s' on write" % save_name)
		OS.alert("could not open save '%s' on write" % save_name, "reportpls.jpg")

func load_save(entered_save_name):
	var save_file = File.new()
	save_name = entered_save_name
	
	# Handle invalid filename characters
	if not save_name.is_valid_filename():
		if save_file.file_exists(SAVE_DIR + save_name):
			var error = save_file.open(SAVE_DIR + save_name, File.READ)
			if error == OK:
				var save_data = save_file.get_var()
				save_file.close()
				
				var new_name := ""
				for letter in save_name:
					if letter.is_valid_filename():
						new_name = new_name + letter
					else:
						new_name = new_name + "_"
				
				delete_save(save_name)
				save_name = new_name
				write_save(save_name, save_data)
			else:
				push_error("Could not open save for renaming")
				return
	
	if save_file.file_exists(SAVE_DIR + save_name):
		var error = save_file.open(SAVE_DIR + save_name, File.READ)
		if error == OK:
			var new_data = save_file.get_var()
			
			# Load standard game data
			if new_data.has("stars"): stars = new_data["stars"]
			if new_data.has("last_hub"): last_hub = new_data["last_hub"]
			if new_data.has("hub_pos"): player_hub_pos = new_data["hub_pos"]
			if new_data.has("cleared_levels"): cleared_levels = new_data["cleared_levels"]
			if new_data.has("perfected_levels"): perfected_levels = new_data["perfected_levels"]
			if new_data.has("level_deaths"): level_deaths = new_data["level_deaths"]
			if new_data.has("level_times"): level_times = new_data["level_times"]
			if new_data.has("total_time"): total_time = new_data["total_time"]
			if new_data.has("speedrun_time"): speedrun_time = new_data["speedrun_time"]
			if new_data.has("icon"): icon = new_data["icon"]
			
			# Load dialogue states - NEW
			if new_data.has("played_dialogues"):
				played_dialogues = new_data["played_dialogues"]
			else:
				played_dialogues = {}  # Fallback for old saves
			
			save_file.close()
			
			# Handle old level codes
			for i in cleared_levels:
				if i in OLD_LEVEL_CODES:
					cleared_levels.append(level_code_to_name(i))
			
			for i in perfected_levels:
				if i in OLD_LEVEL_CODES:
					perfected_levels.append(level_code_to_name(i))
			
			for key in level_deaths.keys():
				if key in OLD_LEVEL_CODES:
					level_deaths[level_code_to_name(key)] = level_deaths[key]
			
			for key in level_times.keys():
				if key in OLD_LEVEL_CODES:
					level_times[level_code_to_name(key)] = level_times[key]
			
			# Handle scene transition
			if last_hub == null:
				get_tree().change_scene("res://Levels/A/Level1.tscn")
			elif last_hub.length() != 1:
				get_tree().change_scene("res://Levels/A/A-Hub.tscn")
			else:
				get_tree().change_scene("res://Levels/%s/%s-Hub.tscn" % [last_hub, last_hub])
		else:
			push_error("Could not open save file")
	else:
		push_error("Save file not found")

func level_code_to_name(lvl:String) -> String:
	match lvl:
		"A-1": return "Redwood"
		"A-2": return "Midpoint"
		"A-3": return "Spiral"
		"A-4": return "Brick"
		"A-5": return "Barricade"
		"A-6": return "Sprint"
		"A-7": return "Quickstep"
		"A-8": return "Entrance"
		"A-9": return "Timber"
		"A-10": return "Gauntlet"
		"A-11": return "Army"
		"A-12": return "Ambushed"
		"A-13": return "Caged"
		"A-14": return "Monarch"
		"A-15": return "Duo"
		"A-secret": return "Shadow"
		_: 
			push_error("invalid level code '%s'" % lvl)
			return lvl

func delete_save(entered_save_name):
	var save_file = File.new()
	
	save_name = entered_save_name
	
	if save_file.file_exists(SAVE_DIR + save_name):
		# file found
		var dir = Directory.new()
		dir.remove(SAVE_DIR + save_name)
	else:
		# file not found
		push_warning("could not find save on delete")
		OS.alert("could not find save on delete", "reportpls.jpg")

func update_settings(save_settings_config:=true):
	OS.window_fullscreen = settings["fullscreen"]
	OS.vsync_enabled = settings["vsync"]
	ProjectSettings.set_setting("rendering/2d/snapping/use_gpu_pixel_snap", settings["gpu_snap"])
	AudioServer.set_bus_volume_db(0, linear2db(settings["volume"]))
	AudioServer.set_bus_volume_db(1, linear2db(settings["sound_volume"]))
	AudioServer.set_bus_volume_db(2, linear2db(settings["menu_volume"]))
	AudioServer.set_bus_volume_db(3, linear2db(settings["ambiance_volume"]))
	AudioServer.set_bus_volume_db(4, linear2db(settings["footsteps_volume"]))
	
	update_audio_volumes()
	
	if is_instance_valid(refs.camera):
		refs.camera.zoom_to(Vector2(1, 1))
	
	if settings["pixel_perfect"] == true:
			get_tree().set_screen_stretch(
					SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, Vector2(384, 216)
				)
	else:
		get_tree().set_screen_stretch(
					SceneTree.STRETCH_MODE_2D, SceneTree.STRETCH_ASPECT_KEEP, Vector2(384, 216)
				)
	
	if "TYPES" in get_tree().current_scene: # is map
		var camera = refs.camera
		if not camera is Camera2D:
			push_warning("could not find camera")
		else:
			camera.smoothing_enabled = settings["smooth_camera"]
			camera.limit_smoothed = settings["smooth_camera"]
		
		for light in get_tree().get_nodes_in_group("lights"):
			light.enabled = settings["lighting"]
			light.shadow_enabled = settings["shadows"]
			light.shadow_buffer_size = settings["shadow_buffer"]
		
		var ambient_lighting: CanvasModulate = refs.ambient_lighting
		var level: Node2D = refs.level
		if level != null and settings["ambient_lighting"] == true:
			match level.AMBIENT_LIGHTING:
				level.TYPES.NONE, level.TYPES.AUTUMN:
					ambient_lighting.color = Color(1, 1, 1)
				level.TYPES.UNDERGROUND:
					ambient_lighting.color = Color(0.6, 0.6, 0.6)
				level.TYPES.WASTELAND:
					ambient_lighting.color = Color(1, 1, 0.7)
		else:
			ambient_lighting.color = Color(1, 1, 1)
		
		var item_bar: Node = refs.item_bar
		if is_instance_valid(item_bar): 
			var player = refs.player
			if not is_instance_valid(player): return
			
			var inventory = player.inventory
			if (
				settings["hide_bar"] == true and 
				inventory[0] == null and
				inventory[1] == null and
				inventory[2] == null
			):
				item_bar.visible = false
			else:
				item_bar.visible = true
		
		if get_tree().current_scene.has_particles == true:
			var particles: Particles2D = get_tree().current_scene.particles
			
			var enabled := false
			if settings["particles"] == 3:
				enabled = true
			
			get_tree().current_scene.update_particles = enabled
			get_tree().current_scene.set_physics_process(enabled)
			particles.visible = enabled
			particles.emitting = enabled
		
		var hud_elements := [refs.health_ui, refs.item_bar, refs.item_info, refs.stopwatch]
		for element in hud_elements:
			if is_instance_valid(element):
				element.visible = settings["show_hud"]
	
	if is_instance_valid(refs.fps):
		refs.fps.visible = settings["show_fps"]
	
	if is_instance_valid(refs.player):
		if global.settings["use_color"]:
			for entity in get_tree().get_nodes_in_group("entity"):
				entity = entity as Entity
				if entity.truName != "player":
					continue
				entity.sprite.front_texture = refs.player.SPRITE_CUSTOM
				entity.sprite.back_texture = refs.player.SPRITE_CUSTOM_BACK
				entity.sprite.modulate = global.settings["player_color"]
		else:
			for entity in get_tree().get_nodes_in_group("entity"):
				entity = entity as Entity
				if entity.truName != "player":
					continue
				entity.sprite.front_texture = refs.player.SPRITE_NORM
				entity.sprite.back_texture = refs.player.SPRITE_NORM_BACK
				entity.sprite.modulate = Color.white
	
	if save_settings_config == false:
		return
	
	# saving to settings_config file
	
	var settings_config = File.new()
	
	var error = settings_config.open("user://settings_config", File.WRITE)
	if error == OK:
		# load works
		settings_config.store_var(settings)
		settings_config.close()
	else:
		# load failed
		push_error("could not load settings_config (on update), deleting")
		OS.alert("could not load settings config (on update)", "reportpls.jpg")
		
		if settings_config.file_exists("user://settings_config"):
			var dir := Directory.new()
			dir.remove("user://settings_config")
		else:
			push_error("could not find settings_config (on deletion)")
			OS.alert("could not find settings_config (on deletion)", "reportpls.jpg")

func quit():
	print(
		"\n" +
		"hope you had fun or whatever\n" +
		"there's some memory leaks that happen when the game quits, and i have no idea why :(\n" +
		"i guess it doesn't really matter\n"
	)
#	refs.queue_free()
#	self.queue_free()
	get_tree().quit()

func sec_to_time(time: float, round_seconds := false) -> String:
	var hours := int(floor(time / 3600))
	var minutes := int(floor((time - hours * 3600) / 60))
	var seconds := int(floor(time - (minutes * 60) - (hours * 3600)))
	var tenth := stepify(time - ((hours * 3600) + (minutes*60) + seconds), 0.1) * 10
	if tenth == 10: tenth = 0
	
	var sec_string: String = str(seconds)
	if seconds < 10:
		sec_string = "0" + sec_string
	
	var text: String
	if hours >= 1:
		text = str(hours) + ":"
	text = text + str(minutes) + ":" + sec_string
	if round_seconds == false:
		text = text + "." + str(tenth)
	return text

func get_look_pos() -> Vector2:
	if joy_connected:
		return look_pos
	else:
		return get_tree().current_scene.get_global_mouse_position()

func goto_scene(scene_path: String):
	refs.transition.exit()
	thread.start(self, "_prep_scene", ResourceLoader.load_interactive(scene_path))

func _prep_scene(loader):
	while true:
		var poll = loader.poll()
		if poll == ERR_FILE_EOF:
			call_deferred("_prep_finished")
			return loader.get_resource()

func _prep_finished():
	var scene: PackedScene = thread.wait_to_finish()
	if refs.transition.animation.is_playing():
		yield(refs.transition, "finished")
	get_tree().change_scene_to(scene)


# Add these functions to your global.gd
func play_persistent_sound(sound: AudioStream):
	# Stop any existing persistent sound
	stop_persistent_sound()
	
	# Store and play the new sound
	current_end_music = sound
	persistent_audio_player = AudioStreamPlayer.new()
	persistent_audio_player.stream = sound
	persistent_audio_player.volume_db = linear2db(settings["sound_volume"])
	
	# Add to scene tree and play
	get_tree().root.add_child(persistent_audio_player)
	persistent_audio_player.play()

func stop_persistent_sound():
	if persistent_audio_player and is_instance_valid(persistent_audio_player):
		persistent_audio_player.stop()
		persistent_audio_player.queue_free()
	persistent_audio_player = null
	current_end_music = null

func update_audio_volumes():
	# Update volume for persistent audio if it exists
	if persistent_audio_player and is_instance_valid(persistent_audio_player):
		persistent_audio_player.volume_db = linear2db(settings["sound_volume"])
