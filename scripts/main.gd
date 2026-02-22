extends Node2D

@onready var hud: CanvasLayer = $HUD

var level: int = 1
var spawn_at_exit: String = ""
var current_level_root: Node = null
var player_scene := preload("res://scenes/player.tscn")
var is_transitioning: bool = false

func _ready() -> void:
	_load_level(level)
	
	

func  _load_level(level_number: int) -> void:
	if current_level_root:
		current_level_root.free()
		current_level_root = null
	
	var level_path = "res://scenes/levels/level_%s.tscn" % level_number
	print("Loading level file:", level_path)
	
	if not ResourceLoader.exists(level_path):
		print("Level not found: ", level_path)
		return
	
	current_level_root = load(level_path).instantiate()
	add_child(current_level_root)
	current_level_root.name = "LevelRoot"
	
	_setup_level(current_level_root)

func _setup_level(level_root: Node) -> void:
	
	print("Setup level called for level:", level)
	
	var player = player_scene.instantiate()
	level_root.add_child(player)
	
	var spawn_point = level_root.get_node_or_null("Spawn")
	if spawn_point:
		player.global_position = spawn_point.global_position
	
	hud.set_player(player)
	player.died.connect(_on_player_died)

	# Position player if coming from another level
	if spawn_at_exit != "":
		var target_exit = level_root.get_node_or_null(spawn_at_exit)
		if target_exit:
			player.global_position = target_exit.global_position + Vector2(0, 20)
		spawn_at_exit = ""

	# Next Level Exit
	var exit_next = level_root.get_node_or_null("Exit")
	if exit_next:
		exit_next.body_entered.connect(_on_exit_next_body_entered)

	# Previous Level Exit
	var exit_prev = level_root.get_node_or_null("Exitt")
	if exit_prev:
		exit_prev.body_entered.connect(_on_exit_prev_body_entered)

func _start_transition(new_level: int, spawn_exit: String) -> void:
	if is_transitioning:
		return

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
	if body.name == "Player" and level > 1 and not is_transitioning:
		level -= 1
		call_deferred("_start_transition", level, "Exit")

func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout

	var respawn_level: int

	if level > 1:
		respawn_level = level - 1
	else:
		respawn_level = 1

	await hud.fade(1.0, "Level " + str(respawn_level))

	level = respawn_level
	PlayerStats.reset()
	spawn_at_exit = ""

	_load_level(level)

	await hud.fade(0.0)
