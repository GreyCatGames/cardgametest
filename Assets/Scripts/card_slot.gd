extends Node2D


var card_in_slot = false
var slot_name

#func _ready() -> void:
	#if get_parent() == $"../../BottomSlots":
		#slot_name = "Bottom"
	#else:
		#slot_name = "Top"
	#print(slot_name)
