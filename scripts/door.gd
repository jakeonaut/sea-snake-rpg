extends Sprite3D

onready var level = get_tree().get_root().get_node("Game/Viewport/level")
export(NodePath) var partnerDoorId = null
var partnerDoor = null

func _ready():
    self.pixel_size = 0.0001
    if partnerDoorId != null:
        partnerDoor = get_node(partnerDoorId) if has_node(partnerDoorId) else null