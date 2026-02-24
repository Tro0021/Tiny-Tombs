extends Node

signal leveled_up
signal exp_changed

var level: int = 1
var current_exp: int = 0
var exp_to_next: int = 100

var base_health: int = 100
var base_strength: int = 30

var max_health: int = 100
var health: int = 100
var strength: int = 30


func add_exp(amount: int) -> void:
	current_exp += amount
	exp_changed.emit()
	print("EXP now:", current_exp)

	while current_exp >= exp_to_next:
		current_exp -= exp_to_next
		level_up()
		


func level_up() -> void:
	level += 1
	exp_to_next = int(exp_to_next * 1.4)

	max_health += 20
	strength += 5
	health = max_health

	leveled_up.emit()
	exp_changed.emit()

	print("LEVEL UP → Level:", level)


func reset() -> void:
	level = 1
	current_exp = 0
	exp_to_next = 100

	max_health = base_health
	health = max_health
	strength = base_strength

	exp_changed.emit()
