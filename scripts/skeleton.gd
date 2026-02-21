extends CharacterBody2D

const SPEED: int = 120
const KNOCKBACK_FORCE: int = 120
const DROP_CHANCE: float = 0.3
const PATROL_DISTANCE: int = 80

var is_alive: bool = true
var health: int = 120
var strength: int = 15

var target: Node2D = null
var target_in_range: bool = false
var last_direction: Vector2 = Vector2.DOWN

var patrol_start_position: Vector2
var patrol_direction: int = 1

var health_pickup_scene = preload("res://scenes/health_pickup.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: Node2D = $HealthBar
@onready var attack_timer: Timer = $AttackTimer


func _ready() -> void:
	patrol_start_position = global_position


func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	if target:
		handle_chase()
	else:
		handle_patrol(delta)


# -----------------------
# PATROL
# -----------------------

func handle_patrol(delta: float) -> void:
	var offset = global_position.x - patrol_start_position.x
	
	if abs(offset) >= PATROL_DISTANCE:
		patrol_direction *= -1
	
	velocity = Vector2(patrol_direction * SPEED, 0)
	last_direction = velocity.normalized()
	
	move_and_slide()
	play_animation("run", last_direction)


# -----------------------
# CHASE + ATTACK
# -----------------------

func handle_chase() -> void:
	var direction = (target.global_position - global_position).normalized()
	last_direction = direction
	
	if not target_in_range:
		velocity = direction * SPEED
		move_and_slide()
		play_animation("run", direction)
	else:
		velocity = Vector2.ZERO


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target_in_range = true
		play_animation("attack", last_direction)
		body.take_damage(strength)
		attack_timer.start()


func _on_attack_timer_timeout() -> void:
	if target and target_in_range and is_alive:
		play_animation("attack", last_direction)
		target.take_damage(strength)


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		attack_timer.stop()


# -----------------------
# DETECTION
# -----------------------

func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player" and is_alive:
		target = body


func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target = null
		target_in_range = false
		attack_timer.stop()
		
		# Reset patrol cleanly
		patrol_start_position = global_position
		patrol_direction = 1
		
		velocity = Vector2.ZERO
		play_animation("idle", last_direction)


# -----------------------
# DAMAGE
# -----------------------

func take_damage(damage: int, attacker_position: Vector2) -> void:
	print("Damage")
	if not is_alive:
		return
	
	health -= damage
	health_bar.update_health(health)
	
	if health <= 0:
		die()
	else:
		var knockback_direction = (global_position - attacker_position).normalized()
		var target_position = global_position + knockback_direction * KNOCKBACK_FORCE
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", target_position, 0.2)


# -----------------------
# DEATH
# -----------------------

func die() -> void:
	if not is_alive:
		return
	
	is_alive = false
	velocity = Vector2.ZERO
	
	# Disable ALL logic instantly
	set_physics_process(false)
	
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	animated_sprite_2d.play("die")
	
	if randf() <= DROP_CHANCE:
		drop_item()


func drop_item():
	var drop = health_pickup_scene.instantiate()
	drop.health_effect = 25
	drop.position = global_position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)


# -----------------------
# ANIMATION SYSTEM
# -----------------------

func play_animation(prefix: String, dir: Vector2) -> void:
	if not is_alive:
		return
	if abs(dir.x) > abs(dir.y):
		animated_sprite_2d.flip_h = dir.x < 0
		animated_sprite_2d.play(prefix + "_right")
	elif dir.y < 0:
		animated_sprite_2d.play(prefix + "_up")
	else:
		animated_sprite_2d.play(prefix + "_down")
