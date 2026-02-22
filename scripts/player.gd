extends Spatial

onready var level = get_tree().get_root().get_node("level")
var coconutProjectileRes = preload("res://sceneObjects/coconutProjectile.tscn")
var playerSheetRes = preload("res://images/player_sheet.png")
var playerCoconutSheetRes = preload("res://images/player_sheet_coconut.png")
var text3dRes = preload("res://sceneObjects/3DText.tscn")
onready var headSprite = get_node("headSprite")
onready var eggSprite = get_node("eggSprite")
onready var parasite = get_node("parasite")
onready var cameraTarget = get_node("cameraTarget")
onready var aniPlayer = get_node("AnimationPlayer")
onready var pfftSound = get_node("Sounds/PfftSound")
onready var growSound = get_node("Sounds/GrowSound")
onready var chompSound = get_node("Sounds/ChompSound")
onready var coolSound = get_node("Sounds/CoolSound")
onready var applauseSound = get_node("Sounds/ApplauseSound")
onready var spitSound = get_node("Sounds/SpitSound")
onready var owSound = get_node("Sounds/OwSound")
onready var bumpSound = get_node("Sounds/BumpSound")
onready var chargeUpSound = get_node("Sounds/ChargeUpSound")
onready var chargeStartSound = get_node("Sounds/ChargeStartSound")
onready var chargeReadySound = get_node("Sounds/ChargeReadySound")
onready var chargeSlowdown = get_node("Sounds/ChargeSlowdown")
onready var hatchedSound = get_node("Sounds/HatchedSound")

onready var csgCombinerPosition = get_node("CSGCombiner")
onready var coverOfDarkness = get_node("CSGCombiner/CSGMesh")
onready var playerLight = get_node("CSGCombiner/PlayerLight")

var IDLE_FRAME_DELAY = 0.4
var FAST_FRAME_DELAY = 0.2
var VERY_FAST_FRAME_DELAY = 0.1

var is_stunned = false
var is_dead = false
var MAX_UNDO_SIZE = 7
var charge_count = 0
var charge_count_max = 14
var is_charge_charged = false
var is_charging_up_charge = false
var is_charging = false
var should_grow = false
var facing = global.DirRight
var should_advance_animation_frame = false
var myBodyParts = []
var prevBodyPartsStatesStack = []

var parasiteTexts = ["pest control!", "deloused!", "para-sea yoU later!"]
var coolTexts = ["awesome!", "radical!", "groovey!", "cool!", "xD!", "nice!", "okay!", "alright!", "neat!"]
var smallComboCoolTexts = ["combo?!?", "you go girl!!!", "now that's something!!!", "now we're getting somewhere!!!", "wtf?!?", "hekck yeah!!!!"]
var bigComboCoolTexts = ["I CAN'T BELIEVE IT!!!!!", "YOU ARE A FISH MASTER!!!!!", "BRO YOU GOTTA TEACH ME HOW TO DO THAT!!!!", "CRAB MODE ACTIVATED!!!!", "WHAT IS THIS POWER?!?!?"]

func _ready():
    myBodyParts = [headSprite]
    cameraTarget.global_transform.origin = headSprite.global_transform.origin
    cameraTarget.global_transform.origin.z = 6

func eatAnOrange():
    level.how_many_oranges_ate += 1
    should_grow = true
    chompSound.pitch_scale = rand_range(0.8, 1.2)
    chompSound.play()

func eatALemon():
    level.how_many_lemons_ate += 1
    playerLight.scale += Vector3(0.5, 0.5, 0.5)

func eatAWhaleFallFruit():
    aniPlayer.stop()
    aniPlayer.play("ateWhaleFall")
    level.has_eaten_whale_fall += 1

