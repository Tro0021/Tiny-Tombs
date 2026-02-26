extends  StaticBody2D

@export var max_health: int = 40
@export var respawn_time: float = 15.0
@export var bar_amount: int = 1
@export var ore_type: String = "silver"

var health: int
var alive: bool = true
var start_position: Vector2

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	start_position = global_position
	health = max_health

func take_damage(amount: int, _attacker_position: Vector2):
	if not alive:
		return
	
	health -= amount
	
	sprite.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1, 1, 1)
	
	if health <= 0:
		break_rock()

func break_rock():
	alive = false
	collision.set_deferred("disabled", true)
	sprite.visible = false
	
	drop_bars()
	
	await get_tree().create_timer(respawn_time).timeout
	respawn()

func drop_bars():
	print(ore_type, "bars: ", bar_amount)
	#Inventory.add_resource(ore_type, bar_amount)

func respawn():
	health = max_health
	alive = true
	collision.set_deferred("disabled", false)
	sprite.visible = true
	global_position = start_position
