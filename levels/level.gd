extends Spatial

var text3dRes = preload("res://sceneObjects/3DText.tscn")

onready var player = get_node("player")
onready var camera = get_node("Camera")

onready var sillyFishSong = get_node("Music/SillyFishSong")
onready var crabTimeSong = get_node("Music/CrabTimeSong")
onready var enterTheDeepSong = get_node("Music/EnterTheDeepSong")
onready var tensionSong = get_node("Music/TensionSong")
onready var partySong = get_node("Music/PartySong")

onready var ewSound = get_node("Sounds/EwSound")
onready var bubbleSound = get_node("Sounds/BubbleSound")
onready var bubbleReverseSound = get_node("Sounds/BubbleReverseSound")
onready var equipCoconutSound = get_node("Sounds/EquipCoconutSound")
onready var coconutChompSound = get_node("Sounds/CoconutChompSound")
onready var shatterSound = get_node("Sounds/ShatterSound")
onready var sadSound = get_node("Sounds/SadSound")
onready var kissSound = get_node("Sounds/KissSound")
onready var swooshSound = get_node("Sounds/SwooshSound")
onready var oofSound = get_node("Sounds/OofSound")
onready var umSound = get_node("Sounds/UmSound")
onready var crabSound = get_node("Sounds/CrabSound")
onready var bigOwSound = get_node("Sounds/BigOwSound")
onready var heySound = get_node("Sounds/HeySound")
onready var errorSound = get_node("Sounds/ErrorSound")
onready var lemonSound = get_node("Sounds/LemonSound")
onready var whatsupSound = get_node("Sounds/WhatsupSound")
onready var heyUpsetSound = get_node("Sounds/HeyUpsetSound")
onready var deadParasiteSound = get_node("Sounds/DeadParasiteSound")
onready var screamSound = get_node("Sounds/ScreamSound")
onready var waterfallStartSound = get_node("Sounds/WaterfallStartSound")

onready var textBox = get_tree().get_root().get_node("Game/CanvasLayer/TextBox")
onready var textBoxText = get_tree().get_root().get_node("Game/CanvasLayer/TextBox/Text")
onready var textBoxTop = get_tree().get_root().get_node("Game/CanvasLayer/TextBoxTop")
onready var textBoxTopText = get_tree().get_root().get_node("Game/CanvasLayer/TextBoxTop/Text")
onready var statsBox = get_tree().get_root().get_node("Game/CanvasLayer/StatsBox")
onready var statsBoxText = get_tree().get_root().get_node("Game/CanvasLayer/StatsBox/Text")
onready var deathOverlay = get_tree().get_root().get_node("Game/CanvasLayer/DeathOverlay")
onready var deathOverlayText = get_tree().get_root().get_node("Game/CanvasLayer/DeathOverlay/Text")

var minimum_camera_x = 0
var currentCameraXBounds = Vector2(-4, 60)
var currentCameraYBounds = Vector2(30, -60)
var sin_counter = 0
var helpful_counter = 0
var bubbleRes = preload("res://sceneObjects/bubble.tscn")
var heartBubbleRes = preload("res://sceneObjects/heartBubble.tscn")
var death_counter = 0
var combo_counter = 0
var trick_counter = 0
var max_combo = 0
var prevTextBoxVisible = false
var prevTextBoxTopVisible = false

var causeOfDeathStr = "you died"

# look into global.memory instead
# var how_many_oranges_ate = 0
var how_many_lemons_ate = 0
var how_many_heart_fruit_ate = 0
var adventure_camera_size = 10
var should_snap_camera = false
var parasite_damage_counter = 0
var parasite_damage_count_max = 10
var parasite_oof_counter = 0
var parasite_oof_counter_max = 3

var hideTextBoxMoveCount = -1

func _ready():
    textBox.visible = true
    textBoxText.bbcode_text = "[color=#ff8426]if you so desire:\n    * use[/color] [wave]arrow keys[/wave] [color=#ff8426]to move..[/color]"
    statsBox.visible = false
    set_process(true)
    hideTextBoxMoveCount = 10

var lemon_failsafe_counter = 0
var lemon_failsafe_count_max = 7
# var move_on_my_own_timer = 0
# var move_on_my_own_time_max = 8