func eatACoconut():
    var could_i_eat_the_coconut = false
    for i in range(len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        if bodyPart.texture != playerCoconutSheetRes:
            bodyPart.texture = playerCoconutSheetRes
            could_i_eat_the_coconut = true
            break
    if not could_i_eat_the_coconut:
        owSound.pitch_scale = rand_range(0.4, 0.6)
        owSound.play()
        level.deathOverlay.visible = false
        level.deathOverlay.color.a = 0.3
        level.prevTextBoxVisible = level.textBox.visible
        level.prevTextBoxTopVisible = level.textBoxTop.visible
        owIDied()
        level.died_to_coconut_overconsumption = true
        level.causeOfDeathStr = "ate too many coconuts"
    else:
        level.how_many_coconuts_ate += 1
    return could_i_eat_the_coconut

func startChargeUp():
    is_charge_charged = false
    is_charging_up_charge = true
    chargeUpSound.pitch_scale = rand_range(0.7, 0.9)
    chargeUpSound.play()
    setSpriteAnimationSpeed(VERY_FAST_FRAME_DELAY)
func chargeUp():
    is_charge_charged = true
    if len(level.lastPressedDirQueue) > 0:
        if len(myBodyParts) > 1:
            var newFace = level.lastPressedDirQueue[0]
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
            var moveDir = level.lastPressedDirQueue[0]
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
        chargeStartSound.pitch_scale = rand_range(1.2, 1.6)
        chargeStartSound.play()
        is_charging = true
    else:
        chargeUpSound.stop()
        setSpriteAnimationSpeed(IDLE_FRAME_DELAY)
    is_charge_charged = false
    charge_count = 0

func chargeForwardStep():
    charge_count += 1
    if charge_count >= charge_count_max:
        charge_count = 0
        setSpriteAnimationSpeed(IDLE_FRAME_DELAY)
        is_charging = false
        level.lastPressedDirQueue = []
        chargeSlowdown.pitch_scale = rand_range(0.6, 0.8)
        chargeSlowdown.play()

func spitCoconutProjectile():
    var has_coconut_in_mouth = false
    for i in range(len(myBodyParts), 0, -1):
        var bodyPart = myBodyParts[i - 1]
        if bodyPart.texture == playerCoconutSheetRes:
            bodyPart.texture = playerSheetRes
            has_coconut_in_mouth = true
            break
    if not has_coconut_in_mouth:
        level.playErrorSound()
        return
    var newCoconutProjectile = coconutProjectileRes.instance()
    level.add_child(newCoconutProjectile)
    newCoconutProjectile.global_transform.origin = headSprite.global_transform.origin
    newCoconutProjectile.facing = facing
    var coconutAniPlayer = newCoconutProjectile.get_node("AnimationPlayer")
    if facing == global.DirRight:
        newCoconutProjectile.global_transform.origin += Vector3(1, 0, 0)
        coconutAniPlayer.stop()
        coconutAniPlayer.clear_queue()
        coconutAniPlayer.play("tumbleRight")
    elif facing == global.DirLeft:
        newCoconutProjectile.global_transform.origin += Vector3(-1, 0, 0)
        coconutAniPlayer.stop()
        coconutAniPlayer.clear_queue()
        coconutAniPlayer.play("tumbleLeft")
    elif facing == global.DirUp:
        newCoconutProjectile.global_transform.origin += Vector3(0, 1, 0)
        coconutAniPlayer.stop()
        coconutAniPlayer.clear_queue()
        coconutAniPlayer.play("tumbleRight")
    elif facing == global.DirDown:
        newCoconutProjectile.global_transform.origin += Vector3(0, -1, 0)
        coconutAniPlayer.stop()
        coconutAniPlayer.clear_queue()
        coconutAniPlayer.play("tumbleRight")
    level.spitSound.pitch_scale = rand_range(0.8, 1.2)
    level.spitSound.play()
    yield(get_tree().create_timer(0.1), "timeout")
    level.swooshSound.play()

func moveUp(): return genericMove(global.DirUp)
func moveDown(): return genericMove(global.DirDown)
func moveLeft(): return genericMove(global.DirLeft)
func moveRight(): return genericMove(global.DirRight)

func genericMove(moveDir):
    if myBodyParts.size() > 1 and moveDir.is_equal_approx(-facing):
        maybeAdvanceBodyPartAnimationFrames()
        should_advance_animation_frame = not should_advance_animation_frame
        level.playErrorSound()
        return false
    if should_grow: grow(moveDir)
    saveBodyPartPositions()
    facing = moveDir
    headSprite.global_transform.origin.x += moveDir.x
    headSprite.global_transform.origin.y += moveDir.y
    if myBodyParts.size() > 1:
        headSprite.updateBaseFrame(2, 0)
    else:
        headSprite.updateBaseFrame(0, 0)
    moveMyBodyParts(moveDir)
    if moveDir.x < 0: faceLeft(headSprite)
    elif moveDir.x > 0: faceRight(headSprite)
    elif moveDir.y > 0: faceUp(headSprite)
    elif moveDir.y < 0: faceDown(headSprite)
    if not tryToEatParasites(): tryToBeCool()
    should_advance_animation_frame = not should_advance_animation_frame
    return postProcessMoveAttempt(moveDir)

func postProcessMoveAttempt(_moveDir):
    if hasCollidedWithAnything():
        if is_charging:
            setSpriteAnimationSpeed(IDLE_FRAME_DELAY)
            is_charging = false
            level.lastPressedDirQueue = []
        return false
    if len(prevBodyPartsStatesStack) > MAX_UNDO_SIZE:
        prevBodyPartsStatesStack.pop_front()
    return true

func hasCollidedWithAnything():
    # if level.isPlayerOutOfBounds(self):
    #     self.restoreBodyPartPositions()
    #     return true
    var rocks = get_tree().get_nodes_in_group("rock_group")
    for i in range(len(rocks)):
        var rock = rocks[i]
        if isHeadOverlapping(rock):
            self.restoreBodyPartPositions()
            if is_charging:
                bumpSound.pitch_scale = rand_range(0.7, 0.9)
                bumpSound.play()
                rock.rockSmash()
                owIGotStunned()
                # TODO(jaketrower): do a little screen shake mini if not disabled (steal from gdc)
            else:
                level.playErrorSound()
            return true
    var crabs = get_tree().get_nodes_in_group("crab_group")
    for i in range(len(crabs)):
        var crab = crabs[i]
        if isHeadOverlapping(crab):
            restoreBodyPartPositions()
            if is_charging:
                bumpSound.pitch_scale = rand_range(0.7, 0.9)
                bumpSound.play()
                owIGotStunned()
            owIDied()
            return true
    return false

func isHeadOverlapping(sprite):
    if not sprite.visible:
        return false
    return sprite.global_transform.origin.x == headSprite.global_transform.origin.x and sprite.global_transform.origin.y == headSprite.global_transform.origin.y

func owIDied():
    owSound.pitch_scale = rand_range(0.4, 0.6)
    owSound.play()
    global.gameState = global.GameState.GAME_OVER
    is_dead = true
    death_timer = 0
    headSprite.updateBaseFrameWithStartFrame(headSprite.start_frame)
    if headSprite.frame_coords.y >= 5:
        headSprite.updateBaseFrame(headSprite.frame_coords.x, 6)
    else:
        headSprite.updateBaseFrame(headSprite.frame_coords.x, 4)
    level.death_counter += 1
    level.playerMovedBubbleSpawn(self)

func owIGotStunned():
    is_stunned = true
    aniPlayer.stop()
    aniPlayer.clear_queue()
    aniPlayer.play("stunned")
    headSprite.updateBaseFrameWithStartFrame(headSprite.start_frame)
    if headSprite.frame_coords.y >= 5:
        headSprite.updateBaseFrame(headSprite.frame_coords.x, 6)
    else:
        headSprite.updateBaseFrame(headSprite.frame_coords.x, 4)
    level.playerMovedBubbleSpawn(self)

func unstunned():
    is_stunned = false
    if not is_dead:
        headSprite.updateBaseFrameWithStartFrame(headSprite.start_frame)
        if headSprite.frame_coords.y >= 5:
            headSprite.updateBaseFrame(headSprite.frame_coords.x, 5)
        else:
            headSprite.updateBaseFrame(headSprite.frame_coords.x, 0)


var death_timer = 0
var death_time_limit = 180
func processDeath(delta):
    death_timer += (delta*22)
    if death_timer >= death_time_limit:
        return
    var has_death_animation_finished = headSprite.opacity <= 0
    if not has_death_animation_finished:
        for i in range(len(myBodyParts)):
            var bodyPart = myBodyParts[i]
            bodyPart.global_transform.origin.y += (delta*1)
            bodyPart.max_frames = 1
            bodyPart.opacity -= (delta*0.4)
            if bodyPart.opacity < 0:
                bodyPart.visible = false
                has_death_animation_finished = true
                if i > 0:
                    bodyPart.queue_free()
    if has_death_animation_finished:
        myBodyParts = [headSprite]


func maybeAdvanceBodyPartAnimationFrames():
    for i in range(len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        bodyPart.updateBaseFrameWithStartFrame(bodyPart.start_frame)
        if should_advance_animation_frame:
            bodyPart.animation_counter = bodyPart.frame_delay
            bodyPart.animate(1)
        else:
            bodyPart.animation_counter = 0

func grow(moveDir):
    # TODO(jaketrower): This _x, _y should be set according to the direction that the LAST PREVIOUS BODY PART is moving.
    # so, it will be accurate for the first growth, but not subsequent growths rn
    headSprite.updateBaseFrame(2, 0)
    var newBodySprite = headSprite.duplicate()
    newBodySprite.name = "bodySprite"
    self.add_child(newBodySprite)
    newBodySprite.global_transform.origin = myBodyParts[len(myBodyParts) - 1].global_transform.origin + Vector3(-moveDir.x, -moveDir.y, -0.05)
    newBodySprite.updateBaseFrame(0, 1)
    newBodySprite.frame_delay = IDLE_FRAME_DELAY
    newBodySprite.modulate.r = 1
    newBodySprite.modulate.b = 1
    newBodySprite.scale = Vector3(1, 1, 1)
    newBodySprite.follow_player_frame_delay = true
    myBodyParts.push_back(newBodySprite)
    should_grow = false
    # growSound.pitch_scale = rand_range(0.8, 1.2)
    # growSound.play()
    yield(get_tree().create_timer(0.3), "timeout")
    pfftSound.pitch_scale = rand_range(0.8, 1.2)
    pfftSound.play()
    for i in range(2):
        level.spawnBubble(newBodySprite.global_transform.origin, i)
 
func tryToBeCool():
    var headPos = Vector2(headSprite.global_transform.origin.x, headSprite.global_transform.origin.y)
    var was_i_cool_this_time = false
    for i in range(1, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        var bodyPos = Vector2(bodyPart.global_transform.origin.x, bodyPart.global_transform.origin.y)
        if bodyPart.frame_coords.y == 1 and headPos.is_equal_approx(bodyPos) and (
            (headSprite.isHorizontal() and bodyPart.isVertical())
            or (headSprite.isVertical() and bodyPart.isHorizontal())
        ):
            was_i_cool_this_time = true
            break
    if was_i_cool_this_time:
        var newAwesomeText = text3dRes.instance()
        level.add_child(newAwesomeText)
        var textArrayToUse = coolTexts
        if level.combo_counter > 0 and level.combo_counter < 4:
            textArrayToUse = smallComboCoolTexts
        elif level.combo_counter >= 4:
            textArrayToUse = bigComboCoolTexts

        var textToUse = textArrayToUse[randi() % len(textArrayToUse)]
        if is_charging:
            level.trick_counter += 3
            level.combo_counter += 3
        else:
            level.trick_counter += 1
            level.combo_counter += 1
        if level.combo_counter > 1:
            textToUse = "+" + str(level.combo_counter) + " " + textToUse
        var got_a_new_highscore = false
        if level.combo_counter > level.max_combo:
            level.max_combo = level.combo_counter
            if level.combo_counter > 1:
                textToUse = textToUse + "\nnew high score!!!"
                got_a_new_highscore = true
        newAwesomeText.get_node("Label3D").text = textToUse
        newAwesomeText.global_transform.origin = headSprite.global_transform.origin + Vector3(0, 0, 5.5)
        if got_a_new_highscore:
            applauseSound.play()
        else:
            coolSound.pitch_scale = rand_range(0.8, 1.2)
            coolSound.play()
    else:
        level.combo_counter -= 1
        if level.combo_counter <= 0:
            level.combo_counter = 0

func moveMyBodyParts(moveDir):
    var _x = moveDir.x
    var x = _x
    var _y = moveDir.y
    var y = _y
    for i in range(1, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        var leadingBodyPart = myBodyParts[i-1]
        var leadingBodyPartPos = leadingBodyPart.global_transform.origin

        var oldBodyPartPos = bodyPart.global_transform.origin
        bodyPart.global_transform.origin.x = leadingBodyPart.global_transform.origin.x - x
        bodyPart.global_transform.origin.y = leadingBodyPart.global_transform.origin.y - y

        x = bodyPart.global_transform.origin.x - oldBodyPartPos.x
        y = bodyPart.global_transform.origin.y - oldBodyPartPos.y

        var trailingBodyPart = myBodyParts[i+1] if i < len(myBodyParts) - 1 else null
        if trailingBodyPart == null:
            updateBodyPartSprite(bodyPart, x, y, _x, _y, leadingBodyPartPos, oldBodyPartPos, 0)
        elif trailingBodyPart != null:
            # need to update rotation between prevBodyPart.pos and currentPos (which will be where nextBodyPart.pos will go)
            # and if it's a straight line (e.g. same X or same Y between the two), need to face/rotate correctly
            updateBodyPartSprite(bodyPart, x, y, _x, _y, leadingBodyPartPos, oldBodyPartPos, 2)

        _x = x
        _y = y
    cameraTarget.global_transform.origin = headSprite.global_transform.origin
    cameraTarget.global_transform.origin.z = 6

func spawnEggBubble():
    level.random_bubble_timer = 0
    level.bubbleSound.pitch_scale = rand_range(0.2, 0.4)
    level.bubbleSound.play()
    var how_many = 1
    for i in range(how_many):
        level.spawnBubble(eggSprite.global_transform.origin + (Vector3(eggSprite.offset.x, eggSprite.offset.y, 0) * eggSprite.pixel_size), i)

func initiateHatchAnimation():
    headSprite.global_transform.origin.x = 0
    headSprite.global_transform.origin.y = 0
    cameraTarget.global_transform.origin = headSprite.global_transform.origin
    cameraTarget.global_transform.origin.z = 6
    eggSprite.global_transform.origin.x = 0
    eggSprite.global_transform.origin.y = 0
    for i in range(1, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        bodyPart.queue_free()
    myBodyParts = [headSprite]
    headSprite.updateBaseFrame(0, 0)
    headSprite.max_frames = 2
    facing = global.DirRight
    faceRight(headSprite)
    is_dead = false
    aniPlayer.stop()
    aniPlayer.clear_queue()
    aniPlayer.play("eggFloatDown")
    aniPlayer.queue("growFromEgg")

func finishHatchAnimation():
    headSprite.updateBaseFrame(0, 0)
    headSprite.max_frames = 2
    hatchedSound.pitch_scale = rand_range(0.6, 0.9)
    hatchedSound.play()
    global.gameState = global.GameState.NORMAL_GAMEPLAY

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
    for i in range(0, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
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
        var bodyPart = myBodyParts[i]
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
    facing = headSprite.facing
    cameraTarget.global_transform.origin = headSprite.global_transform.origin
    cameraTarget.global_transform.origin.z = 6
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

func tryToEatParasites():
    var headPos = Vector2(headSprite.global_transform.origin.x, headSprite.global_transform.origin.y)
    var do_i_have_parasites = false
    var do_i_still_have_parasites_after_consumption = false
    var did_i_eat_a_parasite = false
    for i in range(1, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        var doesThisPartHaveAParasite = bodyPart.has_node("parasite") and bodyPart.get_node("parasite").visible
        do_i_have_parasites = true if doesThisPartHaveAParasite else do_i_have_parasites
        var bodyPos = Vector2(bodyPart.global_transform.origin.x, bodyPart.global_transform.origin.y)
        if doesThisPartHaveAParasite:
            if headPos.is_equal_approx(bodyPos):
                did_i_eat_a_parasite = true
                bodyPart.get_node("parasite").visible = false
            else:
                do_i_still_have_parasites_after_consumption = true
    if did_i_eat_a_parasite:
        var newAwesomeText = text3dRes.instance()
        level.add_child(newAwesomeText)
        newAwesomeText.global_transform.origin = headSprite.global_transform.origin + Vector3(0, 0, 5.5)
        if do_i_still_have_parasites_after_consumption:
            newAwesomeText.get_node("Label3D").text = parasiteTexts[randi() % len(parasiteTexts)]
            level.deadParasiteSound.pitch_scale = rand_range(0.8, 1.2)
            level.deadParasiteSound.play()
        else:
            newAwesomeText.get_node("Label3D").text = "NO MORE PARASITE!!!"
            applauseSound.play()
    # could use player.doIHaveParasites(), but that would repeat the loop needlessly
    # this logic is a little convoluted though
    return do_i_have_parasites 

func doIHaveParasites():
    for i in range(4, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        if bodyPart.has_node("parasite") and bodyPart.get_node("parasite").visible:
            return true
    return false

func infestWithParasites():
    var should_infest_this_part = true
    for i in range(4, len(myBodyParts)):
        var bodyPart = myBodyParts[i]
        if not should_infest_this_part:
            should_infest_this_part = true
            continue
        var newParasite = parasite.duplicate()
        newParasite.visible = true
        bodyPart.add_child(newParasite)
        newParasite.global_transform.origin = bodyPart.global_transform.origin + Vector3(0, 0, 1)
        should_infest_this_part = false
