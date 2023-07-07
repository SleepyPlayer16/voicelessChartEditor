extends Node2D

@onready var area = $noteAr/CollisionShape2D

var mouseIn = false
var isMouseInside: bool = false
var timeStamp: float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready():
	set_process_input(true)

func _process(delta):
	if Input.is_action_pressed("DeleteNote"):
		if mouseIn:
			get_parent().deleteNote(timeStamp)
			queue_free()

func _on_note_ar_mouse_entered():
	mouseIn = true
#	print("uuuooooghhhh")


func _on_note_ar_mouse_exited():
	mouseIn = false
