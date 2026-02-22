extends TextureRect

var power1: int
var power2: int
var power3: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerDetails.UnusedPowerups.shuffle()
	power1 = PlayerDetails.UnusedPowerups.pop_front()
	power2 = PlayerDetails.UnusedPowerups.pop_front()
	power3 = PlayerDetails.UnusedPowerups.pop_front()
	$Button/RichTextLabel.text = PlayerDetails.PowerupDesc.get(power1)
	$Button2/RichTextLabel.text = PlayerDetails.PowerupDesc.get(power2)	
	$Button3/RichTextLabel.text = PlayerDetails.PowerupDesc.get(power3)
	
func _on_button_pressed() -> void:
	PlayerDetails.Powerups.append(power1)
	PlayerDetails.UnusedPowerups.append(power2)
	PlayerDetails.UnusedPowerups.append(power3)
	get_tree().change_scene_to_file("res://ui/profiles/pluto_profile.tscn")



func _on_button_2_pressed() -> void:
	PlayerDetails.Powerups.append(power2)
	PlayerDetails.UnusedPowerups.append(power1)
	PlayerDetails.UnusedPowerups.append(power3)
	get_tree().change_scene_to_file("res://ui/profiles/pluto_profile.tscn")



func _on_button_3_pressed() -> void:
	PlayerDetails.Powerups.append(power3)
	PlayerDetails.UnusedPowerups.append(power2)
	PlayerDetails.UnusedPowerups.append(power1)
	get_tree().change_scene_to_file("res://ui/profiles/pluto_profile.tscn")
