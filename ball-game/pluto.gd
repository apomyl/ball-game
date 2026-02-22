extends RigidBody2D

# --- PLUTO SETTINGS ---
@export var planet_name: String = "Pluto"
@export var planet_speed: float = 2000.0
@export var max_health: float = 300.0
@export var rotation_speed: float = 4.0
@export var radius: float = 90.0
@export var damage_multiplier: float = 0.0001 # Balanced for 1000+ speeds

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0

@onready var hitbox = $weaponhitbox

func _ready():
	current_health = max_health
	randomize() 
	
	# 1. SETUP PHYSICS
	contact_monitor = true
	max_contacts_reported = 5
	
	# 2. AUTO-CONNECT
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1 
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# 3. INITIAL VELOCITY
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed

func _physics_process(delta):
	queue_redraw()

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

func _integrate_forces(state):
	# Keep Pluto at its high constant speed
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _draw():
	var arc_radius = radius + 20
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.88, 0.767, 0.776, 1.0)
	
	# Drawing the offset arc
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 6.0)
	
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

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		get_tree().change_scene_to_file("res://ui/powerups/power1.tscn")

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# --- THE DYNAMIC DAMAGE LOGIC ---
func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		
		if hitbox and hitbox.overlaps_body(body):
			# CALCULATE DAMAGE BASED ON PLUTO'S STATS
			var my_speed = linear_velocity.length()
			
			# Energy = Pluto's Mass * Pluto's Speed Squared
			var impact_energy = (mass * (my_speed ** 2))
			var calculated_damage = impact_energy * damage_multiplier
			
			calculated_damage = clamp(calculated_damage, 10.0, 60.0)
			
			print("PLUTO SELF-POWERED HIT! Damage: ", int(calculated_damage))
			
			body.take_damage(calculated_damage + (max_health-current_health)/10)
			apply_hit_stop(0.08)
			flash_timer = 0.2
			
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				# Knockback still scales with your speed for that 'oomph'
				body.apply_central_impulse(push_dir * (my_speed * 1.5)) 
		else:
			body.take_damage(2)
