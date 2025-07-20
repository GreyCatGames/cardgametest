extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4
const COLLISION_MASK_OPP_CARD = 8
const COLLISION_MASK_CARD_HISTORY = 16
const COLLISION_MASK_GRAVEYARD = 32

var card_manager_ref
var battle_manager_ref
var deck_ref
var inputs_disabled = false
var is_dragging = false

var initial_pos = Vector2.ZERO
func _ready() -> void:
	card_manager_ref = $"../CardManager"
	battle_manager_ref = $"../BattleManager"
	deck_ref = $"../PlayerDeck"

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("left_mouse_button_clicked")
			initial_pos = event.position
			raycast_at_cursor()
			#raycast check for card hit
		else:
			emit_signal("left_mouse_button_released")
			var distance = event.position.distance_to(initial_pos)
			if distance < 10: #Clicked
				is_dragging = false
			else: #Dragging
				is_dragging = true

func raycast_at_cursor():
	if inputs_disabled:
		return
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var result_col_mask = result[0].collider.collision_mask
		if result_col_mask == COLLISION_MASK_CARD:
			var card_found = result[0].collider.get_parent()
			if card_found:
				card_manager_ref.card_clicked(card_found)
		elif result_col_mask == COLLISION_MASK_DECK:
			deck_ref.draw_card()
		elif result_col_mask == COLLISION_MASK_OPP_CARD:
			battle_manager_ref.opp_card_selected(result[0].collider.get_parent())
		elif result_col_mask == COLLISION_MASK_CARD_HISTORY:
			var history_check = result[0].collider.get_parent()
			if history_check:
				print(history_check.name)
				card_manager_ref.card_history_zoom(history_check)
		elif result_col_mask == COLLISION_MASK_GRAVEYARD:
			var graveyard_check = result[0].collider.get_parent()
			if graveyard_check.name == "PlayerGY":
				print(graveyard_check)
				battle_manager_ref.graveyard_check_for_player()
			else:
				battle_manager_ref.graveyard_check_for_opp()
