extends Node2D

signal hovered
signal hovered_off

signal zoomed_in
signal attack_sig

var card_name
var start_pos
var card_in_slot
var card_type
var energy_cost = 0
var card_effect
var effect_script
var health
var attack

var can_attack = false
var defeated = false
var is_zoomed = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#all cards must be child of CardManager
	get_parent().connect_card_signals(self)
	$EffectTxt.text = str(card_effect)
	$ZoomButton.disabled = true
	$AttackButton.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)


func _on_zoom_button_pressed() -> void:
	emit_signal("zoomed_in", self)


func _on_attack_button_pressed() -> void:
	emit_signal("attack_sig", self)
