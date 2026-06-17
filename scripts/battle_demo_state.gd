class_name BattleDemoState
extends RefCounted

signal hand_changed
signal state_changed

var player_hp := 40
var player_block := 0
var enemy_hp := 30
var enemy_block := 0
var energy := 3
var turn := 1
var phase := "player"

var deck := [
  {"id":"slash","name":"打击","type":"attack","cost":1,"damage":6},
  {"id":"slash","name":"打击","type":"attack","cost":1,"damage":6},
  {"id":"slash","name":"打击","type":"attack","cost":1,"damage":6},
  {"id":"slash","name":"打击","type":"attack","cost":1,"damage":6},
  {"id":"guard","name":"防御","type":"skill","cost":1,"block":5},
  {"id":"guard","name":"防御","type":"skill","cost":1,"block":5},
  {"id":"bash","name":"重击","type":"attack","cost":2,"damage":12},
]

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []


func start_battle() -> void:
  player_hp = 40
  player_block = 0
  enemy_hp = 30
  enemy_block = 0
  turn = 1
  draw_pile.clear()
  hand.clear()
  discard_pile.clear()
  for card in deck:
    draw_pile.append(card.duplicate())
  draw_pile.shuffle()
  phase = "player"
  begin_player_turn()


func begin_player_turn() -> void:
  energy = 3
  player_block = 0
  draw_cards(4)
  emit_change()


func draw_cards(count: int) -> void:
  for _i in range(count):
    if hand.size() >= 8:
      break
    if draw_pile.is_empty():
      if discard_pile.is_empty():
        break
      draw_pile = discard_pile.duplicate()
      discard_pile.clear()
      draw_pile.shuffle()
    hand.append(draw_pile.pop_back())
  hand_changed.emit()
  emit_change()


func can_play(index: int) -> bool:
  if phase != "player":
    return false
  if index < 0 or index >= hand.size():
    return false
  var card: Dictionary = hand[index]
  return energy >= int(card.get("cost", 0))


func play_card(index: int) -> void:
  if not can_play(index):
    return
  var card: Dictionary = hand[index]
  energy -= int(card.get("cost", 0))

  if card.get("type") == "attack":
    var damage: int = int(card.get("damage", 0))
    var actual := maxi(damage - enemy_block, 0)
    enemy_block = maxi(enemy_block - damage, 0)
    enemy_hp -= actual
  elif card.get("type") == "skill":
    player_block += int(card.get("block", 0))

  discard_pile.append(card)
  hand.remove_at(index)
  hand_changed.emit()
  emit_change()


func end_player_turn() -> void:
  if phase != "player":
    return
  phase = "enemy"
  enemy_block = 0
  enemy_take_action()
  turn += 1
  phase = "player"
  begin_player_turn()


func enemy_take_action() -> void:
  var intent_damage := 7
  var actual := maxi(intent_damage - player_block, 0)
  player_block = maxi(player_block - intent_damage, 0)
  player_hp -= actual
  emit_change()


func emit_change() -> void:
  state_changed.emit()
