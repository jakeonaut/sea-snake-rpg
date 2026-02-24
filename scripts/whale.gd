extends Spatial

onready var level = get_tree().get_root().get_node("Game/Viewport/level")

onready var whaleSkinSprite = get_node("whaleSprite")
# onready var whaleGutsSprite = get_node("whaleGutsSprite")
onready var hideSkin = get_node("hideSkin")
onready var hideSkin2 = get_node("hideSkin2")
onready var hideSkin3 = get_node("hideSkin3")
onready var hideSkin4 = get_node("hideSkin4")
onready var showSkin = get_node("showSkin")
onready var showSkin2 = get_node("showSkin2")
onready var showSkin3 = get_node("showSkin3")
onready var showSkin4 = get_node("showSkin4")

func _ready():
    pass

func _process(_delta):
    if level.isPlayerHeadCollidingWith(hideSkin) or level.isPlayerHeadCollidingWith(hideSkin2) or level.isPlayerHeadCollidingWith(hideSkin3) or level.isPlayerHeadCollidingWith(hideSkin4):
        whaleSkinSprite.visible = false
    elif level.isPlayerHeadCollidingWith(showSkin) or level.isPlayerHeadCollidingWith(showSkin2) or level.isPlayerHeadCollidingWith(showSkin3) or level.isPlayerHeadCollidingWith(showSkin4):
        whaleSkinSprite.visible = true
