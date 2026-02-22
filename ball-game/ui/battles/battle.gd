extends Node2D

# Variables to hold the paths
var player_to_spawn: String = ""
var enemy_to_spawn: String = ""

func _ready():
	setup_battle()
	# If variables were set before scene change, spawn them now

func setup_battle():
	player_to_spawn = "res://player.tscn"
	enemy_to_spawn = PlayerDetails.e_path
	# If we are already in the scene, spawn immediately
	if is_inside_tree():
		spawn_planets()

func spawn_planets():
	# Remove existing placeholder player if it exists
	if has_node("Player"):
		get_node("Player").queue_free()

	# 1. Spawn Player on Left
	if player_to_spawn != "":
		var p_scene = load(player_to_spawn)
		var p_inst = p_scene.instantiate()
		p_inst.position = Vector2(400, 540)
		add_child(p_inst)
	
	# 2. Spawn Enemy on Right
	if enemy_to_spawn != "":
		var e_scene = load(enemy_to_spawn)
		var e_inst = e_scene.instantiate()
		e_inst.position = Vector2(1520, 540)
		add_child(e_inst)
