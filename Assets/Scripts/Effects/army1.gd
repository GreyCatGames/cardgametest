extends Node

const Y_POSITION = 667

#If this is in the bottom row evolve
func trigger_effect(battle_manager_ref, card_with_effect):
	await battle_manager_ref.wait(0.6)
	if card_with_effect.card_in_slot:
		if card_with_effect.position.y == Y_POSITION:
			print("effect triggered")
			var new_img = str("res://Assets/Art/Army2Card.png")
			card_with_effect.get_node("CardImg").texture = load(new_img)
			card_with_effect.attack = 3
			card_with_effect.health = 3
			card_with_effect.get_node("Attack").text = str(card_with_effect.attack)
			card_with_effect.get_node("Health").text = str(card_with_effect.health)
			card_with_effect.get_node("EffectTxt").text = "'We are stronger together'"
