extends Node2D

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_SLOT = 2
const COLLISION_LOG_BOOK = 3
const DEFAULT_CARD_SPEED = 0.1
const DEFAULT_SCALE = 0.8
const HOVER_SCALE = 0.85
const SLOT_SCALE = 0.6
const SELECTED_SCALE = 0.1
const SCALE_SPEED = 1

var player_history = []
var history_nodes = []
var card_textures: Array[Texture2D] = []

var screen_size
var card_dragged
var is_hovering
var player_hand_ref
var player_energy = 3
var energy_txt
var selected_monster

var new_history

var card_history = load("res://Assets/Scenes/card_played.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_ref = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)
	energy_txt = $"../TextContainer/Energy/EnergyNum"
	energy_txt.text = str(player_energy)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if card_dragged:
		var mouse_pos = get_global_mouse_position()
		card_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), 
		clamp(mouse_pos.y, 0, screen_size.y))

func card_clicked(card):
	if card.card_in_slot && $"../BattleManager".is_opponents_turn == false:
		card.get_node("ZoomButton").visible = true
		card.get_node("ZoomButton").disabled = false
		if $"../BattleManager".is_attacking == false:
			if card not in $"../BattleManager".player_cards_attacked: #if card hasnt attacked this turn
				card.get_node("AttackButton").visible = true
				card.get_node("AttackButton").disabled = false
				print("attacking")
	else:

		start_drag(card)

func select_battle(card):
	if selected_monster:
		if selected_monster == card:
			card.position.y += 20
			selected_monster = null
		else:
			selected_monster.position.y + 20
			selected_monster = card
			card.position.y -= 20
	else: #cancel out attack
		selected_monster = card
		card.position.y -= 20

func unselect():
	if selected_monster:
		selected_monster.position.y += 20
		selected_monster = null


func start_drag(card):
	card.scale = Vector2(DEFAULT_SCALE, DEFAULT_SCALE)
	card_dragged = card
	card_dragged.z_index = 2

func finish_drag():
	card_dragged.scale = Vector2(HOVER_SCALE, HOVER_SCALE)
	var card_slot_found = raycast_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot && player_energy > 0:
		card_dragged.scale = Vector2(SLOT_SCALE, SLOT_SCALE)
		card_dragged.z_index = 1
		card_dragged.card_in_slot = card_slot_found
		player_energy -= int(card_dragged.energy_cost)
		is_hovering = false
		energy_txt.text = str(player_energy)
		player_hand_ref.remove_card_from_hand(card_dragged)
		
		#add played card into history pool
		var texture = card_dragged.get_node("CardImg").texture
		if texture:
			card_textures.append(texture)
		if card_dragged not in player_history:
			player_history.append(card_dragged)
		generate_player_history()
		#card goes into slot
		print(card_slot_found.name)
		if card_slot_found.name == "PlayerMat":
			card_dragged.position = get_viewport().get_mouse_position()
		else:
			card_dragged.position = card_slot_found.position
			card_slot_found.card_in_slot = true
			card_slot_found.get_node("Area2D/CollisionShape2D").disabled = true
		card_dragged.get_node("Energy").visible = false
		print(card_dragged.card_name)
		if card_dragged.card_type == "Monster":
			$"../BattleManager".player_cards_in_play.append(card_dragged)
		var shrink = Vector2(SELECTED_SCALE, SELECTED_SCALE)
		var grow = Vector2(SLOT_SCALE, SLOT_SCALE)
		if card_dragged.effect_script:
			var tween = get_tree().create_tween()
			if card_dragged.card_name == "Army" || card_dragged.card_name == "Army1":
				tween.tween_property(card_dragged, "scale", shrink, 0.6)
			card_dragged.effect_script.trigger_effect($"../BattleManager", card_dragged)
			tween.tween_property(card_dragged, "scale", grow, 0.6)
			
	else:
		player_hand_ref.add_card_to_hand(card_dragged, DEFAULT_CARD_SPEED)
	card_dragged = null
	

func on_left_click_released():
	if card_dragged:
		finish_drag()

func connect_card_signals(card):
	card.connect("hovered", on_hovered)
	card.connect("hovered_off", off_hovered)
	card.connect("zoomed_in", zoom_in)
	card.connect("attack_sig", attack_sig)

func on_hovered(card):
	if card.card_in_slot:
		return
	if !is_hovering:
		is_hovering = true
		highlight_card(card, true)
		#can zoom in on card for easier readability
		card.get_node("ZoomButton").disabled = false
		card.get_node("ZoomButton").visible = true

func off_hovered(card):
	await  $"../BattleManager".wait(0.8)
	card.get_node("ZoomButton").disabled = true
	card.get_node("ZoomButton").visible = false
	card.get_node("AttackButton").disabled = true
	card.get_node("AttackButton").visible = false
	if !card.defeated: #if card is not in graveyard
		if !card.card_in_slot && !card_dragged:
			highlight_card(card, false)
			var new_card_hovered = raycast_card()
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering = false

func zoom_in(card):
	$"../ZoomedInCard".visible = true
	$"../ZoomedInCard".get_node("ZoomedCardImg").texture = card.get_node("CardImg").texture
	$"../ZoomedInCard".get_node("ZoomedTxt").text = card.get_node("EffectTxt").text
	await  $"../BattleManager".wait(2)
	$"../ZoomedInCard".visible = false

func card_history_zoom(card_history):
	if card_history:
		$"../ZoomedInCard".visible = true
		if card_history.name != "GraveyardCard":
			$"../ZoomedInCard".get_node("ZoomedCardImg").texture = card_history.get_node("HistoryImg").texture
		else: #its the graveyard check
			$"../ZoomedInCard".get_node("ZoomedCardImg").texture = card_history.get_node("GraveYardImg").texture
		#change text
		$"../ZoomedInCard".get_node("ZoomedTxt").text = ""
		await $"../BattleManager".wait(2)
		$"../ZoomedInCard".visible = false

func generate_player_history():
		var logbook = $"../LogBookContainer"
		var opp_history = $"../BattleManager".opponent_cards_history
		var opp_history_index = opp_history.size() - 1
		var player_history_yPos = 180
		if opp_history.size() > 0:
			player_history_yPos = opp_history[opp_history_index].position.y
		else:
			player_history_yPos = 0
		for index in range(player_history.size()):
			player_history[index] = card_history.instantiate()
			player_history[index].z_index = 7
			player_history[index].position = Vector2(logbook.position.x - 150, player_history_yPos + 180 * index)
			player_history[index].get_node("HistoryImg").texture = card_textures[index]
			add_child(player_history[index])
			history_nodes.append(player_history[index]) #needs to hide all the ones spawned
			player_history[index].visible = true

func hide_history():
	if player_history:
		for nodes in history_nodes:
			nodes.visible = false


func attack_sig(card):
	if $"../BattleManager".opponent_cards_in_play.size() < 1: #if opp field is empty direct attack
		$"../BattleManager".direct_attack(card, "Player")
		return
	else:
		select_battle(card)

func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(HOVER_SCALE, HOVER_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_SCALE, DEFAULT_SCALE)
		card.z_index = 1

func raycast_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		#return result[0].collider.get_parent()
		return get_card_w_highest_index(result)
	return null

func raycast_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_SLOT
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null


func get_card_w_highest_index(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card #always drags the card ontop
	
func reset_play():
	player_energy = 3
	energy_txt.text = str(player_energy)
