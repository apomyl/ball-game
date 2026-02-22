extends RigidBody2D

# --- PLANET STATS ---
@export var planet_name: String = "Mars"
@export var planet_speed: float = 400.0
@export var max_health: float = 100.0
@export var rotation_speed: float = 2.0 
@export var radius: float = 180.0 # Standardized radius
@export var damage_multiplier: float = 0.00015 # Tuned for Mars' speed

var current_health: float
var flash_timer: float = 0.0

# --- SHOOTING STATS ---
var meteor_scene = preload("res://planets/meteor.tscn") 
var shoot_cooldown: float = 2.0 
var shoot_timer: float = 0.0

func _ready():
	current_health = max_health
	randomize()
	
	# 1. SETUP PHYSICS
	contact_monitor = true
	max_contacts_reported = 5
	
	# 2. HITBOX SETUP
	var hitbox = get_node_or_null("WeaponHitbox")
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1 
	
	# 3. INITIAL VELOCITY
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta
		queue_redraw()

	shoot_timer += delta
	if shoot_timer >= shoot_cooldown:
		shoot_timer = 0.0
		shoot_volcano()

# --- DRAWING (With Saturn-style offset arc) ---
func _draw():
	# Use an offset so the arc floats slightly off the planet
	var arc_radius = radius + 20
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(1, 0.4, 0.0, 0.4) # Martian Orange
	
	# Damage zone arc
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 8.0)
	
	# Health Bar
	# Using float() ensures the division results in a decimal (0.0 to 1.0)
	var hp_pct = clamp(float(current_health) / float(max_health), 0.0, 1.0)
	var bar_width = 100
	var bar_height = 10 # Use this variable in the rects below
	var bar_pos = Vector2(-bar_width / 2, -radius - 50) 

	# Draw Background (Black)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)

	# Draw Health (Green to Red Lerp)
	# 1.0 - hp_pct means: at 100% health, weight is 0 (Green). At 0% health, weight is 1 (Red).
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, bar_height)), health_color)

func _integrate_forces(state):
	if state.linear_velocity.length() > 0:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func shoot_volcano():
	var new_meteor = meteor_scene.instantiate()
	get_tree().current_scene.add_child.call_deferred(new_meteor)
	
	var forward_direction = linear_velocity.normalized()
	if forward_direction == Vector2.ZERO: forward_direction = Vector2(1, 0)
		
	new_meteor.global_position = global_position + (forward_direction * 60.0)
	new_meteor.add_collision_exception_with(self)
	new_meteor.linear_velocity = forward_direction * 1500.0

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		queue_free()
		
# --- UPDATED DYNAMIC DAMAGE LOGIC ---
func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		var hitbox = get_node_or_null("WeaponHitbox")
		
		if hitbox and hitbox.overlaps_body(body):
			# CALCULATE DAMAGE BASED ON MARS' OWN STATS
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var calculated_damage = impact_energy * damage_multiplier
			
			# Clamp damage for balance
			calculated_damage = clamp(calculated_damage, 10.0, 60.0)
			
			print("MARS KINETIC STRIKE! Damage: ", int(calculated_damage))
			body.take_damage(calculated_damage)
			
			apply_hit_stop(0.06)
			flash_timer = 0.2
			
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				body.apply_central_impulse(push_dir * 1000.0)
		else:
			# Normal chip damage for side-bumps
			body.take_damage(2)
