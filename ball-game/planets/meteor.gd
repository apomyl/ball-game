extends RigidBody2D

var damage: float = 25.0 

func _on_body_entered(body):
	# Check if the thing we hit is a planet (has health)
	if body.has_method("take_damage"):
		body.take_damage(damage)
		print("Meteor struck " + body.name + "!")
		
		# Now it ONLY deletes itself if it actually hits a planet.
		queue_free() 
		
	# If it hits a wall, it simply does nothing and bounces off!

# This is triggered the exact millisecond the 5-second Timer hits 0
func _on_timer_timeout():
	queue_free() # Deletes the meteor forever so your game doesn't lag
