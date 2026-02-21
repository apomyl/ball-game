extends RigidBody2D

@export var planet_name: String = "Planet"
@export var planet_speed: float = 1200.0
@export var max_health: float = 150.0
@export var rotation_speed: float = 3.0

var current_health: float
var flash_timer: float = 0.0

func _ready():
	current_health = max_health
	randomize() 
	
	# 1. SETUP PHYSICS VIA CODE (The "Safety Net")
	contact_monitor = true
	max_contacts_reported = 5
	collision_layer = 1
	collision_mask = 1
	
	# 2. FIND AND CONNECT THE HITBOX AUTOMATICALLY
	var hitbox = get_node_or_null("weaponhitbox")
	if hitbox:
		# Force the hitbox to look at Layer 1
		hitbox.collision_layer = 0 # It doesn't need to be hit
		hitbox.collision_mask = 1  # It MUST look at Layer 1
		
	else:
		push_error("Error: Could not find a node named 'weaponhitbox' under ", name)

	# 3. SET INITIAL VELOCITY
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed
	
	# Enable physics collision reporting
	contact_monitor = true
	max_contacts_reported = 5
	
	# Connect the RIGIDBODY'S collision signal, not just the Area2D
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta
		queue_redraw()

func _draw():
	# 1. Visual indicator of the damage zone (Radius at 200)
	var radius = 90
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.916, 0.0, 0.694, 0.4)
	draw_arc(Vector2.ZERO, radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 6.0)
	
	# 2. Simple Health Bar
	var hp_pct = current_health / max_health
	
	# Settings for the bar
	var bar_width = 120
	var bar_height = 12
	# We position it at -240 so it clears the 200px radius of the planet
	var bar_pos = Vector2(-bar_width / 2, -radius - 40) 
	
	# Draw Background (Black)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	
	# Draw Health (Green/Red)
	# We use clamp to ensure the bar doesn't go "negative" if damage exceeds HP
	var current_width = bar_width * clamp(hp_pct, 0.0, 1.0)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	
	draw_rect(Rect2(bar_pos, Vector2(current_width, bar_height)), health_color)

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	print(name, " took damage! Remaining HP: ", current_health)
	
	if current_health <= 0:
		print(name, " was destroyed!")
		queue_free()
		
func _on_body_entered(body):
	if body.has_method("take_damage"):
		var hitbox = get_node("weaponhitbox")
		
		# check if the body we just physically hit is ALSO overlapping our weapon rectangle
		if hitbox.overlaps_body(body):
			print("CRITICAL HIT: Physics collision inside Weapon Zone!")
			body.take_damage(5 + (150 - current_health)/5)
			# Add a little extra 'oomph' or screen shake here
		else:
			print("Normal Bump: Hit outside of weapon zone.")
