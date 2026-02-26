extends Node2D

@export_group("Spawn Settings")
@export var animal_scenes: Array[PackedScene] = []
@export var spawn_count: int = 8
@export var max_attempts_per_animal: int = 10 

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var animal_container: Node2D

func _ready() -> void:
	animal_container = Node2D.new()
	animal_container.name = "SpawnedAnimals"
	add_child(animal_container)
	
	randomize()
	await get_tree().process_frame
	spawn_animals()

func spawn_animals() -> void:
	if animal_scenes.is_empty():
		push_warning("Spawner: No animal scenes assigned!")
		return
	
	var shape = collision_shape_2d.shape
	if not shape is RectangleShape2D:
		push_error("Spawner: CollisionShape2D must be a RectangleShape2D")
		return

	var extents = shape.size / 2 
	
	for i in range(spawn_count):
		_attempt_spawn(extents)

func _attempt_spawn(extents: Vector2) -> void:
	var spawned = false
	var attempts = 0
	
	while not spawned and attempts < max_attempts_per_animal:
		attempts += 1
		
		var random_offset = Vector2(
			randf_range(-extents.x, extents.x),
			randf_range(-extents.y, extents.y)
		)
		var spawn_pos = global_position + random_offset
		
		if _is_pos_safe(spawn_pos):
			_create_animal(spawn_pos)
			spawned = true

func _is_pos_safe(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collision_mask = 1 
	
	var result = space_state.intersect_point(query)
	return result.is_empty()

func _create_animal(pos: Vector2) -> void:
	var random_scene = animal_scenes.pick_random()
	var animal = random_scene.instantiate()
	
	animal_container.add_child(animal)
	animal.global_position = pos

func _on_animal_removed():
	pass
