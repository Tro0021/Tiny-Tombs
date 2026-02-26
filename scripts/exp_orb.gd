extends Area2D

@export_group("Rewards")
@export var exp_value: int = 10

@export_group("Magnet Physics")
@export var magnet_radius: float = 150.0
@export var initial_speed: float = 50.0
@export var max_speed: float = 400.0
@export var acceleration: float = 12.0

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var float_time := 0.0
var current_speed := 0.0
var player: Node2D = null
var is_magnet_active: bool = false
var is_collected: bool = false

func _ready() -> void:
	animated_sprite_2d.play("EXP")
	current_speed = initial_speed
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return

	if not player:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() > 0:
			player = players[0]
		return

	_handle_movement(delta)

func _handle_movement(delta: float) -> void:
	var dist_to_player = global_position.distance_to(player.global_position)

	if dist_to_player < magnet_radius:
		is_magnet_active = true

	if is_magnet_active:
		var direction = (player.global_position - global_position).normalized()
		current_speed = move_toward(current_speed, max_speed, acceleration)
		global_position += direction * current_speed * delta
	else:
		float_time += delta
		var float_offset = sin(float_time * 3.0) * 0.2
		global_position.y += float_offset

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Player") or body.name == "Player") and not is_collected:
		is_collected = true
		
		if PlayerStats.has_method("add_exp"):
			PlayerStats.add_exp(exp_value)
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.1)
		tween.tween_property(self, "modulate:a", 0.0, 0.1)
		
		await tween.finished
		queue_free()
