extends Spatial

onready var level = get_tree().get_root().get_node("Game/Viewport/level")
onready var myParent = get_node("..")
onready var headSprite = get_node("../headSprite")

var should_advance_animation_frame = false
var random_bubble_timer = 0
var random_bubble_time_limit = 10

var charging_move_timer = 0
var charging_move_time_limit = 1.5
var charge_count = 0
var charge_count_max = 14
var is_charge_charged = false
var is_charging_up_charge = false
var moveInputDir = Vector2(0, 0)
var lastPressedDirQueue = []
var lastPressedMoveDir = global.DirRight
var MAX_UNDO_SIZE = 7
var prevBodyPartsStatesStack = []


# ====================================
func processMain(delta):
    var has_player_moved = false
    if not myParent.is_charging and Input.is_action_just_pressed("ui_cancel"):
        if not myParent.is_stunned and restoreBodyPartPositions(true):
            level.combo_counter -= 1
            level.bubbleReverseSound.pitch_scale = rand_range(0.4, 0.8)
            level.bubbleReverseSound.play()
        else:
            maybeAdvanceBodyPartAnimationFrames()
            should_advance_animation_frame = not should_advance_animation_frame
            level.playErrorSound()
    else:   
        processMoveInputs(delta)
        if shouldMoveUp():
            has_player_moved = moveUp()
        elif shouldMoveDown():
            has_player_moved = moveDown()
        if shouldMoveLeft():
            has_player_moved = moveLeft()
        elif shouldMoveRight():
            has_player_moved = moveRight()
        else:
            random_bubble_timer += (delta*22)
            if random_bubble_timer >= random_bubble_time_limit:
                random_bubble_timer = 0
                random_bubble_time_limit = rand_range(10, 90)
                level.spawnBubbles(headSprite.global_transform.origin)
    if has_player_moved:
        random_bubble_timer = 0
        level.spawnBubbles(headSprite.global_transform.origin, 1 if myParent.is_charging else 2)
    var headPos = headSprite.global_transform.origin
    var csgPos = myParent.csgCombinerPosition.global_transform.origin
    # camera.size = camera.size + (adventure_camera_size - camera.size) * (delta*5)
    myParent.csgCombinerPosition.global_transform.origin.x = csgPos.x + (headPos.x - csgPos.x) * (delta * 5)
    myParent.csgCombinerPosition.global_transform.origin.y = csgPos.y + (headPos.y - csgPos.y) * (delta * 5)
    return has_player_moved

# ====================== INPUT HANDLING =======================
func processMoveInputs(delta):
    processLastDirPressedQueue()
    moveInputDir = Vector2(0, 0)
    if myParent.is_charging:
        if Input.is_action_just_pressed("ui_cancel"):
            can_stop_the_charge = true
            myParent.skidStopSound.pitch_scale = rand_range(1.2, 1.5)
            myParent.skidStopSound.play()
        if Input.is_action_pressed("ui_cancel") and can_stop_the_charge:
            if charge_stop_counter == 0:
                charging_move_timer += (delta*22)
            else:
                charging_move_timer += (delta*11)
        else:
            charging_move_timer += (delta*22)
        if charging_move_timer >= charging_move_time_limit:
            if len(lastPressedDirQueue) > 0:
                moveInputDir = lastPressedDirQueue[len(lastPressedDirQueue) - 1]
            else:
                moveInputDir = lastPressedMoveDir
            chargeForwardStep()
            charging_move_timer = 0
    elif not is_charging_up_charge and len(lastPressedDirQueue) > 0:
        moveInputDir = lastPressedDirQueue.pop_back()
    if not myParent.is_stunned:
        if Input.is_action_just_pressed("ui_select"):
            startChargeUp()
        elif Input.is_action_pressed("ui_select"):
            chargeUp()
        elif Input.is_action_just_released("ui_select"):
            # player.spitCoconutProjectile()
            tryChargeAhead()
            pass

