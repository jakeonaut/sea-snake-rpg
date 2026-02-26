extends "res://eventScripts/_event.gd"

onready var myRock = get_node("../myRock")
var can_destroy_rock = false
var destroy_rock_timer = 0
var destroy_rock_time_limit = 15

func _ready():
    set_process(true)
    myRock.can_i_be_destroyed = false

func _process(delta):
    if can_destroy_rock and not myRock.can_i_be_destroyed:
        destroy_rock_timer += (delta*22)
        if destroy_rock_timer >= destroy_rock_time_limit:
            myRock.can_i_be_destroyed = true
            # TODO(jaketrower): MEMORY FIX
            myRock.rockSmash()

func startTrying():
    if doesPlayerHaveMyStripes():
        myParent.bbcode_text = "[wave]werp weep werp :)[/wave]"
        level.textBoxText.bbcode_text = myParent.bbcode_text
        can_destroy_rock = true

func doesPlayerHaveMyStripes():
    var which_color_idx = 0
    var stripe_color_arr = [global.yellow_palette, global.white_palette]
    if len(level.player.myBodyParts) < 3:
        return false
    for i in range(len(level.player.myBodyParts)):
        var bodyPart = level.player.myBodyParts[i]
        var which_color = stripe_color_arr[which_color_idx]
        if bodyPart.material_override.get_shader_param("target_palette") != which_color:
            return false
        which_color_idx += 1
        if which_color_idx >= len(stripe_color_arr): which_color_idx = 0
    return true