extends CharacterBody2D

const SPEED: int = 100
const KNOCKBACK_FORCE: int = 100
const DROP_CHANCE: float = 0.4
const RESPAWN_TIME: float = 10.0

var is_alive: bool = true
var health: int = 60
var strength: int = 5
var target = null
var target_in_range: bool = false

var spawn_position: Vector2
var slime_scene := preload("res://scenes/slime.tscn")

var health_pickup_scene = preload("res://scenes/health_pickup.tscn")
var exp_orb_scene := preload("res://scenes/exp_orb.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: Node2D = $HealthBar
@onready var attack_timer: Timer = $AttackTimer

func _ready() -> void:
	spawn_position = global_position
	health_bar.initialize(health, health)

func _physics_process(delta: float) -> void:
	if is_alive and target:
		_attack(delta)


func _attack(delta: float) -> void:
	var direction = (target.position - position).normalized()
	position += direction * SPEED * delta
	animated_sprite_2d.play("attack")


func take_damage(damage: int, attacker_position: Vector2) -> void:
	health -= damage
	health_bar.update_health(health)
	
	animated_sprite_2d.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.1).timeout
	animated_sprite_2d.modulate = Color(1, 1, 1)
	
	if health <= 0:
		_die()
	else:
		var knockback_direction = (position - attacker_position).normalized()
		var target_position = position + knockback_direction * KNOCKBACK_FORCE
	
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(self, "position", target_position, 0.5)
	
func _die() -> void:
	if not is_alive:
		return
	
	is_alive = false
	animated_sprite_2d.play("die")
	
	var orb = exp_orb_scene.instantiate()
	orb.global_position = global_position + Vector2(0, -10)
	get_parent().add_child(orb)
	
	if randf() <= DROP_CHANCE:
		drop_item()
	
	set_physics_process(false)
	visible = false
	$CollisionShape2D.set_deferred("disabled", true)
	$Sight/CollisionShape2D.set_deferred("disabled", true)
	$Hitbox/CollisionShape2D.set_deferred("disabled", true)
	
	await get_tree().create_timer(RESPAWN_TIME).timeout
	respawn()

func respawn() -> void:
	var new_slime = slime_scene.instantiate()
	new_slime.global_position = spawn_position
	get_parent().add_child(new_slime)
	queue_free()
	
func _on_sight_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target = body

func _on_sight_body_exited(body: Node2D) -> void:
	if body.name == "Player" and  is_alive:
		target = null
		animated_sprite_2d.play("idle")


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = true
		body.take_damage(strength)
		attack_timer.start()


func _on_attack_timer_timeout() -> void:
	if target and target_in_range:
		target.take_damage(strength)


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		target_in_range = false
		attack_timer.stop()

func drop_item():
	var drop = health_pickup_scene.instantiate()
	drop.health_effect = 10
	drop.position = position
	var level_root = get_parent().get_parent()
	var items_node = level_root.get_node("Items")
	items_node.call_deferred("add_child", drop)