func processLastDirPressedQueue():
    var preventChargingTurnAround = (myParent.is_charging or is_charging_up_charge) and len(myParent.myBodyParts) > 1
    if Input.is_action_just_pressed("ui_up"):
        if myParent.is_stunned or (myParent.facing == global.DirDown and preventChargingTurnAround):
            level.playErrorSound()
        else:
            lastPressedMoveDir = global.DirUp
            if is_charging_up_charge: level.spawnBubbles(headSprite.global_transform.origin)
            lastPressedDirQueue.push_back(global.DirUp)
    elif Input.is_action_just_pressed("ui_left"):
        if myParent.is_stunned or (myParent.facing == global.DirRight and preventChargingTurnAround):
            level.playErrorSound()
        else:
            lastPressedMoveDir = global.DirLeft
            if is_charging_up_charge: level.spawnBubbles(headSprite.global_transform.origin)
            lastPressedDirQueue.push_back(global.DirLeft)
    elif Input.is_action_just_pressed("ui_down"):
        if myParent.is_stunned or (myParent.facing == global.DirUp and preventChargingTurnAround):
            level.playErrorSound()
        else:
            lastPressedMoveDir = global.DirDown
            if is_charging_up_charge: level.spawnBubbles(headSprite.global_transform.origin)
            lastPressedDirQueue.push_back(global.DirDown)
    elif Input.is_action_just_pressed("ui_right"):
        if myParent.is_stunned or (myParent.facing == global.DirLeft and preventChargingTurnAround):
            level.playErrorSound()
        else:
            if is_charging_up_charge: level.spawnBubbles(headSprite.global_transform.origin)
            lastPressedMoveDir = global.DirRight
            lastPressedDirQueue.push_back(global.DirRight)
    if Input.is_action_just_released("ui_up"):
        var idx = lastPressedDirQueue.find(global.DirUp)
        if idx >= 0: lastPressedDirQueue.remove(idx)
    if Input.is_action_just_released("ui_left"):
        var idx = lastPressedDirQueue.find(global.DirLeft)
        if idx >= 0: lastPressedDirQueue.remove(idx)
    if Input.is_action_just_released("ui_down"):
        var idx = lastPressedDirQueue.find(global.DirDown)
        if idx >= 0: lastPressedDirQueue.remove(idx)
    if Input.is_action_just_released("ui_right"):
        var idx = lastPressedDirQueue.find(global.DirRight)
        if idx >= 0: lastPressedDirQueue.remove(idx)

func shouldMoveUp():
    return moveInputDir.y > 0
func shouldMoveDown():
    return moveInputDir.y < 0
func shouldMoveLeft():
    return moveInputDir.x < 0
func shouldMoveRight():
    return moveInputDir.x > 0

func moveUp(): return genericMove(global.DirUp)
func moveDown(): return genericMove(global.DirDown)
func moveLeft(): return genericMove(global.DirLeft)
func moveRight(): return genericMove(global.DirRight)

func genericMove(moveDir):
    if myParent.myBodyParts.size() > 1 and moveDir.is_equal_approx(-myParent.facing):
        maybeAdvanceBodyPartAnimationFrames()
        should_advance_animation_frame = not should_advance_animation_frame
        level.playErrorSound()
        return false
    if myParent.should_grow: grow(moveDir)
    saveBodyPartPositions()
    myParent.facing = moveDir
    headSprite.global_transform.origin.x += moveDir.x
    headSprite.global_transform.origin.y += moveDir.y
    if myParent.myBodyParts.size() > 1:
        headSprite.updateBaseFrame(2, 0)
    else:
        headSprite.updateBaseFrame(0, 0)
    moveMyBodyParts(moveDir)
    if moveDir.x < 0: faceLeft(headSprite)
    elif moveDir.x > 0: faceRight(headSprite)
    elif moveDir.y > 0: faceUp(headSprite)
    elif moveDir.y < 0: faceDown(headSprite)
    if not myParent.tryToEatParasites(): myParent.tryToBeCool()
    should_advance_animation_frame = not should_advance_animation_frame
    return postProcessMoveAttempt(moveDir)

