extends Node

const SMALL_CARD_SCALE = 0.6
const CARD_MOVE_SPEED = 0.2
const START_HEALTH = 5
const BATTLE_OFFSET = 25
const OPP_HISTORY_POS_Y = 200

var battle_timer
var empty_opp_slots = []
var opponent_cards_in_play = []
var opponent_cards_history = []
var player_cards_in_play = []
var player_cards_attacked = []

var player_graveyard_check = []
var opponent_graveyard_check = []

var opp_card_textures: Array[Texture2D] = []
var opp_history_nodes = []

var player_health
var opponent_health
var player_gy_txt
var player_gy_count
var opponent_gy_text
var opponent_gy_count

var is_opponents_turn = false
var is_attacking = false
var is_logbook_open = false
var is_graveyard_open = false
var turn_num = 1

var card_history = load("res://Assets/Scenes/card_played.tscn")
var graveyard_card = load("res://Assets/Scenes/graveyard_card.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = 1.0
	#test test
	empty_opp_slots.append($"../OppSlots/ECardSlot")
	empty_opp_slots.append($"../OppSlots/ECardSlot2")
	empty_opp_slots.append($"../OppSlots/ECardSlot3")
	empty_opp_slots.append($"../OppSlots/ECardSlot4")
	empty_opp_slots.append($"../OppSlots/ECardSlot5")
	
	player_health = START_HEALTH
	opponent_health = START_HEALTH
	$"../TextContainer/PlayerHealth/HealthNum".text = str(player_health)
	$"../TextContainer/OppHealth/HealthNum".text = str(opponent_health)
	player_gy_count = 0
	opponent_gy_count = 0
	player_gy_txt = $"../PlayerGY/Count"
	opponent_gy_text = $"../OppGY/Count"
	player_gy_txt.text = str(player_gy_count)
	opponent_gy_text.text = str(opponent_gy_count)

func _on_end_turn_pressed() -> void:
	$"../CardManager".unselect()
	player_cards_attacked = []
	opponents_turn()
	turn_num += 1
	#generate a new logbook section
	#moving logbook up

func opponents_turn():
	is_opponents_turn = true
	$"../EndTurn".disabled = true
	$"../EndTurn".visible = false
	
	if $"../OppDeck".opponent_deck.size() != 0:
		$"../OppDeck".draw_card()
		#wait a second to make it look like the Opp is thinking
		battle_timer.start()
		await battle_timer.timeout
	#check for free slot to play in
	if empty_opp_slots.size() != 0:
		await play_highest_attack()
	#Attack logic
	#Are there enemy cards in play
	if opponent_cards_in_play.size() != 0:
		var attack_enemy_cards = opponent_cards_in_play.duplicate()
		for card in attack_enemy_cards: #attack with all played cards
			if player_cards_in_play.size() == 0:
				#direct damage
				await direct_attack(card, "Opponent")
			else: #attack cards
				var card_being_attacked = player_cards_in_play.pick_random()
				await attack_cards(card, card_being_attacked, "Opponent")
	
	battle_timer.start()
	await battle_timer.timeout
	end_opponent_turn()

func play_highest_attack():
	var opp_hand = $"../OpponentHand".opponent_hand
	if opp_hand.size() == 0:
		end_opponent_turn()
		return
	var random_opp_slot = empty_opp_slots.pick_random()
	empty_opp_slots.erase(random_opp_slot)
	#play cards - in terms of best card to play based on values/attack
	var current_highest_attack = opp_hand[0]
	for card in opp_hand:
		if card.attack > current_highest_attack.attack:
			current_highest_attack = card
	var tween = get_tree().create_tween()
	tween.tween_property(current_highest_attack, "position", random_opp_slot.position, CARD_MOVE_SPEED)
	var tween2 = get_tree().create_tween()
	tween2.tween_property(current_highest_attack, "scale", Vector2(SMALL_CARD_SCALE, SMALL_CARD_SCALE), CARD_MOVE_SPEED)
	current_highest_attack.get_node("AnimationPlayer").play("card_flip")
	
	$"../OpponentHand".remove_card_from_hand(current_highest_attack)
	current_highest_attack.card_in_slot = random_opp_slot 
	opponent_cards_in_play.append(current_highest_attack)
	
	opp_history(current_highest_attack)
	
	battle_timer.start()
	await battle_timer.timeout

func opp_history(current_highest_attack):
	var opp_texture = current_highest_attack.get_node("CardImg").texture
	opp_card_textures.append(opp_texture)
	if current_highest_attack not in opponent_cards_history:
		opponent_cards_history.append(current_highest_attack)
		var logbook = $"../LogBookContainer"
		var player_history_ref = $"../CardManager".player_history
		var player_history_index = player_history_ref.size() - 1
		var opp_history_yPos
	
		for index in range(opponent_cards_history.size()):
			if player_history_ref.size() > 0:
				opp_history_yPos = player_history_ref[player_history_index].position.y
			else:
				opp_history_yPos = OPP_HISTORY_POS_Y * index
			opponent_cards_history[index] = card_history.instantiate()
			opponent_cards_history[index].z_index = 7
			opponent_cards_history[index].position = Vector2(logbook.position.x - 150, opp_history_yPos + 180)
			opponent_cards_history[index].get_node("HistoryImg").texture = opp_card_textures[index]
			var opp_history_child = opponent_cards_history[index].get_node("PlayerCardHistory")
			opp_history_child.get_node("LogBookBGImg").modulate = Color(0,0,0)
			add_child(opponent_cards_history[index])
			opp_history_nodes.append(opponent_cards_history[index]) #needs to hide all the ones spawned

func wait(wait_time):
	battle_timer.wait_time = wait_time
	battle_timer.start()
	await battle_timer.timeout

func end_opponent_turn():
	#End Turn ~~ player turn/draw
	$"../PlayerDeck".reset_draw()
	$"../PlayerDeck".draw_card()
	$"../CardManager".reset_play()
	$"../EndTurn".disabled = false
	$"../EndTurn".visible = true
	is_opponents_turn = false

func direct_attack(attacking_card, attacker):
	var new_pos_y
	if attacker == "Opponent":
		new_pos_y = 1080
	else:
		$"../EndTurn".disabled = true
		$"../EndTurn".visible = false
		new_pos_y = 0
		is_attacking = true
		player_cards_attacked.append(attacking_card)
	var old_pos = attacking_card.position
	var new_pos = Vector2(attacking_card.position.x, new_pos_y)
	attacking_card.z_index = 5
	var tween = get_tree().create_tween()
	tween.tween_property(attacking_card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)
	
	if attacker == "Opponent":
		player_health -= max(0, attacking_card.attack)
		$"../TextContainer/PlayerHealth/HealthNum".text = str(player_health)
	else:
		opponent_health -= max(0, attacking_card.attack)
		$"../TextContainer/OppHealth/HealthNum".text = str(opponent_health)

	var tween2 = get_tree().create_tween()
	tween2.tween_property(attacking_card, "position", old_pos, CARD_MOVE_SPEED)
	attacking_card.z_index = 1
	await wait(1.0)
	if attacker == "Player":
		is_attacking = false
		$"../EndTurn".disabled = false
		$"../EndTurn".visible = true

func attack_cards(attacking_card, defending_card, attacker):
	if attacker == "Player":
		is_attacking = true
		$"../EndTurn".disabled = true
		$"../EndTurn".visible = false
		$"../CardManager".selected_monster = null
		player_cards_attacked.append(attacking_card)
	attacking_card.z_index = 5
	var old_pos = attacking_card.position
	if attacker == "Opponent":
		var new_pos_opp = Vector2(defending_card.position.x, defending_card.position.y - BATTLE_OFFSET)
		var opp_tween = get_tree().create_tween()
		opp_tween.tween_property(attacking_card, "position", new_pos_opp, CARD_MOVE_SPEED)
	else: #players attacking
		var new_pos_player = Vector2(defending_card.position.x, defending_card.position.y + BATTLE_OFFSET)
		var opp_tween = get_tree().create_tween()
		opp_tween.tween_property(attacking_card, "position", new_pos_player, CARD_MOVE_SPEED)
	await wait(0.15)
	var tween_return = get_tree().create_tween()
	tween_return.tween_property(attacking_card, "position", old_pos, CARD_MOVE_SPEED)
	
	defending_card.health -= max(0, attacking_card.attack)
	defending_card.get_node("Health").text = str(defending_card.health)
	
	attacking_card.health -= max(0, defending_card.attack)
	attacking_card.get_node("Health").text = str(attacking_card.health)
	attacking_card.z_index = 1
	battle_timer.start()
	await battle_timer.timeout
	
	var card_destroyed = false
	
	if attacking_card.health < 1:
		destroy_card(attacking_card, attacker)
		attacking_card.health = 0
		defending_card.get_node("Health").text = str(defending_card.health)
		card_destroyed = true
	
	if defending_card.health < 1:
		if attacker == "Player":
			destroy_card(defending_card, "Opponent")
		else:
			destroy_card(defending_card, "Player")
		defending_card.health = 0
		defending_card.get_node("Health").text = str(defending_card.health)
		
		card_destroyed = true
	if card_destroyed:
		battle_timer.start()
		await battle_timer.timeout
	if attacker == "Player":
		is_attacking = false
		$"../EndTurn".disabled = true
		$"../EndTurn".visible = false

func opp_card_selected(defending_card):
	var attacking_card = $"../CardManager".selected_monster
	if attacking_card and defending_card in opponent_cards_in_play:
		if !is_attacking: #not currently attacking
			$"../CardManager".selected_monster = null 
			attack_cards(attacking_card, defending_card, "Player")

func destroy_card(card, card_owner):
	#move card to GY
	#remove card from arrays ~~ slots
	var new_pos
	if card_owner == "Player":
		card.defeated = true
		card.get_node("Area2D/CollisionShape2D").disabled = true
		new_pos = $"../PlayerGY".position
		player_gy_count += 1
		player_gy_txt.text = str(player_gy_count)
		if card in player_cards_in_play:
			player_cards_in_play.erase(card)
		card.card_in_slot.get_node("Area2D/CollisionShape2D").disabled = false
		player_graveyard_check.append(card)
	else:
		new_pos = $"../OppGY".position
		opponent_gy_count += 1
		opponent_gy_text.text = str(opponent_gy_count)
		if card in opponent_cards_in_play:
			opponent_cards_in_play.erase(card)
		opponent_graveyard_check.append(card)
	
	card.card_in_slot = null
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_pos, CARD_MOVE_SPEED)
	await wait(0.15)

