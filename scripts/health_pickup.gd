extends Area2D

@export_group("Settings")
@export var health_effect: int = 10
@export var hover_amplitude: float = 4.0
@export var hover_speed: float = 3.0

@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite_2d: Sprite2D = $Sprite2D

var float_time := 0.0
var is_collected := false
var start_y: float

func _ready() -> void:
	start_y = global_position.y
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if is_collected:
		return
	
	float_time += delta
	global_position.y = start_y + sin(float_time * hover_speed) * hover_amplitude

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	
	if body.is_in_group("Player") or body.name == "Player":
		_collect(body)

func _collect(player: Node2D) -> void:
	is_collected = true
	
	if player.has_method("heal"):
		player.heal(health_effect)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	if collected_sound:
		collected_sound.play()
	
	collision_shape_2d.set_deferred("disabled", true)
	
	if collected_sound and collected_sound.playing:
		await collected_sound.finished
	else:
		await tween.finished
	
	queue_free()
