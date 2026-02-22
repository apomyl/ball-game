extends Control

@export var max_points = 1500

@onready var speed_slider = $SliderContainer/SpeedSlider
@onready var mass_slider = $SliderContainer/MassSlider
@onready var health_slider = $SliderContainer/HealthSlider

@onready var speed_label = $SliderContainer/SpeedLabelContainer/SpeedValue
@onready var mass_label = $SliderContainer/MassLabelContainer/MassValue
@onready var health_label = $SliderContainer/HealthLabelContainer/HealthValue

func _ready() -> void:
	update_ui()
	
func _on_go_pressed() -> void:
	PlayerDetails.PlanetName = $"Planet Selector".index
	PlayerDetails.Speed = speed_slider.value
	PlayerDetails.Mass = mass_slider.value
	PlayerDetails.BaseHealth = health_slider.value
	
	get_tree().change_scene_to_file("res://ui/powerups/power1.tscn")

func _on_speed_slider_value_changed(_value: float) -> void:
	update_ui()
	
func _on_mass_slider_value_changed(_value: float) -> void:
	update_ui()

func _on_health_slider_value_changed(_value: float) -> void:
	update_ui()


func update_ui() -> void:

	var remaining_points = max_points - (speed_slider.value + mass_slider.value + health_slider.value)
	
	speed_slider.max_value = speed_slider.value + remaining_points
	mass_slider.max_value = mass_slider.value + remaining_points
	health_slider.max_value = health_slider.value + remaining_points
	

	speed_label.text = "[font_size=20]%d/%d" % [speed_slider.value, speed_slider.max_value]
	mass_label.text = "[font_size=20]%d/%d" % [mass_slider.value, mass_slider.max_value]
	health_label.text = "[font_size=20]%d/%d" % [health_slider.value, health_slider.max_value]
