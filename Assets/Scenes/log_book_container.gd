extends Node2D

#FOR PRACTICE ONLY

var battleman_ref
var cardman_ref
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battleman_ref = $"../BattleManager"
	cardman_ref = $"../CardManager"


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if battleman_ref.is_logbook_open == true:
		if cardman_ref.player_history.size() > 0:
			print("theres cards in here")
		for index in range(cardman_ref.player_history.size()):
			cardman_ref
