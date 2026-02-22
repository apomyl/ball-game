# IMPORTANT: Change this path to match exactly where you saved your base script!
extends "res://baseplanet.gd"

# --- JUPITER'S STORM STATS ---
# Adjusted these numbers so the wind-up is actually visible over a few seconds!
@export var base_spin: float = 2.0
@export var max_spin: float = 40.0 # Increased max spin so it spins like a buzzsaw!
@export var spin_acceleration: float = 3.0 # Lowered acceleration so it takes time to wind up

# How much damage each "spin point" adds to the final blow
@export var spin_damage_multiplier: float = 2.0 

func _ready():
	# Run the base setup first
	super._ready()
	
	# SAFETY CHECK: Ensure the physics engine isn't locking the rotation
	lock_rotation = false 
	
	planet_name = "Jupiter"
	rotation_speed = base_spin # Start at base speed
	print("HELLO! Jupiter's _ready function is alive!")

func _process(delta):
	# Keep the base drawing and flashing logic running
	super._process(delta)
	
	# THE WIND UP: Constantly accelerate the rotation over time
	rotation_speed += spin_acceleration * delta
	
	# Cap the speed so it doesn't spin out of control
	rotation_speed = clamp(rotation_speed, base_spin, max_spin)

# ---> THE FIX: Actually tell the physics engine to spin the body! <---
func _physics_process(delta):
	angular_velocity = rotation_speed

# OVERRIDING THE COLLISION: Jupiter has its own rules for hitting things
func _on_body_entered(body):
	# Only trigger this on enemies, not walls!
	if body.has_method("take_damage") and body != self:
		
		# Did we hit them with Jupiter's weapon zone?
		if hitbox and hitbox.overlaps_body(body):
			
			# 1. CALCULATE THE STORM DAMAGE
			var bonus_damage = rotation_speed * spin_damage_multiplier
			
			# Base damage from the inherited script's logic (speed & mass)
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var base_damage = clamp(impact_energy * damage_multiplier, 5.0, 50.0)
			
			var total_damage = base_damage + bonus_damage
			print("JUPITER STRIKE! Total Damage: ", total_damage, " (Spin bonus: ", bonus_damage, ")")
			
			# 2. DELIVER THE PAYLOAD
			body.take_damage(total_damage)
			apply_hit_stop(0.15) # An extra-long freeze frame for maximum juice!
			flash_timer = 0.2
			
			# 3. MASSIVE KNOCKBACK
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				body.apply_central_impulse(push_dir * 1800.0) # Shoves them harder than the base script
				
			# 4. THE EXHAUSTION (Reset the spin!)
			print("Jupiter lost its momentum and reset to base spin.")
			rotation_speed = base_spin
			
		else:
			# Minor damage for bumping into them with the "back" of the planet
			body.take_damage(2.0)
