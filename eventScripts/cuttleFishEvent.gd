extends "res://eventScripts/_event.gd"

onready var paletteAniPlayer = get_node("../PaletteAnimationPlayer")
onready var coconutMaskSprite = get_node("../coconutMaskSprite")
onready var myRock = get_node("../myRock")
var can_destroy_rock = false
var destroy_rock_timer = 0
var destroy_rock_time_limit = 15

var touchText = "[wave]shhh kid, i'm hidin' here.[/wave]"
var collisionText = "[wave]hey, bub, watch it! i ain't no rock!\ntell ya what, bring me somethin better to hide in\nand i'll teach ya camouflage[/wave]"

var camouflage_secret_text = "well, here's the secret to camouflage:\n"
var camouflage_secret_fruit_text = "eat this multiberry"
var camouflage_secret_instruction_text = "press [Z] when over colorful kelp"

func _ready():
    set_process(true)
    myRock.can_i_be_destroyed = false

func _process(delta):
    coconutMaskSprite.frame = myParent.mySprite.frame + 2
    if can_destroy_rock and not myRock.can_i_be_destroyed:
        destroy_rock_timer += (delta*22)
        if destroy_rock_timer >= destroy_rock_time_limit:
            myRock.can_i_be_destroyed = true
            # TODO(jaketrower): MEMORY FIX
            myRock.rockSmash()

func collideWith(was_charging = false):
    if was_charging:
        paletteAniPlayer.stop()
        paletteAniPlayer.clear_queue()
        paletteAniPlayer.play("paletteCycle")
        if global.memory["is_cuttlefish_wearing_coconut"]:
            paletteAniPlayer.queue("postCoconutMaskColor")
    var camouflageSecretTextToUse = camouflage_secret_text + (
        camouflage_secret_instruction_text if global.memory["can_camouflage"] else camouflage_secret_fruit_text
    )
    return [collisionText if was_charging else camouflageSecretTextToUse if global.memory["is_cuttlefish_wearing_coconut"] else touchText]

func getHitWithCoconut(_coconutDir):
    if not global.memory["is_cuttlefish_wearing_coconut"]:
        global.memory["is_cuttlefish_wearing_coconut"] = true
        coconutMaskSprite.visible = true
        paletteAniPlayer.stop()
        paletteAniPlayer.clear_queue()
        paletteAniPlayer.play("paletteCycle")
        paletteAniPlayer.queue("postCoconutMaskColor")
        # TODO(jaketrower): MEMORY FIX
        collisionText = "now nobody will mistake me for a rock!\nright? it looks totally different right?"
        can_destroy_rock = true
        return [true, "oh, this will do. thanks kid.\n" + camouflage_secret_text + camouflage_secret_fruit_text]
    elif global.memory["is_cuttlefish_wearing_coconut"]:
        return [false, "thanks again kid.\nthat's enough though.."]
