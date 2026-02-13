extends "res://scripts/Sprite.gd"

var is_cracked = false
onready var aniPlayer = get_node("AnimationPlayer")
onready var miniQuakeSound = get_node("Miniquake")

func rockSmash():
    if not visible or is_cracked: return
    is_cracked = true

    aniPlayer.play("breakUp")
    miniQuakeSound.pitch_scale = rand_range(0.8, 1.2)
    miniQuakeSound.play()