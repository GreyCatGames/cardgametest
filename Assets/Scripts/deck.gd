extends Node2D

const CARD_SCENE_PATH = "res://Assets/Scenes/card.tscn"
const CARD_DRAW_SPEED = 0.3
const START_GAME_DRAW = 5

var player_deck = ["Army", "Army","Army1", "Army1", "Army2", "MagicEx", "MagicEx1"]
var card_databaseref 
var can_draw_card = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player_deck.shuffle()
	$RichTextLabel.text = str(player_deck.size())
	card_databaseref = preload("res://Assets/Scripts/card_database.gd")
	for i in range(START_GAME_DRAW):
		draw_card()
		can_draw_card = false
	can_draw_card = true


func draw_card():
	if can_draw_card:
		return
	
	can_draw_card = true
	if player_deck.size() != 0:
		var card_drawn_name = player_deck[0]
		player_deck.erase(card_drawn_name)
		
		if player_deck.size() == 0:
			$Area2D/CollisionShape2D.disabled = true
			$Sprite2D.visible = false
			$RichTextLabel.visible = false
			can_draw_card = true
		
		$RichTextLabel.text = str(player_deck.size())
		var card_scene = preload(CARD_SCENE_PATH)
		var new_card = card_scene.instantiate() #spawn card
		new_card.card_name = card_drawn_name
		var card_image_path = str("res://Assets/Art/" + card_drawn_name + "Card.png")
		new_card.get_node("CardImg").texture = load(card_image_path)
		
		new_card.card_type = str(card_databaseref.CARDS[card_drawn_name][2])
		if new_card.card_type == "Monster":
			new_card.attack = card_databaseref.CARDS[card_drawn_name][0]
			new_card.health = card_databaseref.CARDS[card_drawn_name][1]
			new_card.get_node("Attack").text = str(new_card.attack)
			new_card.get_node("Health").text = str(new_card.health)
		else:
			new_card.get_node("Attack").visible = false
			new_card.get_node("Health").visible = false
		new_card.energy_cost = str(card_databaseref.CARDS[card_drawn_name][3])
		new_card.get_node("Energy").text = str(new_card.energy_cost)
		new_card.card_effect = str(card_databaseref.CARDS[card_drawn_name][4])
		new_card.get_node("EffectTxt").text = str(card_databaseref.CARDS[card_drawn_name][4])
		var new_card_effect = card_databaseref.CARDS[card_drawn_name][5]
		if new_card_effect:
			new_card.effect_script = load(new_card_effect).new()
		$"../CardManager".add_child(new_card) #otherwise cards give area
		new_card.name = "Card"
		$"../PlayerHand".add_card_to_hand(new_card, CARD_DRAW_SPEED)
		new_card.get_node("AnimationPlayer").play("card_flip")

func reset_draw():
	can_draw_card = false
