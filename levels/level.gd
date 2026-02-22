extends Spatial

onready var player = get_node("player")
onready var orange = get_node("orange")

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
onready var textBox = get_node("CanvasLayer/TextBox")
onready var textBoxText = get_node("CanvasLayer/TextBox/Text")
onready var textBoxTop = get_node("CanvasLayer/TextBoxTop")
onready var textBoxTopText = get_node("CanvasLayer/TextBoxTop/Text")
onready var camera = get_node("Camera")
onready var deathOverlay = get_node("CanvasLayer/DeathOverlay")
onready var deathOverlayText = get_node("CanvasLayer/DeathOverlay/Text")

var CAMERA_X_OFFSET = 6
var CAMERA_Y_OFFSET = 5
var minimum_camera_x = 0
var currentCameraXBounds = Vector2(0, 0)
var currentCameraYBounds = Vector2(0, 0)
var sin_counter = 0
var helpful_counter = 0
var bubbleRes = preload("res://sceneObjects/bubble.tscn")
var heartBubbleRes = preload("res://sceneObjects/heartBubble.tscn")
var random_bubble_timer = 0
var random_bubble_time_limit = 10
var death_counter = 0
var move_counter = 0
var combo_counter = 0
var trick_counter = 0
var max_combo = 0
var prevTextBoxVisible = false
var prevTextBoxTopVisible = false

var causeOfDeathStr = "you died"

var how_many_oranges_ate = 0
var how_many_coconuts_ate = 0
var how_many_lemons_ate = 0
var how_many_heart_fruit_ate = 0
var adventure_camera_size = 10
var should_snap_camera = false
var parasite_damage_counter = 0
var parasite_damage_count_max = 10
var parasite_oof_counter = 0
var parasite_oof_counter_max = 3

func _ready():
    textBox.visible = true
    textBoxText.bbcode_text = "[color=#ff8426]if you so desire:\n    * use[/color] [wave]arrow keys[/wave] [color=#ff8426]to move..[/color]"
    set_process(true)

var lemon_failsafe_counter = 0
var lemon_failsafe_count_max = 7
# var move_on_my_own_timer = 0
# var move_on_my_own_time_max = 8

var charging_move_timer = 0
var charging_move_time_limit = 1.5
var moveInputDir = Vector2(0, 0)
var lastPressedDirQueue = []
var lastPressedMoveDir = global.DirRight
# TODO(jaketrower): I feel like this should live in the player controller now
func processMoveInputTimer(delta):
    processLastDirPressedQueue()
    moveInputDir = Vector2(0, 0)
    if player.is_charging:
        charging_move_timer += (delta*22)
        if charging_move_timer >= charging_move_time_limit:
            if len(lastPressedDirQueue) > 0:
                moveInputDir = lastPressedDirQueue[len(lastPressedDirQueue) - 1]
            else:
                moveInputDir = lastPressedMoveDir
            player.chargeForwardStep()
            charging_move_timer = 0
    elif not player.is_charging_up_charge and len(lastPressedDirQueue) > 0:
        moveInputDir = lastPressedDirQueue.pop_back()

