extends "res://eventScripts/_event.gd"

onready var aniPlayer = get_node("../AnimationPlayer")

var brain_damage = 0
var collisionText = "[wave]hey, what's going on in there??[/wave]"
var characters = 'abcdefghijklmnopqrstuvwxyz'

func collideWith(was_charging = false):
    if not was_charging: return

    aniPlayer.stop()
    aniPlayer.clear_queue()
    aniPlayer.play("stunned")

    level.textBox.visible = true
    level.textBoxText.bbcode_text = collisionText
    level.hideTextBoxMoveCount = global.memory["move_counter"] + 4
    brain_damage += 1
    var indexToRandomize = randi() % len(collisionText)
    var whichLetterIndexToRandomizeTo = randi() % len(characters)
    collisionText[indexToRandomize] = characters[whichLetterIndexToRandomizeTo]
