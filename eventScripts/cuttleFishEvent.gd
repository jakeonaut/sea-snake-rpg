extends "res://eventScripts/_event.gd"

onready var paletteAniPlayer = get_node("../PaletteAnimationPlayer")

var touchText = "[wave]shhh kid, i'm hidin' here.[/wave]"
var collisionText = "[wave]hey, bub, watch it! i ain't no rock!\ntell ya what, bring me a better hiding place\nand i'll teach ya camouflage[/wave]"

func collideWith(was_charging = false):
    level.textBox.visible = true
    level.textBoxText.bbcode_text = collisionText if was_charging else touchText
    level.hideTextBoxMoveCount = global.memory["move_counter"] + 4
    myParent.playTalkSound()
    if was_charging:
        paletteAniPlayer.stop()
        paletteAniPlayer.clear_queue()
        paletteAniPlayer.play("paletteCycle")

func getHitWithCoconut(_coconutDir):
    pass