func _process(delta):
    if global.gameState == global.GameState.RESTART_EGG_HATCHING_ANIMATION:
        updateGameCamera(delta)
        return
    var has_player_moved = false
    if global.gameState != global.GameState.GAME_OVER:
        has_player_moved = player.playerMover.processMain(delta)
    updateGameCamera(delta)
    if has_player_moved:
        global.memory["move_counter"] += 1
        if hideTextBoxMoveCount >= 0 and global.memory["move_counter"] >= hideTextBoxMoveCount:
            hideTextBoxMoveCount = -1
            textBox.visible = false
        processNpcInteractions()
        processFruitInteractions()
    elif global.gameState == global.GameState.GAME_OVER:
        player.processDeath(delta)
        textBoxTop.visible = false
        if not deathOverlay.visible:
            deathOverlay.visible = true
            deathOverlayText.bbcode_text = "[center]you died...[/center]\ncause of death:\n    [color=red][shake]" + causeOfDeathStr + "[/shake][/color]\n\ntry again? press ENTER"
        deathOverlay.color.a += 0.2 * delta
        if deathOverlay.color.a > 1:
            deathOverlay.color.a = 1
        if Input.is_action_just_pressed("ui_accept"):
            # player.restoreBodyPartPositions()
            deathOverlay.visible = false
            deathOverlay.color.a = 0
            textBoxTop.visible = false
            textBox.visible = false
            if last_speaker != null: last_speaker.get_ref().stopTalking()
            last_speaker = null
            # global.gameState = global.GameState.NORMAL_GAMEPLAY
            global.gameState = global.GameState.RESTART_EGG_HATCHING_ANIMATION
            player.initiateHatchAnimation()

var charging_initiation_npc_dist = 2
var initiation_npc_dist = 4
var byebye_npc_dist = 5
var last_speaker = null
func processNpcInteractions():
    var npcs = self.get_tree().get_nodes_in_group("npc_group")
    var nearest_npc = null
    var nearest_dist = 999
    for i in range(len(npcs)):
        var npc = npcs[i]
        var dist = player.headSprite.global_transform.origin.distance_to(npc.global_transform.origin)
        if dist < nearest_dist and (
            ((
                (not player.is_charging and dist <= initiation_npc_dist)
                or (player.is_charging and dist <= charging_initiation_npc_dist)
            ) and npc.bbcode_text != "")
            or (last_speaker != null and npc == last_speaker.get_ref())
        ):
            nearest_npc = npc
            nearest_dist = dist
    if nearest_npc != null:
        if not nearest_npc.is_talking:
            setNewLastSpeaker(nearest_npc)
            self.textBoxText.bbcode_text = nearest_npc.startTalking()
            self.textBox.visible = true
        elif last_speaker != null and last_speaker.get_ref() != null and last_speaker.get_ref() == nearest_npc:
            if nearest_dist > byebye_npc_dist:
                self.textBox.visible = false
                last_speaker.get_ref().stopTalking()
                last_speaker = null
            else:
                nearest_npc.keepTalking()
        
func setNewLastSpeaker(npc):
    if last_speaker != null and last_speaker.get_ref() != null:
        last_speaker.get_ref().stopTalking(true) # (did_someone_else_start_talking)
    last_speaker = weakref(npc)

func processFruitInteractions():
    var oranges = get_tree().get_nodes_in_group("orange_group")
    for i in range(len(oranges)):
        var orange = oranges[i]
        if isPlayerEating(orange):
            player.eatAnOrange()
            for j in range(3):
                _spawnBubble(player.headSprite.global_transform.origin, j + 1)    
            while doesIntersectWithAnyBodyPart(orange) or (orange.global_transform.origin.x == 0 and orange.global_transform.origin.y == 0):
                orange.global_transform.origin.x = randi() % 7 - 3
                orange.global_transform.origin.y = randi() % 7 - 3
    var coconuts = get_tree().get_nodes_in_group("coconut_group")
    for i in range(len(coconuts)):
        var coconut = coconuts[i]
        if isPlayerEating(coconut):
            player.eatACoconut()
            for j in range(3):
                _spawnBubble(player.headSprite.global_transform.origin, j + 1)    
            while doesIntersectWithAnyBodyPart(coconut) or (coconut.global_transform.origin.x == 0 and coconut.global_transform.origin.y == 0):
                coconut.global_transform.origin.x = randi() % 7 - 3
                coconut.global_transform.origin.y = randi() % 7 - 3
    var rockFruits = get_tree().get_nodes_in_group("rockfruit_group")
    for i in range(len(rockFruits)):
        var rockFruit = rockFruits[i]
        if isPlayerEating(rockFruit):
            player.eatARockFruit()
            for j in range(3):
                _spawnBubble(player.headSprite.global_transform.origin, j + 1)
            rockFruit.visible = false
    var multiberries = get_tree().get_nodes_in_group("multiberry_group")
    for i in range(len(multiberries)):
        var multiberry = multiberries[i]
        if isPlayerEating(multiberry):
            player.eatAMultiberry()
            for j in range(3):
                _spawnBubble(player.headSprite.global_transform.origin, j + 1)
            multiberry.visible = false

            