# TODO(jaketrower): I feel like this should live in the player controller now
func processLastDirPressedQueue():
    var preventChargingTurnAround = (player.is_charging or player.is_charging_up_charge) and len(player.myBodyParts) > 1
    if Input.is_action_just_pressed("ui_up"):
        if player.is_stunned or (player.facing == global.DirDown and preventChargingTurnAround):
            playErrorSound()
        else:
            lastPressedMoveDir = global.DirUp
            if player.is_charging_up_charge: playerMovedBubbleSpawn(player)
            lastPressedDirQueue.push_back(global.DirUp)
    elif Input.is_action_just_pressed("ui_left"):
        if player.is_stunned or (player.facing == global.DirRight and preventChargingTurnAround):
            playErrorSound()
        else:
            lastPressedMoveDir = global.DirLeft
            if player.is_charging_up_charge: playerMovedBubbleSpawn(player)
            lastPressedDirQueue.push_back(global.DirLeft)
    elif Input.is_action_just_pressed("ui_down"):
        if player.is_stunned or (player.facing == global.DirUp and preventChargingTurnAround):
            playErrorSound()
        else:
            lastPressedMoveDir = global.DirDown
            if player.is_charging_up_charge: playerMovedBubbleSpawn(player)
            lastPressedDirQueue.push_back(global.DirDown)
    elif Input.is_action_just_pressed("ui_right"):
        if player.is_stunned or (player.facing == global.DirLeft and preventChargingTurnAround):
            playErrorSound()
        else:
            if player.is_charging_up_charge: playerMovedBubbleSpawn(player)
            lastPressedMoveDir = global.DirRight
            lastPressedDirQueue.push_back(global.DirRight)
    if Input.is_action_just_released("ui_up"):
        lastPressedDirQueue.remove(lastPressedDirQueue.find(global.DirUp))
    if Input.is_action_just_released("ui_left"):
        lastPressedDirQueue.remove(lastPressedDirQueue.find(global.DirLeft))
    if Input.is_action_just_released("ui_down"):
        lastPressedDirQueue.remove(lastPressedDirQueue.find(global.DirDown))
    if Input.is_action_just_released("ui_right"):
        lastPressedDirQueue.remove(lastPressedDirQueue.find(global.DirRight))

func shouldMoveUp():
    return moveInputDir.y > 0
func shouldMoveDown():
    return moveInputDir.y < 0
func shouldMoveLeft():
    return moveInputDir.x < 0
func shouldMoveRight():
    return moveInputDir.x > 0

func _process(delta):
    if global.gameState == global.GameState.RESTART_EGG_HATCHING_ANIMATION:
        updateGameCamera(delta)
        return

    var has_player_moved = false
    if not deathOverlay.visible:
        # TODO(jaketrower): I feel like this should live in the player controller now
        if not player.is_charging and Input.is_action_just_pressed("ui_cancel"):
            if not player.is_stunned and player.restoreBodyPartPositions(true):
                combo_counter -= 1
                bubbleReverseSound.pitch_scale = rand_range(0.4, 0.8)
                bubbleReverseSound.play()
            else:
                player.maybeAdvanceBodyPartAnimationFrames()
                player.should_advance_animation_frame = not player.should_advance_animation_frame
                playErrorSound()
        # TODO(jaketrower): I feel like this should live in the player controller now
        else:   
            processMoveInputTimer(delta)
            if shouldMoveUp():
                has_player_moved = player.moveUp()
                playerMovedBubbleSpawn()
            elif shouldMoveDown():
                has_player_moved = player.moveDown()
                playerMovedBubbleSpawn()
            if shouldMoveLeft():
                has_player_moved = player.moveLeft()
                playerMovedBubbleSpawn()
            elif shouldMoveRight():
                has_player_moved = player.moveRight()
                playerMovedBubbleSpawn()
            else:
                random_bubble_timer += (delta*22)
                if random_bubble_timer >= random_bubble_time_limit:
                    random_bubble_timer = 0
                    random_bubble_time_limit = rand_range(10, 40)
                    spawnBubble(player.headSprite.global_transform.origin, 0)
    if has_player_moved:
        move_counter += 1
    # okay, semi-regardless of game state...
    if global.gameState != global.GameState.GAME_OVER:
        thingsToDoRegardlessOfGameState(has_player_moved, delta)
        
    updateGameCamera(delta)
    if has_player_moved:
        if isPlayerEating(orange):
            player.eatAnOrange()
            for i in range(3):
                spawnBubble(player.headSprite.global_transform.origin, i + 1)    
            if how_many_oranges_ate >= 2:
                textBox.visible = false
            while doesIntersectWithAnyBodyPart(orange) or (orange.global_transform.origin.x == 0 and orange.global_transform.origin.y == 0):
                orange.global_transform.origin.x = randi() % 7 - 3
                orange.global_transform.origin.y = randi() % 7 - 3
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
            # global.gameState = global.GameState.NORMAL_GAMEPLAY
            global.gameState = global.GameState.RESTART_EGG_HATCHING_ANIMATION
            player.initiateHatchAnimation()
            

