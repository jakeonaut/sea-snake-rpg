extends "res://scripts/Sprite.gd"

var is_cracked = false
onready var aniPlayer = get_node("AnimationPlayer")
onready var miniQuakeSound = get_node("MiniquakeSound")

func rockSmash():
    if not visible or is_cracked: return
    is_cracked = true

    aniPlayer.play("breakUp")
    yield(get_tree().create_timer(0.1), "timeout")
    miniQuakeSound.pitch_scale = rand_range(0.8, 1.2)
    miniQuakeSound.play()