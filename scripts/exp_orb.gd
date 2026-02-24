extends Area2D

@export var exp_value: int = 10
@export var magnet_radius: float = 120.0
@export var magnet_speed: float = 50.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var float_time := 0.0
var start_position: Vector2
var player: Node2D = null
var is_magnet_active: bool = false


func _ready():
	start_position = global_position
	animated_sprite_2d.play("EXP")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("Player")

	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance < magnet_radius:
			is_magnet_active = true

	if is_magnet_active and player:
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * magnet_speed * delta
	else:
		float_time += delta
		var float_offset = sin(float_time * 3.0) * 4.0
		global_position.y = start_position.y + float_offset


func _on_body_entered(body):
	if body.name == "Player":
		PlayerStats.add_exp(exp_value)
		queue_free()
