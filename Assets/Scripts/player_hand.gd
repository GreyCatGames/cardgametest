extends Node2D


const CARD_WIDTH = 205
const HAND_Y_POS = 927
const DEFAULT_CARD_SPEED = 0.1

var player_hand = []
var center_screen
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen = get_viewport().size / 2


func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_pos(speed)
	else:
		animate_card_to_position(card, card.start_pos, DEFAULT_CARD_SPEED)

func update_hand_pos(speed):
	for i in range(player_hand.size()):
		#get card pos based on index
		var new_pos = Vector2(calculate_card_pos(i), HAND_Y_POS)
		var card = player_hand[i]
		card.start_pos = new_pos
		animate_card_to_position(card, new_pos, speed)

func calculate_card_pos(index):
	var total_width = (player_hand.size() - 1) * CARD_WIDTH
	var x_offset = center_screen.x + index * CARD_WIDTH - total_width / 2
	return x_offset

func animate_card_to_position(card, new_pos, speed):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, speed)

func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_pos(DEFAULT_CARD_SPEED)
