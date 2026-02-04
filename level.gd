extends Spatial

onready var player = get_node("player")
onready var orange = get_node("orange")
onready var orangeFish = get_node("orangeFish")
onready var bubbleSound = get_node("BubbleSound")
onready var chompSound = get_node("ChompSound")
onready var heySound = get_node("HeySound")
onready var screamSound = get_node("ScreamSound")
onready var textBox = get_node("CanvasLayer/TextBox")
onready var textBoxText = get_node("CanvasLayer/TextBox/Text")
onready var camera = get_node("Camera")
var bubbleRes = preload("res://bubble.tscn")
var random_bubble_timer = 0
var random_bubble_time_limit = 10

var HOW_MANY_ORANGES = 3

enum GameState {
    ORANGE_EATING,
    ORANGE_FISH_COMPLAINING,
    BEGIN_ADVENTURE,
}
var gameState = GameState.ORANGE_EATING

var how_many_oranges_ate = 0
var adventure_size = 10
var should_snap_camera = false

func _ready():
    set_process(true)

func _process(delta):
    var has_player_moved = false
    if Input.is_action_just_pressed("ui_up"):
        player.moveUp()
        has_player_moved = true
    elif Input.is_action_just_pressed("ui_down"):
        player.moveDown()
        has_player_moved = true
    if Input.is_action_just_pressed("ui_left"):
        player.moveLeft()
        has_player_moved = true
    elif Input.is_action_just_pressed("ui_right"):
        player.moveRight()
        has_player_moved = true
    else:
        random_bubble_timer += (delta*22)
        if random_bubble_timer >= random_bubble_time_limit:
            random_bubble_timer = 0
            random_bubble_time_limit = rand_range(10, 40)
            spawnBubble(player.headSprite.global_transform.origin, 0)
        
    if gameState == GameState.ORANGE_EATING:
        if has_player_moved:
            random_bubble_timer = 0
            bubbleSound.pitch_scale = rand_range(0.8, 1.2)
            bubbleSound.play()
            for i in range(2):
                spawnBubble(player.headSprite.global_transform.origin, i)
            if isPlayerEating(orange):
                how_many_oranges_ate += 1
                player.eatAnOrange()
                chompSound.pitch_scale = rand_range(0.8, 1.2)
                chompSound.play()
                for i in range(3):
                    spawnBubble(player.headSprite.global_transform.origin, i + 1)
                
                if how_many_oranges_ate >= 2:
                    textBox.visible = false

                if how_many_oranges_ate >= HOW_MANY_ORANGES:
                    orange.visible = false
                    orangeFish.visible = true
                    heySound.play()
                    gameState = GameState.ORANGE_FISH_COMPLAINING
                    while doesIntersectWithAnyBodyPart(orangeFish):
                        orangeFish.global_transform.origin.x = randi() % 7 - 3
                        orangeFish.global_transform.origin.y = randi() % 7 - 3
                    textBox.visible = true
                    textBoxText.bbcode_text = "[center]hey man, you're eating all my [wave]freaking[/wave] [color=#ff8426]oranges[/color]!!![/center]"
                else:
                    while doesIntersectWithAnyBodyPart(orange):
                        orange.global_transform.origin.x = randi() % 7 - 3
                        orange.global_transform.origin.y = randi() % 7 - 3
    elif gameState == GameState.ORANGE_FISH_COMPLAINING:
        if has_player_moved:
            random_bubble_timer = 0
            bubbleSound.pitch_scale = rand_range(0.8, 1.2)
            bubbleSound.play()
            for i in range(2):
                spawnBubble(player.headSprite.global_transform.origin, i)
            if isPlayerEating(orangeFish):
                screamSound.play()
                player.eatAnOrange()
                chompSound.pitch_scale = rand_range(0.8, 1.2)
                chompSound.play()
                for i in range(3):
                    spawnBubble(player.headSprite.global_transform.origin, i + 1)

                orangeFish.visible = false
                gameState = GameState.BEGIN_ADVENTURE
                textBox.visible = true
                textBoxText.bbcode_text = "[center][shake][color=#ff8426]AAAAAUUUUUUGGGHHH!!!!!![/color][/shake][/center]"
    elif gameState == GameState.BEGIN_ADVENTURE:
        camera.size = camera.size + (adventure_size - camera.size) * (delta*5)
        if stepify(camera.size, 0.1) == stepify(adventure_size, 0.1):
            camera.size = adventure_size
        
        if should_snap_camera:
            camera.global_transform.origin = player.cameraTarget.global_transform.origin
        elif camera.size == adventure_size:
            camera.global_transform.origin = camera.global_transform.origin + (player.cameraTarget.global_transform.origin - camera.global_transform.origin) * (delta*5)
            if stepify(camera.global_transform.origin.x, 0.1) == stepify(player.cameraTarget.global_transform.origin.x, 0.1) and stepify(camera.global_transform.origin.y, 0.1) == stepify(player.cameraTarget.global_transform.origin.y, 0.1):
                # should_snap_camera = true
                pass


        if has_player_moved:
            random_bubble_timer = 0
            bubbleSound.pitch_scale = rand_range(0.8, 1.2)
            bubbleSound.play()
            for i in range(2):
                spawnBubble(player.headSprite.global_transform.origin, i)
        
                

func isPlayerEating(sprite):
    return sprite.global_transform.origin.x == player.headSprite.global_transform.origin.x and sprite.global_transform.origin.y == player.headSprite.global_transform.origin.y
    
func doesIntersectWithAnyBodyPart(sprite):
    var spritePos = sprite.global_transform.origin
    for i in range(len(player.myBodyParts)):
        var bodyPart = player.myBodyParts[i]
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

func spawnBubble(pos, time_to_yield = 0):
    if time_to_yield > 0:
        yield(get_tree().create_timer(0.1*time_to_yield), "timeout")
    var newBubble = bubbleRes.instance()
    self.add_child(newBubble)
    newBubble.global_transform.origin = pos
    newBubble.global_transform.origin.y += rand_range(0.3, 0.8)
    newBubble.global_transform.origin.x += rand_range(-0.5, 0.5)
    if randi() % 2 <= 1:
        newBubble.which_x = -1
