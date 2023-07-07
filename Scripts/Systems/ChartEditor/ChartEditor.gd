extends Node2D

@export var bpm = 60
@export var songToPlay = ""
var bps = 60/float(bpm)
var songPos = 0.0
var real_songPos = 0.0
var songPosition = 0.0
var notes = []
var lineSpeed = 5.0
var startTime: float = 0.0
var linePosition = 0
var zoom = 1
var speedFactor = 4

var snapValues = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 128, 192]
var currentSnapValue = 8
var mouseOnButton = false
var detectedSongs = []

@onready var selector = $ColorRect
@onready var line = $Line
@onready var cam = $Line/Camera2D
@onready var song = $AudioStreamPlayer2D
@onready var note =  preload("res://Scenes/Note.tscn")
@onready var notesfx = $noteSound
@onready var speedFactorLabel = $CanvasLayer/RichTextLabel
@onready var snapValueLabel = $CanvasLayer/Snap
@onready var zoomValueLabel = $CanvasLayer/Zoom
@onready var songPositionLabel = $CanvasLayer/SongPosition

func _ready():
	cam.zoom *= zoom
#	if OS.has_feature("standalone"):
#		var folder := OS.get_executable_path().get_base_dir() + "/song/song.ogg"
#	get_filelist("user://")
	song.stream = load(songToPlay)
	bps = 60/float(bpm)
	speedFactorLabel.text = "Speed Factor: " + str(speedFactor)
	snapValueLabel.text = "Snap: " + str(snapValues[currentSnapValue])
	zoomValueLabel.text = "Zoom: x" + str(zoom)
	songPositionLabel.text = "Song Position: " + str(0.0)
	
func _process(_delta):
	if zoom < 0.5:
		zoom = 0.5
	cam.zoom.x = zoom
	cam.zoom.y = zoom
	if real_songPos < 0:
		real_songPos = 0
		linePosition = 0
	if Input.is_action_just_pressed("ui_up"):
		speedFactor += 4
		speedFactorLabel.text = "Speed Factor: " + str(speedFactor)
	if Input.is_action_just_pressed("ui_down"):
		speedFactor -= 4
		speedFactorLabel.text = "Speed Factor: " + str(speedFactor)
		
	if Input.is_action_just_pressed("pauseSong"):
		if !song.playing:
			song.play( line.position.x / 64 * bps  )
		else:
			real_songPos = song.get_playback_position()
			song.stop()
	
	if (song.playing):
		songPosition = song.get_playback_position() + AudioServer.get_time_since_last_mix()
		
		linePosition = songPosition / bps * 64
		real_songPos = songPosition
	songPositionLabel.text = "Song Position: " + str(float(str( real_songPos ).pad_decimals(3)))
	update_line_position()

	selector.position.x = floor((get_global_mouse_position().x) / snapValues[currentSnapValue]) * snapValues[currentSnapValue]
	songPos = ((selector.position.x / 64) * bps)

func update_line_position():
	if (Input.is_action_pressed("ui_left")) and real_songPos > 0:
		real_songPos -= 0.001 * speedFactor
		linePosition = real_songPos / bps * 64
	elif (Input.is_action_pressed("ui_right")):
		real_songPos += 0.001 * speedFactor
		linePosition = real_songPos / bps * 64
	line.position.x = linePosition

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouseEvent = event as InputEventMouseButton
		if mouseEvent.button_index == MOUSE_BUTTON_LEFT and mouseEvent.pressed and !mouseOnButton:
			var noteIndex = notes.find(str(songPos).pad_decimals(3))

			if noteIndex >= 0 or selector.position.x < 0:
				pass
			else:
				spawnNote()
				notes.append(str(songPos).pad_decimals(3))
				notes.sort()
				print(notes)
		if mouseEvent.button_index == MOUSE_BUTTON_WHEEL_UP  and mouseEvent.pressed:
				if (currentSnapValue < snapValues.size()-1):
					currentSnapValue += 1
				snapValueLabel.text = "Snap: " + str(snapValues[currentSnapValue])
		elif mouseEvent.button_index == MOUSE_BUTTON_WHEEL_DOWN  and mouseEvent.pressed:
				if (currentSnapValue > 0):
					currentSnapValue -= 1
				snapValueLabel.text = "Snap: " + str(snapValues[currentSnapValue])



func spawnNote():
	var sceneInstance = note.instantiate()
	add_child(sceneInstance)
	sceneInstance.timeStamp = str(songPos).pad_decimals(3)
	sceneInstance.position = selector.position

func deleteNote(noteTimeStamp):
	var noteIndex = notes.find(str(noteTimeStamp).pad_decimals(3))
	notes.remove_at(noteIndex)
	notes.sort()

func _on_line_col_area_entered(_area):
	notesfx.play()

func _on_button_pressed():
	$CanvasLayer/FileDialog.visible = true


func _on_button_2_mouse_entered():
	mouseOnButton = true

func _on_button_2_mouse_exited():
	mouseOnButton = false

func _on_button_2_pressed():
	exportChart()

func exportChart():
	if OS.has_feature("standalone"):
		var folder := OS.get_executable_path().get_base_dir()
		var file = FileAccess.open(folder + "/chart.txt",FileAccess.WRITE)
		for i in range(notes.size()):
			file.store_line(String(notes[i]) + "\r")
	else:
		var time = Time.get_time_dict_from_system()

		var file = FileAccess.open("user://chart.txt",FileAccess.WRITE)
		for i in range(notes.size()):
			file.store_line(str(notes[i]) + "\r")
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"), true)

#func get_filelist(path):
#	var dir = DirAccess.open(path)
#	dir.make_dir("songs")
#	DirAccess.make_dir_absolute("user://levels/song")
#	dir = DirAccess.open(path+"/songs")
#	if dir:
#		dir.list_dir_begin()
#		var file_name = dir.get_next()
#		while file_name != "":
#			if dir.current_is_dir():
#				print("Found directory: " + file_name)
#			else:
#				if String(file_name).get_extension() == "ogg" or String(file_name).get_extension() == "mp3" or String(file_name).get_extension() == "wav":
#					print("Found file: " + file_name)
#					var songFile = FileAccess.open("user://songs/" + file_name, FileAccess.READ)
#					var audio_loader = AudioLoader.new()
#
#					detectedSongs.append(audio_loader.loadfile("user://songs/" + file_name))
#					songFile.close()
#			file_name = dir.get_next()
#			print(detectedSongs)
#	else:
#		print("An error occurred when trying to access the path.")
#
