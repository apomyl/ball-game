extends Control

func _on_go_pressed() -> void:
	
	PlayerDetails.planet_name = $"Planet Selector".index
	
	get_tree().change_scene_to_file("res://main.tscn")
