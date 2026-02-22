extends GPUParticles2D

func _ready():
	# 1. Start the explosion immediately
	emitting = true
	
	# 2. Wait for the particles to finish
	# We wait for 'lifetime' (0.6s) + a little buffer (0.5s) to ensure
	# even the last slow particles have faded out.
	await get_tree().create_timer(lifetime + 0.5).timeout
	
	# 3. Delete this node from the game to free up memory
	queue_free()
