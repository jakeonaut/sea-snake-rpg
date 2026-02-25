extends Node

onready var level = get_tree().get_root().get_node("Game/Viewport/level")
onready var myParent = get_node("..")

# TODO(): Override me!!
func startTrying():
  pass

func keepTrying():
  pass

# TODO(): Override me!!
func stopTrying(_did_someone_else_start_talking):
  pass

# TODO(): Override me!!
func collideWith(was_charging = false):
  pass

# TODO(): Override me!!
func getHitWithCoconut(_coconutDir):
  pass