func postProcessMoveAttempt(moveDir):
    if hasCollidedWithAnything(moveDir):
        if myParent.is_charging:
            setSpriteAnimationSpeed(global.IDLE_FRAME_DELAY)
            myParent.chargeStartSound.stop()
            myParent.is_charging = false
            lastPressedDirQueue = []
            myParent.bumpSound.pitch_scale = rand_range(0.7, 0.9)
            myParent.bumpSound.play()
            myParent.owIGotStunned()
        return false
    if len(prevBodyPartsStatesStack) > MAX_UNDO_SIZE:
        prevBodyPartsStatesStack.pop_front()
    return true

# ====================== MOVEMENT HELPER FUNCS =======================
func tryEnterDoor(door):
    if door.partnerDoor != null:
        myParent.headSprite.global_transform.origin.x = door.partnerDoor.global_transform.origin.x
        myParent.headSprite.global_transform.origin.y = door.partnerDoor.global_transform.origin.y
        return true
    return false

func hasCollidedWithAnything(moveDir):
    var doors = level.get_tree().get_nodes_in_group("door_group")
    for i in range(len(doors)):
        var door = doors[i]
        if myParent.isHeadOverlapping(door):
            if tryEnterDoor(door):
                moveMyBodyParts(moveDir)
                myParent.is_charging = false
                level.immediatelySnapGameCamera()
                return false # we don't actually "collide" with it but... we SHOULD pause...

    var crabs = level.get_tree().get_nodes_in_group("crab_group")
    for i in range(len(crabs)):
        var crab = crabs[i]
        if myParent.isHeadOverlapping(crab):
            restoreBodyPartPositions()
            myParent.owIGotHurt()
            crab.killSound.pitch_scale = rand_range(0.8, 1.2)
            crab.killSound.play()
            if myParent.is_charging:
                crab.getMiniStunned()
            return true
    var npcs = level.get_tree().get_nodes_in_group("npc_group")
    for i in range(len(npcs)):
        var npc = npcs[i]
        if myParent.isHeadOverlapping(npc):
            restoreBodyPartPositions()
            level.playErrorSound()
            if myParent.is_charging:
                npc.getMiniStunned()
            return true
    var rocks = level.get_tree().get_nodes_in_group("rock_group")
    for i in range(len(rocks)):
        var rock = rocks[i]
        if myParent.isHeadOverlapping(rock):
            restoreBodyPartPositions()
            if myParent.is_charging:
                rock.rockSmash()
                # TODO(jaketrower): do a little screen shake mini if not disabled (steal from gdc)
            else:
                level.playErrorSound()
            return true
    var solids = level.get_tree().get_nodes_in_group("solid_group")
    for i in range(len(solids)):
        var solid = solids[i]
        if myParent.isHeadOverlapping(solid):
            restoreBodyPartPositions()
            if not myParent.is_charging:
                level.playErrorSound()
            return true
    return false

# ====================== BODY PART MANAGEMENT =======================
func grow(moveDir):
    # TODO(jaketrower): This _x, _y should be set according to the direction that the LAST PREVIOUS BODY PART is moving.
    # so, it will be accurate for the first growth, but not subsequent growths rn
    headSprite.updateBaseFrame(2, 0)
    var newBodySprite = headSprite.duplicate()
    newBodySprite.name = "bodySprite"
    myParent.add_child(newBodySprite)
    newBodySprite.global_transform.origin = myParent.myBodyParts[len(myParent.myBodyParts) - 1].global_transform.origin + Vector3(-moveDir.x, -moveDir.y, -0.05)
    # print(newBodySprite.global_transform.origin)
    newBodySprite.updateBaseFrame(0, 1)
    newBodySprite.frame_delay = global.IDLE_FRAME_DELAY
    newBodySprite.modulate.r = 1
    newBodySprite.modulate.b = 1
    newBodySprite.scale = Vector3(1, 1, 1)
    newBodySprite.follow_player_frame_delay = true
    myParent.myBodyParts.push_back(newBodySprite)
    myParent.should_grow = false
    # growSound.pitch_scale = rand_range(0.8, 1.2)
    # growSound.play()
    yield(get_tree().create_timer(0.3), "timeout")
    myParent.pfftSound.pitch_scale = rand_range(0.8, 1.2)
    myParent.pfftSound.play()
    for i in range(2):
        level._spawnBubble(newBodySprite.global_transform.origin, i)

