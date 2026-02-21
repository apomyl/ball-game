extends RigidBody2D

var planet_name = "Uranus"
var planet_speed = 400.0
var planet_health = 100.0

func _ready():
	var random_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	linear_velocity = random_direction * planet_speed
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):    
	if body is RigidBody2D:
		var damage_taken = body.mass * 10 
		planet_health -= damage_taken
		
		print(planet_name + " was hit! Health: " + str(planet_health))
		
		if planet_health <= 0:
			print(planet_name + " was destroyed!")
			queue_free()
