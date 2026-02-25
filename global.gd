extends Spatial

enum GameState {
  MAIN_MENU,
  PAUSE_MENU,
  NORMAL_GAMEPLAY,
  GAME_OVER,
  RESTART_EGG_HATCHING_ANIMATION,
}
var gameState = GameState.NORMAL_GAMEPLAY
var DirUp = Vector2(0, 1)
var DirLeft = Vector2(-1, 0)
var DirDown = Vector2(0, -1)
var DirRight = Vector2(1, 0)

func isOppositeDirOf(dirA, dirB):
  if dirA == DirUp: return dirB == DirDown
  if dirA == DirDown: return dirB == DirUp
  if dirA == DirLeft: return dirB == DirRight
  if dirA == DirRight: return dirB == DirLeft
  return false

var IDLE_FRAME_DELAY = 0.4
var FAST_FRAME_DELAY = 0.2
var VERY_FAST_FRAME_DELAY = 0.1

var memory = {}

func _ready():
  memory["can_charge_attack"] = false
  memory["how_many_oranges_ate"] = 0
  memory["how_many_rockfruit_ate"] = 0
  memory["move_counter"] = 0

var base_palette = preload("res://palettes/base_palette.png")
var orange_palette = preload("res://palettes/orange_palette.png")
var white_palette = preload("res://palettes/white_palette.png")
var crab_palette = preload("res://palettes/crab_palette.png")
var egg_palette = preload("res://palettes/egg_palette.png")
var pokemon_palette = preload("res://palettes/pokemon-sgb-1x.png")
var rock_palette = preload("res://palettes/rock_palette.png")
func getRandomPalette():
  var palettes = [
    base_palette,
    orange_palette,
    white_palette,
    crab_palette,
    egg_palette,
    pokemon_palette,
    rock_palette
  ]
  return palettes[randi() % len(palettes)]