extends Node2D

@onready var hud: CanvasLayer = $HUD

var level: int = 0 
var spawn_at_exit: String = ""
var current_level_root: Node = null
var player_scene := preload("res://scenes/player.tscn")
var is_transitioning: bool = false

var location_map : Dictionary = {
	"Hub": "res://scenes/hub.tscn",
	"Door_level1": "res://scenes/levels/level_1.tscn",
	"Door_Mining": "res://scenes/mining_area.tscn",
	"Door_Wood": "res://scenes/wood_area.tscn",
	"Door_Shop": "res://scenes/shop.tscn"
}

func _ready() -> void:
	hud.fade_overlay.modulate.a = 1.0
	
	_load_location("Hub")
	
	await hud.fade(0.0)

func _load_location(location_key: String) -> void:
	if current_level_root:
		current_level_root.queue_free()
		current_level_root = null
	
	if location_key == "Door_level1":
		level = 1
	else:
		level = 0
	
	var path = location_map[location_key]
	current_level_root = load(path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	
	var display_name = location_key.replace("Door_", "").capitalize()
	hud.update_world_text(display_name)
	
	_setup_level(current_level_root)

func _load_level(level_number: int) -> void:
	if current_level_root:
		current_level_root.queue_free()
		current_level_root = null
	
	var level_path = "res://scenes/levels/level_%s.tscn" % level_number
	
	if not ResourceLoader.exists(level_path):
		return
	
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	
	hud.update_world_text("Level " + str(level_number))
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
	var player = player_scene.instantiate()
	level_root.add_child(player)
	
	var spawn_point = level_root.get_node_or_null("Spawn")
	if spawn_point:
		player.global_position = spawn_point.global_position
	
	hud.set_player(player)
	player.died.connect(_on_player_died)

	if spawn_at_exit != "":
		var target_exit = level_root.get_node_or_null(spawn_at_exit)
		if target_exit:
			player.global_position = target_exit.global_position + Vector2(0, 20)
		spawn_at_exit = ""

	var exit_next = level_root.get_node_or_null("Exit")
	if exit_next:
		exit_next.body_entered.connect(_on_exit_next_body_entered)

	var exit_prev = level_root.get_node_or_null("Exitt")
	if exit_prev:
		exit_prev.body_entered.connect(_on_exit_prev_body_entered)

	for door_name in location_map.keys():
		var door_node = level_root.get_node_or_null(door_name)
		if door_node and door_node is Area2D:
			door_node.body_entered.connect(func(body): _on_hub_door_entered(body, door_name))

func _on_hub_door_entered(body: Node2D, location_key: String) -> void:
	if body.name == "Player" and not is_transitioning:
		_start_hub_transition(location_key)

func _start_hub_transition(location_key: String) -> void:
	if is_transitioning: return
	is_transitioning = true
	
	var display_name = location_key.replace("Door_", "").capitalize()
	await hud.fade(1.0, display_name)
	_load_location(location_key)
	await hud.fade(0.0)
	
	is_transitioning = false

func _start_transition(new_level: int, spawn_exit: String) -> void:
	if is_transitioning: return
	is_transitioning = true
	spawn_at_exit = spawn_exit
	
	await hud.fade(1.0, "Level " + str(new_level))
	_load_level(new_level)
	await hud.fade(0.0)

	await get_tree().create_timer(0.2).timeout
	is_transitioning = false

func _on_exit_next_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not is_transitioning:
		level += 1
		call_deferred("_start_transition", level, "Exitt")

func _on_exit_prev_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not is_transitioning:
		if level > 1:
			level -= 1
			call_deferred("_start_transition", level, "Exit")
		else:
			_start_hub_transition("Hub")

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	PlayerStats.reset()
	level = 0
	_start_hub_transition("Hub")
