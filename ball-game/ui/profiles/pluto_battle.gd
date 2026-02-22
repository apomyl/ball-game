extends Button

func _on_pressed():

	PlayerDetails.e_path = "res://planets/pluto.tscn"
	get_tree().change_scene_to_file("res://ui/battles/battle.tscn")
