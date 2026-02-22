extends RigidBody2D

# --- URANUS SETTINGS ---
@export var planet_name: String = "Uranus"
@export var planet_speed: float = 1100.0 
@export var max_health: float = 300.0    
@export var rotation_speed: float = 4.0  
@export var radius: float = 240.0
@export var damage_multiplier: float = 0.0001 

# --- DASH SETTINGS ---
@export var dash_interval: float = 2.5
@export var dash_boost: float = 50.0 # How much speed increases per dash
var dash_timer: float = 0.0

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0

@onready var hitbox = $weaponhitbox

func _ready():
	current_health = max_health
	randomize() 
	
	contact_monitor = true
	max_contacts_reported = 5
	
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1 
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	await get_tree().physics_frame
	_perform_random_dash()

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta
		
	# --- DASH LOGIC ---
	dash_timer += delta
	if dash_timer >= dash_interval:
		dash_timer = 0.0
		_perform_random_dash()

func _perform_random_dash():
	# Increase velocity slightly
	planet_speed += dash_boost
	# Choose a new random direction
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed
	print(planet_name, " dashed! New Speed: ", planet_speed)

func _physics_process(delta):
	queue_redraw()

func _integrate_forces(state):
	# Forces Uranus to stay at its current (potentially boosted) speed
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _draw():
	var arc_radius = radius + 18
	# Pale Cyan color for Uranus
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.6, 0.9, 1.0, 0.4)
	
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

func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		if hitbox and hitbox.overlaps_body(body):
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var calculated_damage = clamp(impact_energy * damage_multiplier, 10.0, 60.0)
			
			body.take_damage(calculated_damage)
			apply_hit_stop(0.08)
			flash_timer = 0.2
			
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				body.apply_central_impulse(push_dir * (my_speed * 1.5)) 
		else:
			body.take_damage(2)
