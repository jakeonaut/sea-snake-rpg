extends Node

onready var level = get_tree().get_root().get_node("level")
onready var myParent = get_node("..")

# TODO(): Override me!!
func startTrying():
  pass

func keepTrying():
  pass

# TODO(): Override me!!
func stopTrying(_did_someone_else_start_talking):
  pass