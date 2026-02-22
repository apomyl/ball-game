extends RigidBody2D

# --- JUPITER SETTINGS ---
@export var planet_name: String = "Jupiter"
@export var planet_speed: float = 500.0
@export var max_health: float = 400.0
@export var radius: float = 410.0
@export var damage_multiplier: float = 0.0001 # Needed for kinetic calculation

# --- JUPITER'S STORM STATS ---
@export var base_spin: float = 2.0
@export var max_spin: float = 40.0 
@export var spin_acceleration: float = 3.0 
@export var spin_damage_multiplier: float = 1.5 

# --- INTERNAL STATE (Previously inherited, now required) ---
var current_health: float
var flash_timer: float = 0.0
var rotation_speed: float = 0.0

@onready var hitbox = get_node_or_null("weaponhitbox")

func _ready():
	current_health = max_health
	randomize()
	
	# SETUP PHYSICS
	contact_monitor = true
	max_contacts_reported = 5
	lock_rotation = false 
	
	rotation_speed = base_spin 
	
	# Connect collision signal manually
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# INITIAL VELOCITY
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed

func _process(delta):
	# Update flash timer
	if flash_timer > 0:
		flash_timer -= delta
		queue_redraw()
	
	# THE WIND UP
	rotation_speed += spin_acceleration * delta
	rotation_speed = clamp(rotation_speed, base_spin, max_spin)

func _physics_process(_delta):
	# Force velocity and handle the buzzsaw spin
	linear_velocity = linear_velocity.normalized() * planet_speed
	angular_velocity = rotation_speed

# --- HELPER FUNCTIONS (Previously inherited) ---
func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		queue_free()

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# --- UI VISUALS ---
func _draw():
	var arc_radius = radius + 20
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(1.0, 0.4, 0.2, 1.0)
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)
	
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = 220
	var bar_height = 15
	var bar_pos = Vector2(-bar_width / 2, -arc_radius - 60) 
	
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, bar_height)), health_color)

# --- COLLISION ---
func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		if hitbox and hitbox.overlaps_body(body):
			
			var bonus_damage = rotation_speed * spin_damage_multiplier
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var base_damage = clamp(impact_energy * damage_multiplier, 5.0, 50.0)
			
			var total_damage = base_damage + bonus_damage
			body.take_damage(total_damage)
			
			apply_hit_stop(0.15) 
			flash_timer = 0.2
			
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				body.apply_central_impulse(push_dir * 1800.0) 
				
			rotation_speed = base_spin
		else:
			# Resets spin on "Normal Bumps" (side collisions)
			body.take_damage(2.0)
			rotation_speed = base_spin
