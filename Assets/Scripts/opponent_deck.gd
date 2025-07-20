extends Node2D

const CARD_SCENE_PATH = "res://Assets/Scenes/opponent_card.tscn"
const CARD_DRAW_SPEED = 0.3
const START_GAME_DRAW = 5

var opponent_deck = ["Army", "Army","Army","Army1", "Army1", "Army2"]
var card_databaseref 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	opponent_deck.shuffle()
	card_databaseref = preload("res://Assets/Scripts/card_database.gd")
	for i in range(START_GAME_DRAW):
		draw_card()


func draw_card():
	var card_drawn_name = opponent_deck[0]
	opponent_deck.erase(card_drawn_name)
	
	if opponent_deck.size() == 0:
		$Sprite2D.visible = false
	
	var card_scene = preload(CARD_SCENE_PATH)
	var new_card = card_scene.instantiate() #spawn card
	var card_image_path = str("res://Assets/Art/" + card_drawn_name + "Card.png")
	new_card.get_node("CardImg").texture = load(card_image_path)
	new_card.attack = card_databaseref.CARDS[card_drawn_name][0]
	new_card.health = card_databaseref.CARDS[card_drawn_name][1]
	new_card.get_node("Attack").text = str(new_card.attack)
	new_card.get_node("Health").text = str(new_card.health)
	new_card.card_effect = str(card_databaseref.CARDS[card_drawn_name][2])
	new_card.z_index = 1
	$"../CardManager".add_child(new_card) #otherwise cards give area
	new_card.name = "Card"
	$"../OpponentHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
