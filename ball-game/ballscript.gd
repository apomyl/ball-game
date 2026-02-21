extends RigidBody2D

# Export variables allow you to change these in the Godot Inspector later!
@export var planet_name: String = "Unknown"
@export var planet_speed: float = 400.0
@export var max_health: float = 100.0

var current_health: float

func _ready():
	current_health = max_health
	
	# Wait for physics engine to boot
	await get_tree().physics_frame
	
	# Shoot in random direction
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	linear_velocity = random_dir * planet_speed

func _process(_delta):
	# Always face the weapon forward (velocity direction)
	if linear_velocity.length() > 0:
		rotation = linear_velocity.angle()

func take_damage(amount: float):
	current_health -= amount
	print(planet_name + " took " + str(amount) + " damage! Health: " + str(current_health))
	
	if current_health <= 0:
		print(planet_name + " was destroyed!")
		queue_free()

# CONNECT THIS from your WeaponHitbox Node -> Node Tab -> Signals
func _on_weapon_hitbox_body_entered(body):
	if body is RigidBody2D and body != self:
		if body.has_method("take_damage"):
			# Deal damage based on THIS planet's mass
			var damage_dealt = mass * 10
			body.take_damage(damage_dealt)
