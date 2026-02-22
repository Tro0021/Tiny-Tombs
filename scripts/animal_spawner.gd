extends  Node2D

@export var animal_scenes: Array[PackedScene]
@export var spawn_count: int = 8

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	randomize()
	spawn_animals()

func spawn_animals():
	if animal_scenes.is_empty():
		return
	
	var shape = collision_shape_2d.shape as RectangleShape2D
	if  shape == null:
		return

	var extents = shape.extents
	
	for i in range(spawn_count):
		var random_scene = animal_scenes.pick_random()
		var animal = random_scene.instantiate()
		
		var random_offset = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
		
		animal.position = random_offset
		call_deferred("add_child", animal)
