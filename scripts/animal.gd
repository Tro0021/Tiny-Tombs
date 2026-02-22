extends CharacterBody2D

const WANDER_SPEED := 40
const  FLEE_SPEED := 100

var direction := Vector2.ZERO
var change_timer := 0.0
var fleeing := false
var player: Node2D = null

@onready var fear_aera: Area2D = $FearAera
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	randomize()
	fear_aera.body_entered.connect(_on_fear_entered)
	fear_aera.body_exited.connect(_on_fear_exited)

func _physics_process(delta):
	if fleeing and player:
		var flee_dir = (global_position - player.global_position).normalized()
		velocity = flee_dir * FLEE_SPEED
	else:
		change_timer -= delta
		if change_timer <= 0:
			if randf() < 0.4:
				direction = Vector2.ZERO
			else:
				direction = Vector2(
					randf_range(-1, 1),
					randf_range(-1, 1)
				).normalized()
			change_timer = randf_range(1.0, 3.0)
		
		velocity = direction * WANDER_SPEED
	
	move_and_slide()
	update_animation()

func update_animation():
	if velocity.length() > 5:
		if animated_sprite_2d.animation != "run":
			animated_sprite_2d.play("run")
		
		if velocity.x != 0:
			animated_sprite_2d.flip_h = velocity.x < 0
	else:
		if animated_sprite_2d.animation != "idle":
			animated_sprite_2d.play("idle")

func _on_fear_entered(body):
	if body.name == "Player":
		fleeing = true
		player = body

func _on_fear_exited(body):
	if body.name == "Player":
		fleeing = false
		player = null
