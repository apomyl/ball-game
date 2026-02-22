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

var EnemyPaths = {
	0: "res://planets/pluto.tscn",
	1: "res://planets/neptune.tscn",
	2: "res://planets/uranus.tscn",
	3: "res://planets/saturn.tscn",
	4: "res://planets/jupiter.tscn",
	5: "res://planets/mars.tscn",
	6: "res://planets/earth.tscn",
	7: "res://planets/venus.tscn",
	8: "res://planets/mercury.tscn",
	9: "res://planets/sun.tscn"
}

var current_enemy_index: int = 0

var UnusedPowerups = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19]

var PowerupDesc = {
	0: "res://assets/powerups/01.png",
	1: "res://assets/powerups/02.png", 
	2: "res://assets/powerups/03.png",
	3: "res://assets/powerups/04.png",
	4: "res://assets/powerups/05.png",
	5: "res://assets/powerups/06.png",
	6: "res://assets/powerups/07.png",
	7: "res://assets/powerups/08.png",
	8: "res://assets/powerups/09.png",
	9: "res://assets/powerups/10.png",
	10: "res://assets/powerups/11.png",
	11: "res://assets/powerups/12.png",
	12: "res://assets/powerups/13.png",
	13: "res://assets/powerups/14.png",
	14: "res://assets/powerups/15.png",
	15: "res://assets/powerups/16.png",
	16: "res://assets/powerups/17.png",
	17: "res://assets/powerups/18.png",
	18: "res://assets/powerups/19.png",
	19: "res://assets/powerups/20.png"
}

@export var Powerups: Array[int]
@export var Speed: float
@export var Mass: float
@export var BaseHealth: float

@export var e_path: String

func advance_enemy():
	# Update e_path using the current index
	e_path = EnemyPaths[current_enemy_index]
	
	# Increment the index for the next time this is called
	current_enemy_index += 1
	
	# Optional: Reset to 0 if we run out of enemies (looping)
	if current_enemy_index >= EnemyPaths.size():
		current_enemy_index = 0
		
	print("Next enemy path will be: ", e_path)
