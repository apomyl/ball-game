extends Button

func _on_pressed():

	PlayerDetails.advance_enemy()
	get_tree().change_scene_to_file("res://ui/transition.tscn")
