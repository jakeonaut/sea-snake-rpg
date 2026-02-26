extends Spatial

onready var level = get_tree().get_root().get_node("Game/Viewport/level")

export(String, MULTILINE) var bbcode_text = ""
export(String, MULTILINE) var stunned_text = ""
export(String, MULTILINE) var coconut_text = ""
export var should_collide_with = true

onready var talkSound = get_node("talkSound")
onready var killSound = get_node("killSound") if has_node("killSound") else talkSound
onready var mySprite = get_node("fishSprite")
onready var aniPlayer = get_node("AnimationPlayer")

onready var event = get_node("event") if has_node("event") else null

var is_talking = false

func _ready():
    pass

func _process(_delta):
    pass

func playTalkSound(minPitch = 0.8, maxPitch = 1.2):
    talkSound.pitch_scale = rand_range(minPitch, maxPitch)
    talkSound.play()

func startTalking():
    playTalkSound()
    is_talking = true
    if event != null:
        event.startTrying()
    return bbcode_text

func keepTalking():
    if event != null:
        event.keepTrying()

func stopTalking(did_someone_else_start_talking = false):
    is_talking = false
    if event != null:
        event.stopTrying(did_someone_else_start_talking)

func collideWith(was_player_charging):
    var stunnedTextToUse = ""
    if was_player_charging:
        self.getMiniStunned()
        stunnedTextToUse = stunned_text
    if event != null:
        var collisionResult = event.collideWith(was_player_charging)
        if collisionResult[0] != "":
            stunnedTextToUse = collisionResult[0]
    if stunnedTextToUse != "":
        level.textBox.visible = true
        level.textBoxText.bbcode_text = stunnedTextToUse
        playTalkSound()
        level.setNewLastSpeaker(self)
        is_talking = true


func getMiniStunned():
    aniPlayer.stop()
    aniPlayer.clear_queue()
    aniPlayer.play("stunned")

func getHitWithCoconut(coconutDir):
    var was_coconut_absorbed = false
    var coconutTextToUse = coconut_text if coconut_text != "" else stunned_text if stunned_text != "" else ""
    if event != null:
        var coconutEventResult = event.getHitWithCoconut(coconutDir)
        was_coconut_absorbed = coconutEventResult[0]
        var unique_coconut_event_text = coconutEventResult[1]
        if unique_coconut_event_text != "":
            coconutTextToUse = unique_coconut_event_text
    aniPlayer.stop()
    aniPlayer.clear_queue()
    aniPlayer.play("stunned")
    aniPlayer.queue("stunned")
    if coconutTextToUse != "":
        level.textBoxText.bbcode_text = coconutTextToUse
        level.textBox.visible = true
        playTalkSound()
        level.setNewLastSpeaker(self)
        is_talking = true
    return was_coconut_absorbed
