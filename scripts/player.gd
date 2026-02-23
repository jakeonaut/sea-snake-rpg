extends Spatial

onready var level = get_tree().get_root().get_node("level")
var coconutProjectileRes = preload("res://sceneObjects/coconutProjectile.tscn")
var playerSheetRes = preload("res://images/player_sheet.png")
var playerCoconutSheetRes = preload("res://images/player_sheet_coconut.png")
var text3dRes = preload("res://sceneObjects/3DText.tscn")

onready var headSprite = get_node("headSprite")
onready var eggSprite = get_node("eggSprite")
onready var parasite = get_node("parasite")
onready var playerMover = get_node("cameraTarget") # shhhh, they're the same
onready var cameraTarget = get_node("cameraTarget") # shhhh, they're the same
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
onready var skidStopSound = get_node("Sounds/SkidStopSound")
onready var hatchedSound = get_node("Sounds/HatchedSound")

onready var csgCombinerPosition = get_node("CSGCombiner")
onready var coverOfDarkness = get_node("CSGCombiner/CSGMesh")
onready var playerLight = get_node("CSGCombiner/PlayerLight")

var is_stunned = false
var is_dead = false
var is_charging = false
var should_grow = false
var facing = global.DirRight
var myBodyParts = []

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
    level.spawnBubbles(headSprite.global_transform.origin, 5)

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
    level.spawnBubbles(headSprite.global_transform.origin, 3)

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

func spawnEggBubble():
    playerMover.random_bubble_timer = 0
    level.bubbleSound.pitch_scale = rand_range(0.2, 0.4)
    level.bubbleSound.play()
    var how_many = 1
    for i in range(how_many):
        level._spawnBubble(eggSprite.global_transform.origin + (Vector3(eggSprite.offset.x, eggSprite.offset.y, 0) * eggSprite.pixel_size), i)

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
    playerMover.prevBodyPartsStatesStack = []
    headSprite.updateBaseFrame(0, 0)
    headSprite.max_frames = 2
    facing = global.DirRight
    playerMover.faceRight(headSprite)
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
