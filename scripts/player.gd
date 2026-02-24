extends CharacterBody2D

signal health_changed(new_health: int)
signal died

const SPEED = 300.0

var last_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false
var hitbox_offset: Vector2
var alive: bool = true
var max_health: int
var health: int
var strength: int = 30
var invincible: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var swordswing: AudioStreamPlayer2D = $swordswing
@onready var hitbox: Area2D = $Hitbox
@onready var damage_cooldown: Timer = $DamageCooldown


func _ready() -> void:
	add_to_group("Player")
	PlayerStats.leveled_up.connect(_on_level_up)
	
	strength = PlayerStats.strength
	health = PlayerStats.health
	max_health = PlayerStats.max_health
	
	hitbox_offset = hitbox.position
	
	emit_signal("health_changed", health)
	
	invincible = true
	await get_tree().create_timer(1.0).timeout
	invincible = false

func _physics_process(_delta: float) -> void:
	
	if alive:
		if Input.is_action_just_pressed("attack") and not is_attacking:
			attack()
	
		if is_attacking:
			velocity = Vector2.ZERO
			return
	
		process_movement()
		process_animation()
		move_and_slide()


func process_movement() -> void:
	
	
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		last_direction = direction
		update_hitbox_offset()
	else:
		velocity = Vector2.ZERO


func process_animation() -> void:
	if is_attacking:
		return
	if velocity != Vector2.ZERO:
		play_animation("run", last_direction)
	else:
		play_animation("idle", last_direction)


func play_animation(prefix : String, dir: Vector2) -> void:
	var anim_name
	
	if dir.x != 0:
		animated_sprite_2d.flip_h = dir.x < 0
		anim_name = prefix + "_right"
	elif dir.y < 0:
		anim_name = prefix + "_up"
	else:
		anim_name = prefix + "_down"
	if animated_sprite_2d.animation != anim_name:
		animated_sprite_2d.play(anim_name)

func attack() -> void:
	is_attacking = true
	hitbox.monitoring = true
	swordswing.play()
	play_animation("attack", last_direction)


func _on_animated_sprite_2d_animation_finished() -> void:
	if is_attacking:
		is_attacking = false
		hitbox.monitoring = false


func update_hitbox_offset() -> void:
	var x := hitbox_offset.x
	var y := hitbox_offset.y
	
	match last_direction:
		Vector2.LEFT:
			hitbox.position = Vector2(-x , y)
		Vector2.RIGHT:
			hitbox.position = Vector2(x , y)
		Vector2.UP:
			hitbox.position = Vector2(y , -x)
		Vector2.DOWN:
			hitbox.position = Vector2(-y , x)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if is_attacking and body.has_method("take_damage"):
		var damage_done = strength
		print("Player dealt: ", damage_done)
		body.take_damage(strength, global_position)

func heal(amount: int) -> void:
	health = clamp(health + amount, 0, max_health)
	PlayerStats.health = health
	emit_signal("health_changed", health)


func take_damage(amount: int) -> void:
	if not alive:
		return
	
	if invincible:
		return

	if damage_cooldown.time_left > 0:
		return

	print("Damage taken:", amount)

	health -= amount
	print("Current health:", health)

	PlayerStats.health = health
	emit_signal("health_changed", health)

	if health <= 0:
		die()
		return

	damage_cooldown.start()

func die() -> void:
	if not alive:
		return

	print("die() called")

	alive = false
	velocity = Vector2.ZERO

	$CollisionShape2D.disabled = true
	$Hitbox.monitoring = false

	animated_sprite_2d.play("dying")
	died.emit()

func _on_level_up():
	max_health = PlayerStats.max_health
	strength = PlayerStats.strength
	health = max_health
	emit_signal("health_changed", health)
