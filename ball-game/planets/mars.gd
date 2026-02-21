extends RigidBody2D

# --- PLANET STATS ---
@export var planet_name: String = "Mars"
@export var planet_speed: float = 400.0
@export var max_health: float = 100.0
@export var rotation_speed: float = 2.0 

var current_health: float
var flash_timer: float = 0.0

# --- SHOOTING STATS ---
# Make sure this path exactly matches where you saved your meteor scene!
var meteor_scene = preload("res://planets/meteor.tscn") 
var shoot_cooldown: float = 2.0 
var shoot_timer: float = 0.0

func _ready():
	current_health = max_health
	
	# 1. SETUP PHYSICS
	contact_monitor = true
	max_contacts_reported = 5
	collision_layer = 1
	collision_mask = 1
	
	# 2. FIND AND CONNECT THE HITBOX 
	# (Check your scene tree: make sure the capitalization matches exactly!)
	var hitbox = get_node_or_null("WeaponHitbox")
	if hitbox:
		hitbox.collision_layer = 0 # It doesn't need to be hit
		hitbox.collision_mask = 1  # It MUST look at Layer 1
	else:
		push_error("Error: Could not find a node named 'WeaponHitbox' under ", name)

	# 3. SET INITIAL VELOCITY
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed
	
	# 4. CONNECT RIGIDBODY COLLISION SIGNAL
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	# 1. VISUAL DAMAGE FLASH LOGIC
	if flash_timer > 0:
		flash_timer -= delta
		queue_redraw() # Tells _draw() to update the screen

	# 2. THE SHOOTING CLOCK
	shoot_timer += delta
	if shoot_timer >= shoot_cooldown:
		shoot_timer = 0.0
		shoot_volcano()

# --- DRAWING THE HEALTH BAR AND HITBOX ARC ---
func _draw():
	# 1. Visual indicator of the damage zone (Radius at 200)
	var radius = 200
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(1, 0, 0, 0.4)
	draw_arc(Vector2.ZERO, radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 6.0)
	
	# 2. Simple Health Bar
	var hp_pct = current_health / max_health
	var bar_width = 120
	var bar_height = 12
	# Position it at -240 so it clears the 200px radius of the planet
	var bar_pos = Vector2(-bar_width / 2, -radius - 40) 
	
	# Draw Background (Black)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	
	# Draw Health (Green/Red)
	var current_width = bar_width * clamp(hp_pct, 0.0, 1.0)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(current_width, bar_height)), health_color)

# --- MOVEMENT PHYSICS ---
func _integrate_forces(state):
	# This constantly forces the planet to move at exactly planet_speed
	# and constantly rotates it like a spinning top
	if state.linear_velocity.length() > 0:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

# --- SHOOTING LOGIC ---
func shoot_volcano():
	print(planet_name + " fired a meteor!")
	
	var new_meteor = meteor_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(new_meteor)
	
	# Since _integrate_forces makes the planet spin rapidly, we shoot in the direction of its movement, not its rotation
	var forward_direction = linear_velocity.normalized()
	if forward_direction == Vector2.ZERO:
		forward_direction = Vector2(1, 0)
		
	new_meteor.global_position = global_position + (forward_direction * 60.0)
	new_meteor.add_collision_exception_with(self)
	new_meteor.linear_velocity = forward_direction * 1500.0

# --- DAMAGE AND COLLISION LOGIC ---
func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1 # Triggers the visual flash
	print(name, " took damage! Remaining HP: ", current_health)
	
	if current_health <= 0:
		print(name, " was destroyed!")
		queue_free()
		
func _on_body_entered(body):
	if body.has_method("take_damage"):
		# Match capitalization with the string in _ready()!
		var hitbox = get_node_or_null("WeaponHitbox")
		
		if hitbox and hitbox.overlaps_body(body):
			print("CRITICAL HIT: Mars slammed into something!")
			body.take_damage(20)
		else:
			print("Normal Bump: Hit outside of weapon zone.")
