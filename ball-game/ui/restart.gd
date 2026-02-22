extends Button


func _on_pressed() -> void:
	PlayerDetails.restart()
	get_tree().change_scene_to_file("res://ui/creation.tscn")
