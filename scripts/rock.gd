extends "res://scripts/Sprite.gd"

var is_cracked = false
var can_i_be_destroyed = true 
onready var aniPlayer = get_node("AnimationPlayer")
onready var miniQuakeSound = get_node("MiniquakeSound")

# TODO(jaketrower): MEMORY FIX
func rockSmash():
    if not can_i_be_destroyed: return
    if not visible or is_cracked: return
    is_cracked = true

    aniPlayer.play("breakUp")
    yield(get_tree().create_timer(0.1), "timeout")
    miniQuakeSound.pitch_scale = rand_range(0.8, 1.2)
    miniQuakeSound.play()