func playErrorSound():
    errorSound.pitch_scale = rand_range(0.9, 1.1)
    errorSound.play()

func spawnBubbles(pos, how_many = 1):
    bubbleSound.pitch_scale = rand_range(0.4, 0.8)
    bubbleSound.play()
    for i in range(how_many):
        _spawnBubble(pos, i)

func _spawnBubble(pos, time_to_yield = 0, which_bubble_res = bubbleRes):
    if time_to_yield > 0:
        yield(get_tree().create_timer(0.1*time_to_yield), "timeout")
    var newBubble = which_bubble_res.instance()
    self.add_child(newBubble)
    newBubble.global_transform.origin = pos
    newBubble.global_transform.origin.y += rand_range(0.3, 0.8)
    newBubble.global_transform.origin.x += rand_range(-0.5, 0.5)
    if randi() % 2 <= 1:
        newBubble.which_x = -1

func isPlayerHeadCollidingWith(target, lb = -0.5, tb = 0.5, rb = 0.5, bb = -0.5, which_player = player):
    var pos = which_player.headSprite.global_transform.origin
    var tPos = target.global_transform.origin
    return pos.x > tPos.x + lb and pos.x < tPos.x + rb and pos.y > tPos.y + bb and pos.y < tPos.y + tb

func isPlayerEating(sprite, which_player = player):
    if not sprite.visible:
        return false
    return sprite.global_transform.origin.x == which_player.headSprite.global_transform.origin.x and sprite.global_transform.origin.y == which_player.headSprite.global_transform.origin.y

func doesIntersectWithAnyBodyPart(sprite, which_player = player):
    var spritePos = sprite.global_transform.origin
    for i in range(len(which_player.myBodyParts)):
        var bodyPart = which_player.myBodyParts[i]
        var bodyPartPos = bodyPart.global_transform.origin
        if spritePos.x == bodyPartPos.x and spritePos.y == bodyPartPos.y:
            return true
    return false 

func faceUp(sprite):
    sprite.rotation_degrees.z = 90
    sprite.flip_h = false

func faceDown(sprite):
    sprite.rotation_degrees.z = -90
    sprite.flip_h = false

func faceLeft(sprite):
    sprite.rotation_degrees.z = 0
    sprite.flip_h = true

func faceRight(sprite):
    sprite.rotation_degrees.z = 0
    sprite.flip_h = false

func immediatelySnapGameCamera():
    camera.global_transform.origin = player.cameraTarget.global_transform.origin

func updateGameCamera(delta, x_bounds = null, y_bounds = null):
    if x_bounds != null: currentCameraXBounds = x_bounds
    if y_bounds != null: currentCameraYBounds = y_bounds

    var size_to_use = adventure_camera_size
    camera.size = camera.size + (size_to_use - camera.size) * (delta*5)
    if stepify(camera.size, 0.1) == stepify(size_to_use, 0.1):
        camera.size = size_to_use
    if should_snap_camera:
        camera.global_transform.origin = player.cameraTarget.global_transform.origin
    elif camera.size == size_to_use:
        camera.global_transform.origin = camera.global_transform.origin + (player.cameraTarget.global_transform.origin - camera.global_transform.origin) * (delta*5)
        if camera.global_transform.origin.x > currentCameraXBounds.y:
            camera.global_transform.origin.x = currentCameraXBounds.y
        elif camera.global_transform.origin.x < currentCameraXBounds.x:
            camera.global_transform.origin.x = currentCameraXBounds.x
        if camera.global_transform.origin.y < currentCameraYBounds.y:
            camera.global_transform.origin.y = currentCameraYBounds.y
        elif camera.global_transform.origin.y > currentCameraYBounds.x:
            camera.global_transform.origin.y = currentCameraYBounds.x
            
    var coverOfDarknessAlpha = 0
    var y = camera.global_transform.origin.y
    coverOfDarknessAlpha = ((-40 - y) / 20)

    if coverOfDarknessAlpha < 0: coverOfDarknessAlpha = 0
    if coverOfDarknessAlpha > 1: coverOfDarknessAlpha = 1
    player.coverOfDarkness.material.albedo_color.a = coverOfDarknessAlpha

func createNewAwesomeText(textToUse, pos, is_lame = false):
    var newAwesomeText = text3dRes.instance()
    self.add_child(newAwesomeText)
    newAwesomeText.setText(textToUse, is_lame)
    newAwesomeText.global_transform.origin = pos
