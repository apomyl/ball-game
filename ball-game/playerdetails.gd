extends Node
class_name user

@export_enum("Jinzor", "Pacoria IX", "Apostis Major", "Selenara", "Sangor Prime") var PlanetName: int
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

var UnusedPowerups = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]

var PowerupDesc = {
	0: "Power 0",
	1: "Power 1", 
	2: "Power 2",
	3: "Power 3",
	4: "Power 4",
	5: "Power 5",
	6: "Power 6",
	7: "Power 7",
	8: "Power 8",
	9: "Power 9",
	10: "Power 10",
	11: "Power 11",
	12: "Power 12",
	13: "Power 13",
	14: "Power 14",
	15: "Power 15",
	16: "Power 16",
	17: "Power 17",
	18: "Power 18",
	19: "Power 19"
}

@export var Powerups: Array[int]
@export var Speed: float
@export var Mass: float
@export var BaseHealth: float
