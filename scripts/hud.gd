extends CanvasLayer

const HEART_SIZE: int = 20
var player

@onready var level_label: Label = $LevelLabel


const HEART_FULL = preload("res://assets/images/UI/Heart_full.png")
const HEART_HALF = preload("res://assets/images/UI/Heart_half.png")
const HEART_EMPTY = preload("res://assets/images/UI/Heart_empty.png")

func set_player(p) -> void:
	if player and player.health_changed.is_connected(_update_health):
		player.health_changed.disconnect(_update_health)
	player = p
	if player:
		player.health_changed.connect(_update_health)
		_update_health(player.health)

@onready var fade_overlay: ColorRect = $FadeOverlay
@onready var hearts_container: HBoxContainer = $Hearts



func _update_health(new_health: int) -> void:
	var hearts = hearts_container.get_children()
	var max_hearts = hearts.size()

	for heart in hearts:
		heart.texture = HEART_EMPTY
	
	var full_hearts: int = new_health / HEART_SIZE
	var remainder: int = new_health % HEART_SIZE
	var has_half: bool = remainder > 0
	
	for i in range(min(full_hearts, max_hearts)):
		hearts[i].texture = HEART_FULL
	if has_half and full_hearts < max_hearts:
		hearts[full_hearts].texture = HEART_HALF

func fade(to_alpha: float, text: String = "") -> void:
	if text != "":
		level_label.text = text
		level_label.visible = true
	else:
		level_label.visible = false
		
	var tween := create_tween()
	tween.tween_property(fade_overlay, "modulate:a", to_alpha, 1.5)
	await tween.finished
	
	if to_alpha == 0:
		level_label.visible = false
