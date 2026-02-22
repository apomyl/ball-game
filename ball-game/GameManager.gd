extends Node

# Stores the path to the scenes we want to spawn
var player_scene_path: String = ""
var enemy_scene_path: String = ""

func set_battle_setup(player_path: String, enemy_path: String):
	player_scene_path = player_path
	enemy_scene_path = enemy_path
	# Change to the battle scene
	get_tree().change_scene_to_file("res://ui/battles/battle.tscn")
