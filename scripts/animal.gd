extends CharacterBody2D

@export_group("Movement")
@export var wander_speed := 50.0
@export var flee_speed := 120.0
@export var acceleration := 10.0

@export_group("Combat")
@export var max_health := 20
@export var exp_value := 15

enum State { IDLE, WANDER, FLEE, DEAD }
var current_state : State = State.IDLE

var direction := Vector2.ZERO
var change_timer := 0.0
var player: Node2D = null

@onready var fear_area: Area2D = $FearArea 
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var health : int

var exp_orb_scene = preload("res://scenes/exp_orb.tscn")

func _ready() -> void:
	randomize()
	health = max_health
	
	add_to_group("hurtbox") 
	
	if not fear_area.body_entered.is_connected(_on_fear_entered):
		fear_area.body_entered.connect(_on_fear_entered)
	if not fear_area.body_exited.is_connected(_on_fear_exited):
		fear_area.body_exited.connect(_on_fear_exited)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	_determine_state(delta)
	_apply_movement(delta)
	move_and_slide()
	_update_animation()

func _determine_state(delta: float) -> void:
	if player:
		current_state = State.FLEE
	else:
		change_timer -= delta
		if change_timer <= 0:
			if randf() < 0.4:
				current_state = State.IDLE
				direction = Vector2.ZERO
			else:
				current_state = State.WANDER
				direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
			
			change_timer = randf_range(1.5, 4.0)

func _apply_movement(_delta: float) -> void:
	var target_velocity := Vector2.ZERO
	
	match current_state:
		State.IDLE:
			target_velocity = Vector2.ZERO
		State.WANDER:
			target_velocity = direction * wander_speed
		State.FLEE:
			if player:
				var flee_dir = (global_position - player.global_position).normalized()
				target_velocity = flee_dir * flee_speed
	
	velocity = velocity.move_toward(target_velocity, acceleration)

func _update_animation() -> void:
	if velocity.length() > 10:
		animated_sprite_2d.play("run")
		animated_sprite_2d.flip_h = velocity.x < 0
	else:
		animated_sprite_2d.play("idle")

func take_damage(amount: int, _attacker_pos: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD:
		return
		
	health -= amount
	print("Animal health: ", health)

	var flash_tween = create_tween()
	animated_sprite_2d.modulate = Color.RED
	flash_tween.tween_property(animated_sprite_2d, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		_die()

func _die() -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	
	# Disable collisions immediately
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	animated_sprite_2d.play("idle")
	animated_sprite_2d.modulate = Color(1, 0, 0, 1)
	
	if exp_orb_scene:
		var orb = exp_orb_scene.instantiate()
		get_parent().add_child(orb)
		orb.global_position = global_position
	
	await get_tree().create_timer(1.0).timeout
	
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	await fade_tween.finished
	queue_free()

func _on_fear_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("Player"):
		player = body

func _on_fear_exited(body: Node2D) -> void:
	if body == player:
		player = null
		current_state = State.IDLE
