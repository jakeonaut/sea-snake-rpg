extends "res://eventScripts/_event.gd"

var initial_trick_counter = 0
func startTrying():
    initial_trick_counter = level.trick_counter

var has_complimented_you = false
var is_in_pain = false
func keepTrying():
    if not has_complimented_you and level.trick_counter > initial_trick_counter:
        has_complimented_you = true
        myParent.playTalkSound()
        level.textBoxText.bbcode_text = "[wave]ah, very cool dearie.\nhm.. let me try![/wave]"

        yield(get_tree().create_timer(0.5), "timeout")
        myParent.mySprite.frame_delay = global.FAST_FRAME_DELAY

        yield(get_tree().create_timer(0.5), "timeout")
        level.bubbleReverseSound.pitch_scale = rand_range(0.4, 0.8)
        level.bubbleReverseSound.play()
        level._spawnBubble(myParent.global_transform.origin)
        level.faceUp(myParent.mySprite)
        myParent.mySprite.frame_delay = global.IDLE_FRAME_DELAY

        yield(get_tree().create_timer(0.5), "timeout")
        myParent.mySprite.frame_delay = global.FAST_FRAME_DELAY

        yield(get_tree().create_timer(0.5), "timeout")
        level.bubbleReverseSound.pitch_scale = rand_range(0.4, 0.8)
        level.bubbleReverseSound.play()
        level._spawnBubble(myParent.global_transform.origin)
        level.faceLeft(myParent.mySprite)
        myParent.mySprite.flip_v = true
        myParent.mySprite.frame_delay = global.IDLE_FRAME_DELAY

        yield(get_tree().create_timer(0.5), "timeout")
        myParent.mySprite.frame_delay = global.FAST_FRAME_DELAY

        yield(get_tree().create_timer(0.5), "timeout")
        level.bubbleReverseSound.pitch_scale = rand_range(0.4, 0.8)
        level.bubbleReverseSound.play()
        level._spawnBubble(myParent.global_transform.origin)
        myParent.mySprite.frame_delay = global.IDLE_FRAME_DELAY
        myParent.playTalkSound(0.6, 0.8)
        initial_trick_counter = level.trick_counter
        is_in_pain = true
        myParent.bbcode_text = "[shake]oouk.. my back..[/shake]"
        level.textBoxText.bbcode_text = myParent.bbcode_text
    elif has_complimented_you and level.trick_counter > initial_trick_counter and is_in_pain:
        var nonoText = "no, no... i've had my fill of fun"
        if level.textBoxText.bbcode_text != nonoText:
            myParent.playTalkSound(0.6, 0.8)
        level.textBoxText.bbcode_text = nonoText
        initial_trick_counter = level.trick_counter