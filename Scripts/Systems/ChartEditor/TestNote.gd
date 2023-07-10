extends Sprite2D

@onready var scr = get_parent()
@onready var scr2 = get_parent().get_node("AnimationPlayer")
var strumtime = 0.0
var advance = false
var note_id = 0
var layer = -1
var can_be_hit = true
var on_hold = false
var scroll_speed = 300
var safezone = 0.1
var hit_at = 0.0
var last_hit_index = null
var next_note = 0
var movetoleft = true
var closeness = 0
var originalPosition = position
var noteDone = false
var noteLost = false

var inputs = [
	"jump", 
	"stomp", 
	"dash",
	"parry",
	"customAction"
]

func _ready() -> void:
	add_to_group("notesGp")
	visible = false
	modulate.a = 1

func _process(delta: float) -> void:
	if scr.time <=strumtime:
		modulate.a = -((strumtime-1.25)-scr.time)
	elif scr.time >=strumtime:
		modulate.a -= delta
		if !noteLost:
			noteLost = true

	if advance == true:
		match(movetoleft):
			true:
				visible = true
				position.x = 480 + (strumtime-scr.time)*scroll_speed
			false:
				visible = true
				position.x = 480 - (strumtime-scr.time)*scroll_speed

		if (Input.is_action_just_pressed("notePress") and !on_hold) and !noteDone:
			if (scr.time <= strumtime+safezone and scr.time >= strumtime-safezone):
				scr2.seek(0.0,true)
				scr2.play("HitNote")
				$Clap.play()
				if !on_hold:
					noteDone = true
					hit_at = scr.time
					can_be_hit = false
					on_hold = true
				$AnimationPlayer.play("Hit")

	if (!on_hold):
		if modulate.a <= 0 and scr.time >=strumtime:
			queue_free()

	if on_hold:
		modulate.a = 1
		advance = false
		position.x = 480
		if !$AnimationPlayer.is_playing():
			queue_free()
