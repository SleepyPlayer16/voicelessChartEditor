extends Node2D

signal zoomSignal

@export var bpm = 60
@export var songToPlay = ""
@export var chartToLoad = ""

var bps = 60/float(bpm)
var songPos = 0.0
var real_songPos = 0.0
var songPosition = 0.0
var notes = []
var lineSpeed = 5.0
var startTime: float = 0.0
var linePosition = 0
var zoom = 1
var speedFactor = 32
var gettingReady = true
var testing = false
var cur_note = 0

var snapValues = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 128, 192]
var currentSnapValue = 8
var mouseOnButton = false
var detectedSongs = []
var noteDict = {
	"notes":{
		
	}
}

@onready var selector = $ColorRect
@onready var line = $Line
@onready var lineAnimPlayer = $Line/AnimationPlayer
@onready var cam = $Line/Camera2D
@onready var song = $AudioStreamPlayer2D
@onready var note =  preload("res://Scenes/Note.tscn")
@onready var notesfx = $noteSound
@onready var speedFactorLabel = $CanvasLayer/RichTextLabel
@onready var snapValueLabel = $CanvasLayer/Snap
@onready var zoomValueLabel = $CanvasLayer/Zoom
@onready var songPositionLabel = $CanvasLayer/SongPosition
@onready var textInput = $CanvasLayer/TextEdit

func _ready():
#	if OS.has_feature("standalone"):
#		var folder := OS.get_executable_path().get_base_dir() + "/song/song.ogg"
#	get_filelist("user://")
	song.stream = load(songToPlay)
	bps = 60/float(bpm)
	speedFactorLabel.text = "Speed Factor: " + str(speedFactor)
	snapValueLabel.text = "Snap: " + str(snapValues[currentSnapValue])
	zoomValueLabel.text = "Zoom: x" + str(zoom)
	songPositionLabel.text = "Song Position: " + str(0.0)
	if chartToLoad != "":
		loadChart()

func _process(_delta):
	if songPosition < 0:
		songPosition = 0
		linePosition = 0
		$TestChartLayer.firstTime = true
	if songPosition <= 0:
		if !$TestChartLayer.firstTime:

			$TestChartLayer.firstTime = true
	else:
		$TestChartLayer.firstTime = false

	if Input.is_action_just_pressed("ui_up"):
		speedFactor += 4
		speedFactorLabel.text = "Speed Factor: " + str(speedFactor)
	if Input.is_action_just_pressed("ui_down"):
		speedFactor -= 4
		speedFactorLabel.text = "Speed Factor: " + str(speedFactor)

	if song.playing or testing:
		if textInput.editable:
			textInput.editable = false

	if (song.playing):
		songPosition = song.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
		linePosition = songPosition / bps * (64*zoom)
		real_songPos = songPosition
	else:
		if !textInput.editable and !testing:
			textInput.editable = true
	songPositionLabel.text = "Song Position: " + str(float(str( songPosition ).pad_decimals(3)))
	update_line_position()
	mouseHeldDown()
	selector.position.x = floor((get_global_mouse_position().x) / snapValues[currentSnapValue]) * snapValues[currentSnapValue]
	songPos = ((selector.position.x / (64*zoom)) * bps)
	if Input.is_action_just_pressed("pauseSong"):
		if !song.playing:
			gettingReady = false
			song.play( line.position.x / (64*zoom) * bps  )
		else:
			if !testing:
				real_songPos = song.get_playback_position()
				song.stop()

