extends Spatial

onready var level = get_tree().get_root().get_node("Game/Viewport/level")
onready var aniPlayer = get_node("AnimationPlayer")
onready var clonkSound = get_node("ClonkSound")
onready var weakRicochetSound = get_node("WeakRicochetSound")
onready var mySprite = get_node("Sprite3D")

var facing = global.DirRight
var moveVel = global.DirRight
var moveVelAcc = Vector2(0, 0)
var opacity = 1
var is_ricocheting = false

func _ready():
    set_process(true)
    moveVel = facing

func _process(delta):
    moveVel += moveVelAcc * (delta * 10)
    self.global_transform.origin.x += (moveVel.x * (delta*10))
    self.global_transform.origin.y += (moveVel.y * (delta*10))
    if is_ricocheting:
        opacity -= (delta * 3)
        if opacity < 0: queue_free()
        return
    else:
        opacity -= (delta * 2)
        if opacity < 0: queue_free()
    mySprite.opacity = opacity

    var npcs = level.get_tree().get_nodes_in_group("npc_group")
    for i in range(len(npcs)):
        var npc = npcs[i]
        if didCollideWithTarget(npc):
            for j in range(2):
                level._spawnBubble(npc.global_transform.origin, j)
            var was_coconut_absorbed = npc.getHitWithCoconut(facing)
            if not was_coconut_absorbed:
                activateRicochet()
                weakRicochetSound.pitch_scale = rand_range(1.4, 1.6)
                weakRicochetSound.play()
            else:
                queue_free()
    var solids = level.get_tree().get_nodes_in_group("solid_group")
    var rocks = level.get_tree().get_nodes_in_group("rock_group")
    var solids_and_rocks = solids
    solids_and_rocks.append_array(rocks)
    for i in range(len(solids_and_rocks)):
        var solidOrRock = solids_and_rocks[i]
        if didCollideWithTarget(solidOrRock):
            for j in range(2):
                level._spawnBubble(solidOrRock.global_transform.origin, j)
            activateRicochet()
            weakRicochetSound.pitch_scale = rand_range(1.4, 1.6)
            weakRicochetSound.play()

func didCollideWithTarget(target, lb = -1, tb = 1, rb = 1, bb = -1):
    if not target.visible: return false
    var pos = self.global_transform.origin
    var tPos = target.global_transform.origin
    return pos.x > tPos.x + lb and pos.x < tPos.x + rb and pos.y > tPos.y + bb and pos.y < tPos.y + tb

func activateRicochet():
    facing = -facing
    moveVel = facing
    if facing.x == 0:
        moveVelAcc.x = -1
        facing.x = 1
    elif facing.y == 0:
        moveVelAcc.y = -1
        facing.y = 1
    clonkSound.play()
    opacity = 1.0
    is_ricocheting = true
