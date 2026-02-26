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

    # need to do this here because whaleBrain is not an NPC.
    # npcs will normally handle their own level.textBox setting
    level.textBox.visible = true
    level.textBoxText.bbcode_text = collisionText
    level.hideTextBoxMoveCount = global.memory["move_counter"] + 4
    brain_damage += 1
    var indexToRandomize = randi() % len(collisionText)
    var whichLetterIndexToRandomizeTo = randi() % len(characters)
    collisionText[indexToRandomize] = characters[whichLetterIndexToRandomizeTo]
    # technically a no-op here to return collisionText cuz this is being
    # called directly from playerMover rather than from within npc.collideWith
    return collisionText