func moveMyBodyParts(moveDir):
    var _x = moveDir.x
    var x = _x
    var _y = moveDir.y
    var y = _y
    for i in range(1, len(myParent.myBodyParts)):
        var bodyPart = myParent.myBodyParts[i]
        var leadingBodyPart = myParent.myBodyParts[i-1]
        var leadingBodyPartPos = leadingBodyPart.global_transform.origin
        var oldBodyPartPos = bodyPart.global_transform.origin
        bodyPart.global_transform.origin.x = leadingBodyPart.global_transform.origin.x - x
        bodyPart.global_transform.origin.y = leadingBodyPart.global_transform.origin.y - y
        x = bodyPart.global_transform.origin.x - oldBodyPartPos.x
        y = bodyPart.global_transform.origin.y - oldBodyPartPos.y
        # print("old: ", oldBodyPartPos, ", new: ", bodyPart.global_transform.origin)
        var trailingBodyPart = myParent.myBodyParts[i+1] if i < len(myParent.myBodyParts) - 1 else null
        if trailingBodyPart == null:
            updateBodyPartSprite(bodyPart, x, y, _x, _y, leadingBodyPartPos, oldBodyPartPos, 0)
        elif trailingBodyPart != null:
            # need to update rotation between prevBodyPart.pos and currentPos (which will be where nextBodyPart.pos will go)
            # and if it's a straight line (e.g. same X or same Y between the two), need to face/rotate correctly
            updateBodyPartSprite(bodyPart, x, y, _x, _y, leadingBodyPartPos, oldBodyPartPos, 2)
        _x = x
        _y = y
    myParent.cameraTarget.global_transform.origin = headSprite.global_transform.origin
    myParent.cameraTarget.global_transform.origin.z = 6

func maybeAdvanceBodyPartAnimationFrames():
    for i in range(len(myParent.myBodyParts)):
        var bodyPart = myParent.myBodyParts[i]
        bodyPart.updateBaseFrameWithStartFrame(bodyPart.start_frame)
        if should_advance_animation_frame:
            bodyPart.animation_counter = bodyPart.frame_delay
            bodyPart.animate(1)
        else:
            bodyPart.animation_counter = 0

func updateBodyPartSprite(bodyPart, x, y, _x, _y, leadingBodyPartPos, oldBodyPartPos, x_frame):
    if leadingBodyPartPos.x == oldBodyPartPos.x or leadingBodyPartPos.y == oldBodyPartPos.y: 
        bodyPart.updateBaseFrame(x_frame, 1)
        # need to face the right direction
        if x > 0: faceRight(bodyPart)
        elif x < 0: faceLeft(bodyPart)
        elif y > 0: faceUp(bodyPart)
        elif y < 0: faceDown(bodyPart)
    elif leadingBodyPartPos.x > oldBodyPartPos.x and leadingBodyPartPos.y > oldBodyPartPos.y:
        if _x > 0:
            bodyPart.updateBaseFrame(x_frame, 2)
            faceRight(bodyPart)
        elif _y > 0:
            bodyPart.updateBaseFrame(x_frame, 3)
            faceDown(bodyPart)
    elif leadingBodyPartPos.x > oldBodyPartPos.x and leadingBodyPartPos.y < oldBodyPartPos.y: 
        if _x > 0:
            bodyPart.updateBaseFrame(x_frame, 2)
            faceRight(bodyPart)
            bodyPart.flip_v = true
        elif _y < 0:
            bodyPart.updateBaseFrame(x_frame, 2)
            faceDown(bodyPart)
    elif leadingBodyPartPos.x < oldBodyPartPos.x and leadingBodyPartPos.y > oldBodyPartPos.y:
        if _x < 0:
            bodyPart.updateBaseFrame(x_frame, 3)
            faceRight(bodyPart)
            # bodyPart.flip_v = true
        elif _y > 0:
            bodyPart.updateBaseFrame(x_frame, 2)
            faceUp(bodyPart)
    elif leadingBodyPartPos.x < oldBodyPartPos.x and leadingBodyPartPos.y < oldBodyPartPos.y:
        if _x < 0:
            bodyPart.updateBaseFrame(x_frame, 3)
            faceRight(bodyPart)
            bodyPart.flip_v = true
        elif _y < 0:
            bodyPart.updateBaseFrame(x_frame, 3)
            faceUp(bodyPart)
    if should_advance_animation_frame:
        bodyPart.animation_counter = bodyPart.frame_delay
        bodyPart.animate(1)
    else:
        bodyPart.animation_counter = 0

