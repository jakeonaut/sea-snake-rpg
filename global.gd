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
