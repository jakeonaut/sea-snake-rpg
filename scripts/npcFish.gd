extends Spatial

onready var level = get_tree().get_root().get_node("level")

export(String, MULTILINE) var bbcode_text = ""
export(String, MULTILINE) var stunned_text = ""
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

func getMiniStunned():
    aniPlayer.stop()
    aniPlayer.clear_queue()
    aniPlayer.play("stunned")
    if stunned_text != "":
        level.textBoxText.bbcode_text = stunned_text
        playTalkSound()