extends RigidBody2D

# --- SATURN SETTINGS ---
@export var planet_name: String = "Saturn"
@export var planet_speed: float = 400.0  # Saturn is a bit slower/sturdier
@export var max_health: float = 300.0
@export var rotation_speed: float = 1.5
@export var radius: float = 260.0
@export var damage_multiplier: float = 0.0001 

@export var ring_slow_factor: float = 0.4 # Reduces speed to 40%
@export var ring_inner_radius: float = 180.0
@export var ring_outer_radius: float = 450.0

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0
var affected_planets = {} # Stores {body: original_speed}

@onready var hitbox = $weaponhitbox
@onready var ring_area = $Area2D # The ring area from your screenshot

func _ready():
	current_health = max_health
	randomize() 
	
	# 1. SETUP PHYSICS
	contact_monitor = true
	max_contacts_reported = 5
	
	# 2. CONNECT RING SIGNALS
	if ring_area:
		ring_area.body_entered.connect(_on_ring_entered)
		ring_area.body_exited.connect(_on_ring_exited)
	
	# 3. WEAPON CONNECTION
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1 
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# 4. INITIAL VELOCITY
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed

func _physics_process(delta):
	queue_redraw()

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _draw():
	# 1. Draw Saturn's Rings (Visual Only)
	var ring_color = Color(0.8, 0.7, 0.5, 0.3) # Dusty Beige
	# Inner ring line
	draw_arc(Vector2.ZERO, ring_inner_radius, 0, TAU, 64, ring_color, 15.0)
	# Main ring body
	draw_arc(Vector2.ZERO, (ring_inner_radius + ring_outer_radius)/2, 0, TAU, 64, Color(0.8, 0.7, 0.5, 0.15), 80.0)
	# Outer ring line
	draw_arc(Vector2.ZERO, ring_outer_radius, 0, TAU, 64, ring_color, 5.0)

	# 2. Weapon Arc (Front)
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(1, 0.8, 0.4, 0.4)
	draw_arc(Vector2.ZERO, radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)
	
	# 3. Health Bar
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = 200
	var bar_height = 15
	var bar_pos = Vector2(-bar_width / 2, -radius - 30) 
	
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, bar_height)), Color.GOLD.lerp(Color.RED, 1.0 - hp_pct))

# --- RING SLOWDOWN LOGIC ---

func _on_ring_entered(body):
	# Check if it's a planet with a 'planet_speed' variable
	if body != self and "planet_speed" in body:
		print("Planet entered Saturn's rings: ", body.name)
		# Save original speed and apply slow
		affected_planets[body] = body.planet_speed
		body.planet_speed *= ring_slow_factor

func _on_ring_exited(body):
	if body in affected_planets:
		print("Planet exited Saturn's rings: ", body.name)
		# Restore original speed from dictionary
		body.planet_speed = affected_planets[body]
		affected_planets.erase(body)

# --- DYNAMIC DAMAGE LOGIC ---

func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		if hitbox and hitbox.overlaps_body(body):
			# SELF-POWERED KINETIC DAMAGE
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var calculated_damage = (impact_energy * damage_multiplier) + (max_health - current_health)/5
			
			calculated_damage = clamp(calculated_damage, 15.0, 80.0)
			
			body.take_damage(calculated_damage)
			apply_hit_stop(0.08)
			flash_timer = 0.2
			
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				body.apply_central_impulse(push_dir * 1200.0)
		else:
			body.take_damage(5)

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		# Restore speeds to all trapped planets before dying
		for body in affected_planets:
			if is_instance_valid(body):
				body.planet_speed = affected_planets[body]
		queue_free()

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
