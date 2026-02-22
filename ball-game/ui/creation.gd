extends Control

var remaining_points

func _on_go_pressed() -> void:
	
	PlayerDetails.planet_name = $"Planet Selector".index
	PlayerDetails.Speed = $SliderContainer/SpeedSlider.value
	PlayerDetails.Mass = $SliderContainer/MassSlider.value
	PlayerDetails.BaseHealth = $SliderContainer/HealthSlider.value
	
	
	get_tree().change_scene_to_file("res://main.tscn")


func _on_speed_slider_drag_ended(value_changed: bool) -> void:
	pass # Replace with function body.


func _on_mass_slider_drag_ended(value_changed: bool) -> void:
	pass # Replace with function body.


func _on_health_slider_drag_ended(value_changed: bool) -> void:
	pass # Replace with function body.