func playErrorSound():
    errorSound.pitch_scale = rand_range(0.9, 1.1)
    errorSound.play()

# TODO(jaketrower): I feel like this should live in the player controller now
func isPlayerOutOfBounds(which_player = player):
    var lb = currentCameraXBounds.x - CAMERA_X_OFFSET
    var rb = currentCameraXBounds.y + CAMERA_X_OFFSET
    var tb = currentCameraYBounds.x + CAMERA_Y_OFFSET
    var bb = currentCameraYBounds.y - CAMERA_Y_OFFSET
    var headPos = which_player.headSprite.global_transform.origin
    return headPos.x <= lb or headPos.x >= rb or headPos.y >= tb or headPos.y <= bb

# TODO(jaketrower): I feel like this should live in the player controller now
func thingsToDoRegardlessOfGameState(_has_player_moved, delta):
    var headPos = player.headSprite.global_transform.origin
    var csgPos = player.csgCombinerPosition.global_transform.origin
    # camera.size = camera.size + (adventure_camera_size - camera.size) * (delta*5)
    player.csgCombinerPosition.global_transform.origin.x = csgPos.x + (headPos.x - csgPos.x) * (delta * 5)
    player.csgCombinerPosition.global_transform.origin.y = csgPos.y + (headPos.y - csgPos.y) * (delta * 5)

    if Input.is_action_just_pressed("ui_select"):
        player.startChargeUp()
    elif Input.is_action_pressed("ui_select"):
        player.chargeUp()
    elif Input.is_action_just_released("ui_select"):
        # player.spitCoconutProjectile()
        player.tryChargeAhead()
        pass

func playerMovedBubbleSpawn(which_player = player):
    random_bubble_timer = 0
    bubbleSound.pitch_scale = rand_range(0.4, 0.8)
    bubbleSound.play()
    var how_many = 2
    for i in range(how_many):
        spawnBubble(which_player.headSprite.global_transform.origin, i)

func playerMovedEatAnOrange():
    if isPlayerEating(orange):
        player.eatAnOrange()
        for i in range(3):
            spawnBubble(player.headSprite.global_transform.origin, i + 1)
        print("bro?")
        orange.visible = false

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

func spawnBubble(pos, time_to_yield = 0, which_bubble_res = bubbleRes):
    if time_to_yield > 0:
        yield(get_tree().create_timer(0.1*time_to_yield), "timeout")
    var newBubble = which_bubble_res.instance()
    self.add_child(newBubble)
    newBubble.global_transform.origin = pos
    newBubble.global_transform.origin.y += rand_range(0.3, 0.8)
    newBubble.global_transform.origin.x += rand_range(-0.5, 0.5)
    if randi() % 2 <= 1:
        newBubble.which_x = -1

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
        camera.global_transform.origin = camera.global_transform.origin + (player.cameraTarget.global_transform.origin - camera.global_transform.origin) * (delta*2)
        # if camera.global_transform.origin.x > currentCameraXBounds.y:
        #     camera.global_transform.origin.x = currentCameraXBounds.y
        # elif camera.global_transform.origin.x < currentCameraXBounds.x:
        #     camera.global_transform.origin.x = currentCameraXBounds.x
        # if camera.global_transform.origin.y < currentCameraYBounds.y:
        #     camera.global_transform.origin.y = currentCameraYBounds.y
        # elif camera.global_transform.origin.y > currentCameraYBounds.x:
        #     camera.global_transform.origin.y = currentCameraYBounds.x
            
    var coverOfDarknessAlpha = 0
    var y = camera.global_transform.origin.y
    coverOfDarknessAlpha = ((-40 - y) / 20)

    if coverOfDarknessAlpha < 0: coverOfDarknessAlpha = 0
    if coverOfDarknessAlpha > 1: coverOfDarknessAlpha = 1
    player.coverOfDarkness.material.albedo_color.a = coverOfDarknessAlpha