func graveyard_check_for_player():
	var graveyard_checker = $"../GraveyardChecker"
	var graveyard_spawn
	var initial_pos = Vector2(-79.506, 62.939)
	
	if is_graveyard_open == false:
		graveyard_checker.get_node("GraveyardName").text = "JUNKYARD OPEN"
		graveyard_checker.propagate_call("set_visible", [true]) #change self and children
		is_graveyard_open = true
		for card in range(player_graveyard_check.size()):
			player_graveyard_check[card] = graveyard_card.instantiate()
			player_graveyard_check[card].position = initial_pos
			player_graveyard_check[card].z_index = 10
			add_child(player_graveyard_check[card])
	else: #close graveyard
		graveyard_checker.propagate_call("set_visible", [false])
		is_graveyard_open = false

func graveyard_check_for_opp():
	var graveyard_checker = $"../GraveyardChecker"
	if is_graveyard_open == false:
		graveyard_checker.get_node("GraveyardName").text = "MAUSOLEUM OPEN"
		graveyard_checker.propagate_call("set_visible", [true]) #change self and children
		is_graveyard_open = true
	else: #close graveyard
		graveyard_checker.propagate_call("set_visible", [false])
		is_graveyard_open = false

func end_turn_button(is_enabled):
	if is_enabled:
		$"../EndTurn".disabled = false
		$"../EndTurn".visible = true
	else:
		$"../EndTurn".disabled = true
		$"../EndTurn".visible = false

func _on_log_book_pressed() -> void:
	var log_book = $"../LogBookContainer"
	var manager_history = $"../CardManager".history_nodes
	#if is_opponents_turn == false:
	var log_tween = get_tree().create_tween()
	var history_tween = get_tree().create_tween()
	if is_logbook_open == false:
		log_tween.tween_property(log_book, "position", Vector2(log_book.position.x - 200, log_book.position.y), CARD_MOVE_SPEED)
		is_logbook_open = true
		for i in manager_history.size():
			manager_history[i].visible = true
	else:
		log_tween.tween_property(log_book, "position", Vector2(log_book.position.x + 200, log_book.position.y), CARD_MOVE_SPEED)
		is_logbook_open = false
		$"../CardManager".hide_history()
