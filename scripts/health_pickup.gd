extends Area2D

@export var health_effect: int = 20

@onready var collected_sound: AudioStreamPlayer2D = $CollectedSound
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.heal(health_effect)
		print(health_effect)
		
		visible = false
		collision_shape_2d.set_deferred("disabled", true)
		
		collected_sound.play()
		await collected_sound.finished
		
		queue_free()
