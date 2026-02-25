extends Spatial

onready var level = get_tree().get_root().get_node("Game/Viewport/level")

var blockingRocks = []
var am_i_active = true
func _ready():
    var waterfallCurrents = get_children()
    var rocks = level.get_tree().get_nodes_in_group("rock_group")
    for i in range(len(rocks)):
        var rock = rocks[i]
        var rPos = rock.global_transform.origin
        for j in range(len(waterfallCurrents)):
            var waterfall = waterfallCurrents[j]
            var wPos = waterfall.global_transform.origin
            if rPos.x == wPos.x and rPos.y == wPos.y:
                blockingRocks.push_back(weakref(rock))
                break
    if len(blockingRocks) > 0:
        inactivateWaterfall()

var try_to_check_timer = 0
var try_to_check_time_limit = 5
func _process(delta):
    if len(blockingRocks) <= 0:
        return
    try_to_check_timer += (delta*22)
    if try_to_check_timer >= try_to_check_time_limit:
        try_to_check_timer = 0
        var are_any_blocking_rocks_visible = false
        for i in range(len(blockingRocks)):
            var rock = blockingRocks[i].get_ref()
            if rock == null: continue
            if rock.visible:
                are_any_blocking_rocks_visible = true
                break
        if are_any_blocking_rocks_visible and am_i_active:
            inactivateWaterfall()
        elif not are_any_blocking_rocks_visible and not am_i_active:
            activateWaterfall()

func activateWaterfall():
    if am_i_active: return

    level.waterfallStartSound.pitch_scale = rand_range(0.9, 1.1)
    level.waterfallStartSound.play()
    am_i_active = true
    var waterfallCurrents = get_children()
    for j in range(len(waterfallCurrents)):
        var waterfall = waterfallCurrents[j]
        waterfall.visible = true

func inactivateWaterfall():
    if not am_i_active: return
    
    am_i_active = false
    var waterfallCurrents = get_children()
    for j in range(len(waterfallCurrents)):
        var waterfall = waterfallCurrents[j]
        waterfall.visible = false
