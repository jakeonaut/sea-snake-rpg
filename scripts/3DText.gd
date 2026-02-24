extends Spatial

onready var label3d = get_node("Label3D")
onready var colorAnimationPlayer = get_node("ColorAnimationPlayer")
onready var moveAnimationPlayer = get_node("MoveAnimationPlayer")

func setText(newText, is_lame = false):
    label3d.text = newText
    if is_lame:
        colorAnimationPlayer.stop()
        colorAnimationPlayer.clear_queue()
        colorAnimationPlayer.play("notAsCool")
        moveAnimationPlayer.stop()
        moveAnimationPlayer.clear_queue()
        moveAnimationPlayer.play("longerRaiseAndFade")