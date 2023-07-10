extends CanvasLayer
var song_chart

var note = {}
var noteloop = []
var cur_note = -1

var id
var begin_song = false
var time = 0.0
var number_of_notes = null

var time_of_loop = 0.0
var playing = false
var layerr = -1
var show_in_advance = 4
var begin_at = null

var curr_note_by_time = 0
var curr_noteSingleFrame = 0

var loop = false
var unloop = false
var songLoaded = false
var destructTimer = 5
var prepareForMassDestruction = false
var lastBeat = 0.0
var firstTime = true
var spawnNotes = true

var loadParentChart = false

@onready var noteScene = load("res://Scenes/TestNote.tscn")
@onready var audioPlayer = get_parent().get_node("AudioStreamPlayer2D")

var countdown = true

var activateSecondaryTime = false

func _ready():
	if get_parent().chartToLoad != "":
		song_chart = get_parent().chartToLoad
		_load()
		set_physics_process_internal(true)
		begin_at = note["notes"][str(show_in_advance)]
		time-= get_parent().bps*2
		for i in range(0,note["notes"].size()):
			noteloop.append(note["notes"][str(i)])
		number_of_notes = noteloop.size()-1
	else:
		loadParentChart = true
		

func _process(_delta: float):
	if get_parent().testing:
		if loadParentChart:
			if get_parent().notes.size() > 2:
				noteloop = get_parent().notes
				begin_at = noteloop[2]
				playAtBeginning()
				number_of_notes = noteloop.size()
				loadParentChart = false

		if noteloop.size() > 2:
			print(cur_note)
			if !visible:
				noteloop = get_parent().notes
				visible = true
				playAtBeginning()
				

			if audioPlayer.playing:
				time = get_parent().song.get_playback_position() + AudioServer.get_time_since_last_mix()
				time -= AudioServer.get_output_latency()

			if !begin_song:
				time += _delta
			if begin_song:
				if !audioPlayer.playing:
					time += _delta

			if time >= 0.0 and !begin_song:
				playing = true
				firstTime = false
				begin_song = true
				audioPlayer.play(get_parent().line.position.x / (64*get_parent().zoom) * get_parent().bps)

			if (( time + begin_at ) >= noteloop[cur_note]):
				spawn_note()
				if cur_note+1 == number_of_notes:
					spawn_note()
					spawnNotes = false
		else:
			get_parent().testing = false
			spawnNotes = true
			cur_note = 0
	else:
		cur_note = 0
		if begin_song:
			playing = false
			begin_song = false
			spawnNotes = true
		if visible:
			for i in get_tree().get_nodes_in_group("notesGp"):
				i.queue_free()
			loadParentChart = true
			visible = false
		

func spawn_note():
	if spawnNotes:
		id = noteScene.instantiate()
		id.strumtime = noteloop[cur_note]
		id.advance = true
		id.note_id = cur_note
		if cur_note < number_of_notes-1:
			cur_note += 1

		add_child(id)

func playAtBeginning():
	if cur_note != get_parent().cur_note:
		cur_note = get_parent().cur_note
	if !firstTime:
		time = get_parent().line.position.x / (64*get_parent().zoom) * get_parent().bps
	else:
		time = -get_parent().bps*2

func _load():
	var file = FileAccess.open(song_chart, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(file.get_as_text())
	var data = test_json_conv.get_data()
	note = data
