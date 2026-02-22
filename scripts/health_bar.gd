extends Node2D

@onready var health_bar: Sprite2D = $Health
@onready var default_width = health_bar.region_rect.size.x
@onready var default_height = health_bar.region_rect.size.y

var max_health: int

func initialize(max_hp: int, current_hp: int) -> void:
	max_health = max_hp
	update_health(current_hp)

func update_health(current_health: int) -> void:
	var ratio: float =  clamp(float(current_health) / max_health, 0.0, 1.0)
	var new_width: float = ratio * default_width
	health_bar.region_rect = Rect2(0, 0, new_width, default_height)