func saveBodyPartPositions():
    var newPrevBodyPartsStates = []
    for i in range(0, len(myParent.myBodyParts)):
        var bodyPart = myParent.myBodyParts[i]
        var bodyPartFacing = bodyPart.facing
        var bodyPartPos = bodyPart.global_transform.origin
        var bodyPartFlipH = bodyPart.flip_h
        var bodyPartFlipV = bodyPart.flip_v
        var bodyPartRotation = bodyPart.rotation_degrees
        var bodyPartStartFrame = bodyPart.start_frame
        newPrevBodyPartsStates.push_back([bodyPartPos, bodyPartFacing, bodyPartFlipH, bodyPartFlipV, bodyPartRotation, bodyPartStartFrame])
    prevBodyPartsStatesStack.push_back(newPrevBodyPartsStates)

func restoreBodyPartPositions(is_manual_reverse = false):
    if len(prevBodyPartsStatesStack) == 0:
        return false
    var prevBodyPartsStates = prevBodyPartsStatesStack.pop_back()
    for i in range(0, len(prevBodyPartsStates)):
        var bodyPart = myParent.myBodyParts[i]
        var prevBodyPartState = prevBodyPartsStates[i]
        bodyPart.global_transform.origin = prevBodyPartState[0]
        if i == 0:
            if len(prevBodyPartsStates) > 1:
                if is_manual_reverse:
                    bodyPart.facing = prevBodyPartState[1]
                    bodyPart.flip_h = prevBodyPartState[2]
                    bodyPart.flip_v = prevBodyPartState[3]
                    bodyPart.rotation_degrees = prevBodyPartState[4]
                    bodyPart.updateBaseFrame(2, 0)
                else:
                    var oldFace = prevBodyPartState[1]
                    var newFace = headSprite.facing
                    if oldFace != newFace:
                        headSprite.updateBaseFrameWithStartFrame(prevBodyPartState[5])
                        # i figured this out just by drawing it... idk man don't make sense to me.
                        if oldFace.y < 0 or (oldFace.x != 0 and oldFace.x == newFace.y):
                            headSprite.updateBaseFrame(0, 5)
                        else:
                            headSprite.updateBaseFrame(2, 5)
                    headSprite.facing = oldFace
        else:
            bodyPart.facing = prevBodyPartState[1]
            bodyPart.flip_h = prevBodyPartState[2]
            bodyPart.flip_v = prevBodyPartState[3]
            bodyPart.rotation_degrees = prevBodyPartState[4]
            bodyPart.updateBaseFrameWithStartFrame(prevBodyPartState[5])
        if should_advance_animation_frame:
            bodyPart.animation_counter = bodyPart.frame_delay
            bodyPart.animate(1)
        else:
            bodyPart.animation_counter = 0
    myParent.facing = headSprite.facing
    myParent.cameraTarget.global_transform.origin = headSprite.global_transform.origin
    myParent.cameraTarget.global_transform.origin.z = 6
    return true

