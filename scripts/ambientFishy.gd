extends Spatial

var original_pos = null
var target_pos = null
onready var mySprite = get_node("Sprite3D")
export var is_jelly = false

onready var level = get_tree().get_root().get_node("level")

var is_swimmin_away = false

func _ready():
    set_process(true)
    original_pos = global_transform.origin
    randomizeTargetPos()
    mySprite.global_transform.origin = self.global_transform.origin

func _process(delta):    
    var MULT = 2 if is_jelly else 5
    global_transform.origin = global_transform.origin + (target_pos - global_transform.origin) * (delta*MULT)

    var diff = target_pos - global_transform.origin
    var step = 0.1

    if level.isPlayerHeadCollidingWith(mySprite):
      passiveActivate()

    if is_swimmin_away:
        step = 5
        if stepify(target_pos.x, 0.1) == stepify(global_transform.origin.x, 0.1) and \
        stepify(target_pos.y, 0.1) == stepify(global_transform.origin.y, 0.1):
            is_swimmin_away = false
            randomizeTargetPos()
    elif stepify(abs(diff.x), step) == 0 and stepify(abs(diff.y), step) == 0:
        randomizeTargetPos()
        
func randomizeTargetPos():
  if is_jelly:
    target_pos = Vector3(
        original_pos.x + rand_range(-3, 3),
        original_pos.y + rand_range(-3, 3),
        original_pos.z
    )
  else:
    target_pos = Vector3(
        original_pos.x + rand_range(-1, 1),
        original_pos.y + rand_range(-1, 1),
        original_pos.z
    )
  mySprite.flip_h = (target_pos.x < global_transform.origin.x)

func passiveActivate():
    if not is_swimmin_away:
        is_swimmin_away = true
    var x_min = 2
    var x_max = 3
    var y_min = 2
    var y_max = 3
    if level.player.global_transform.origin.x > self.global_transform.origin.x:
        x_min = -3
        x_max = -2
    if level.player.global_transform.origin.y > self.global_transform.origin.y:
        y_min = -3
        y_max = -2
    if is_jelly:
        y_min *= 2
        y_max *= 2
        x_min *= 2
        x_max *= 2
    target_pos = Vector3(
        global_transform.origin.x + rand_range(x_min, x_max),
        global_transform.origin.y + rand_range(y_min, y_max),
        original_pos.z
    )
    mySprite.flip_h = (target_pos.x < global_transform.origin.x)