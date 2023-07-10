extends Node2D

@onready var area = $noteAr/CollisionShape2D

var mouseIn = false
var isMouseInside: bool = false
var timeStamp: float = 0.0
var note_id = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)
	get_parent().zoomSignal.connect(changeZoom)

func _process(_delta):
	if Input.is_action_pressed("DeleteNote"):
		if mouseIn and !get_parent().testing:
			get_parent().deleteNote(timeStamp)
			queue_free()
			
func changeZoom():
	position.x = timeStamp / get_parent().bps * (64*get_parent().zoom)

func coolEffect():
	$AnimationPlayer2.play("coolEffect")

func _on_note_ar_mouse_entered():
	mouseIn = true
#	print("uuuooooghhhh")


func _on_note_ar_mouse_exited():
	mouseIn = false
