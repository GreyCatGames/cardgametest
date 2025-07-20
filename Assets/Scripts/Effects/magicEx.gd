extends Node

const MAGIC_DAMAGE = 1

#Deal 1 to all opponent cards
func trigger_effect(battle_manager_ref, card_with_effect):
	battle_manager_ref.end_turn_button(false)
	await battle_manager_ref.wait(1.0)
	var card_to_destroy = []
	
	for card in battle_manager_ref.opponent_cards_in_play:
		card.health -= MAGIC_DAMAGE
		card.get_node("Health").text = str(card.health)
		if card.health < 1:
			card_to_destroy.append(card)
	await battle_manager_ref.wait(1.0)
	if card_to_destroy.size() > 0:
		for card in card_to_destroy:
			battle_manager_ref.destroy_card(card, "Opponent")
	battle_manager_ref.destroy_card(card_with_effect, "Player")
	await battle_manager_ref.wait(1.0)
	battle_manager_ref.end_turn_button(true)