func update_line_position():
	if !testing and !song.playing:
		if (Input.is_action_pressed("ui_left")) and songPosition > 0:
			songPosition -= 0.001 * speedFactor
			linePosition = songPosition / bps * (64*zoom)
		elif (Input.is_action_pressed("ui_right")):
			songPosition += 0.001 * speedFactor
			linePosition = songPosition / bps * (64*zoom)
	line.position.x = linePosition

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouseEvent = event as InputEventMouseButton

		if mouseEvent.button_index == MOUSE_BUTTON_WHEEL_UP  and mouseEvent.pressed:
				if (currentSnapValue < snapValues.size()-1):
					currentSnapValue += 1
				snapValueLabel.text = "Snap: " + str(snapValues[currentSnapValue])
		elif mouseEvent.button_index == MOUSE_BUTTON_WHEEL_DOWN  and mouseEvent.pressed:
				if (currentSnapValue > 0):
					currentSnapValue -= 1
				snapValueLabel.text = "Snap: " + str(snapValues[currentSnapValue])
				
func mouseHeldDown():
	if Input.is_action_pressed("placeNote") and !mouseOnButton and !testing:
		var noteIndex = notes.find(songPos)
		
		if noteIndex >= 0 or selector.position.x < 0:
			pass
		else:
			notes.append(songPos)
			notes.sort()
			var actualIndex = notes.find(songPos)
			spawnNote(null, null, actualIndex)

func spawnNote(loadNotes, tStamp, id):
	var sceneInstance = note.instantiate()
	add_child(sceneInstance)
	sceneInstance.note_id = id
	if loadNotes == null:
		sceneInstance.timeStamp = songPos
		sceneInstance.position = (selector.position)
	else:
		sceneInstance.timeStamp = tStamp
		sceneInstance.position.x = loadNotes
		sceneInstance.position.y = selector.position.y

func deleteNote(noteTimeStamp):
	var noteIndex = notes.find(noteTimeStamp)
	notes.remove_at(noteIndex)
	notes.sort()

func exportChart():
	for n in notes.size():
		noteDict["notes"][n] = notes[n] 

	var chartName
	if textInput.text != "":
		chartName = textInput.text
	else:
		chartName = "chart"
	var file = FileAccess.open("user://" + chartName + ".json",FileAccess.WRITE)
	var json = JSON.stringify(noteDict)
	if file != null:
		file.store_string(json)

	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"), true)

func exportAsTXT():
	var chartName
	if textInput.text != "":
		chartName = textInput.text
	else:
		chartName = "chart"
	var file = FileAccess.open("user://" + chartName + ".txt",FileAccess.WRITE)
	for i in range(notes.size()):
		file.store_line(str(notes[i]) + "\r")
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://"), true)

func loadChart():
	var file = FileAccess.open(chartToLoad, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	print("Chart Detected")
	var datainArray = Array(data["notes"].values())
	
	for i in range(datainArray.size()):
		notes.append(datainArray[i])
		spawnNote(datainArray[i] / bps * (64*zoom), datainArray[i], i)

func _on_button_3_pressed():
	exportChart()

func _on_line_col_area_entered(_area):
	cur_note = _area.get_parent().note_id
	_area.get_parent().coolEffect()
	lineAnimPlayer.play("noteHit")
	if !testing:
		notesfx.play()

func _on_button_pressed():
	$CanvasLayer/FileDialog.visible = true


func _on_button_2_mouse_entered():
	mouseOnButton = true

func _on_button_2_mouse_exited():
	mouseOnButton = false

func _on_button_2_pressed():
	exportAsTXT()

func _on_button_3_mouse_entered():
	mouseOnButton = true


func _on_button_3_mouse_exited():
	mouseOnButton = false

func _on_text_edit_mouse_entered():
	mouseOnButton = true


func _on_text_edit_mouse_exited():
	mouseOnButton = false


func _on_button_4_pressed():
	if !testing:
		testing = true
		gettingReady = false
	else:
		testing = false
		mouseOnButton = false

func _on_button_5_pressed():
	if !testing:
		testing = true

func _on_button_7_pressed():
	if zoom > 1:
		zoom -= 1
		linePosition = songPosition / bps * (64*zoom)
	emit_signal("zoomSignal")

func _on_button_6_pressed():
	if zoom < 8:
		zoom += 1
		linePosition = songPosition / bps * (64*zoom)
	emit_signal("zoomSignal")