func faceUp(sprite):
    sprite.facing = global.DirUp
    sprite.rotation_degrees.z = 90
    sprite.flip_v = false
    sprite.flip_h = false
func faceDown(sprite):
    sprite.facing = global.DirDown
    sprite.rotation_degrees.z = -90
    sprite.flip_v = false
    sprite.flip_h = false
func faceLeft(sprite):
    sprite.facing = global.DirLeft
    sprite.rotation_degrees.z = 0
    sprite.flip_v = false
    sprite.flip_h = true
func faceRight(sprite):
    sprite.facing = global.DirRight
    sprite.rotation_degrees.z = 0
    sprite.flip_v = false
    sprite.flip_h = false

func setSpriteAnimationSpeed(frameDelay):
    headSprite.frame_delay = frameDelay

func startChargeUp():
    is_charge_charged = false
    is_charging_up_charge = true
    myParent.chargeUpSound.pitch_scale = rand_range(0.7, 0.9)
    myParent.chargeUpSound.play()
    setSpriteAnimationSpeed(global.VERY_FAST_FRAME_DELAY)
func chargeUp():
    is_charge_charged = true
    if len(lastPressedDirQueue) > 0:
        if len(myParent.myBodyParts) > 1:
            var newFace = lastPressedDirQueue[0]
            var oldFace = headSprite.facing
            if newFace.x < 0: faceLeft(headSprite)
            elif newFace.x > 0: faceRight(headSprite)
            elif newFace.y > 0: faceUp(headSprite)
            elif newFace.y < 0: faceDown(headSprite)
            if oldFace != newFace:
                # i figured this out just by drawing it... idk man don't make sense to me.
                if oldFace.y < 0 or (oldFace.x != 0 and oldFace.x == newFace.y):
                    headSprite.updateBaseFrame(0, 5)
                else:
                    headSprite.updateBaseFrame(2, 5)
                headSprite.facing = oldFace
            else:
                headSprite.updateBaseFrame(2, 0)
        else:
            var moveDir = lastPressedDirQueue[0]
            if moveDir.x < 0: faceLeft(headSprite)
            elif moveDir.x > 0: faceRight(headSprite)
            elif moveDir.y > 0: faceUp(headSprite)
            elif moveDir.y < 0: faceDown(headSprite)
    # if is_charge_charged:
    #     return
    # elif not chargeUpSound.is_playing(): # TODO(jaketrower): Does this work when muted?
    #     is_charge_charged = true
        # chargeReadySound.play()
func tryChargeAhead():
    if is_charge_charged:
        is_charging_up_charge = false
        myParent.chargeStartSound.pitch_scale = rand_range(1.2, 1.6)
        myParent.chargeStartSound.play()
        myParent.is_charging = true
        can_stop_the_charge = false # need to repress "ui_cancel" in order to halt,
    else:
        myParent.chargeUpSound.stop()
        setSpriteAnimationSpeed(global.IDLE_FRAME_DELAY)
    is_charge_charged = false
    charge_count = 0

var can_stop_the_charge = false
var charge_stop_counter = 0
var charge_stop_count_max = 4
func chargeForwardStep():
    charge_count += 1
    if Input.is_action_pressed("ui_cancel") and can_stop_the_charge:
        charge_stop_counter += 1
    else:
        charge_stop_counter = 0
        
    if charge_count >= charge_count_max or charge_stop_counter >= charge_stop_count_max:
        charge_count = 0
        setSpriteAnimationSpeed(global.IDLE_FRAME_DELAY)
        myParent.is_charging = false
        lastPressedDirQueue = []
        if charge_stop_counter >= charge_stop_count_max:
            pass
        else:
            myParent.chargeSlowdown.pitch_scale = rand_range(0.6, 0.8)
            myParent.chargeSlowdown.play()
