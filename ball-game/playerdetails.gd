extends Resource
class_name user

@export_enum("Jinzor", "Pacoria IX", "Apostis Major", "Selenara", "Sangor Prime") var planet_name: int
var sprite_scale = [
	1,
	0.93,
	1.13,
	1.27,
	1.42
]
var sprite_file_paths = [
	"res://assets/exoplanet1.png",
	"res://assets/exoplanet2.png",
	"res://assets/exoplanet3.png",
	"res://assets/exoplanet4.png",
	"res://assets/exoplanet5.png"
]

@export var powerups: Array[String]
