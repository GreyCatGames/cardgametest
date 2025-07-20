extends Node

#Deal 1 to all cards
const MAGIC_DAMAGE = 1

var card_to_destroy = []
func trigger_effect(battle_manager_ref, card_with_effect):
	battle_manager_ref.end_turn_button(false)
	await battle_manager_ref.wait(1.0)
	effect_opponent(battle_manager_ref)
	effect_player(battle_manager_ref)
	await battle_manager_ref.wait(1.0)
	battle_manager_ref.destroy_card(card_with_effect, "Player")
	await battle_manager_ref.wait(1.0)
	battle_manager_ref.end_turn_button(true)
	
func effect_opponent(battle_manager_ref):
	for card in battle_manager_ref.opponent_cards_in_play:
		card.health -= MAGIC_DAMAGE
		card.get_node("Health").text = str(card.health)
		if card.health < 1:
			card_to_destroy.append(card)
	if card_to_destroy.size() > 0:
		for card in card_to_destroy:
			battle_manager_ref.destroy_card(card, "Opponent")

func effect_player(battle_manager_ref):
	for card2 in battle_manager_ref.player_cards_in_play:
		card2.health -= MAGIC_DAMAGE
		card2.get_node("Health").text = str(card2.health)
		if card2.health < 1:
			card_to_destroy.append(card2)
	if card_to_destroy.size() > 0:
		for card2 in card_to_destroy:
			battle_manager_ref.destroy_card(card2, "Player")
