extends RigidBody2D

# --- PLANET SETTINGS ---
@export var planet_name: String = "Earth"
@export var planet_speed: float = 500.0
@export var max_health: float = 300.0 
@export var radius: float = 190.0
@export var damage_multiplier: float = 0.0001 # Tune this to scale difficulty

# --- MOON SETTINGS ---
@export var moon_orbit_speed: float = 2.0
@export var moon_knockback: float = 2000.0 
@export var moon_damage: float = 5.0

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0

@onready var pivot = $MoonPivot
@onready var hitbox = $weaponhitbox
@onready var damage_detector = $MoonPivot/Moon/Area2D

func _ready():
	current_health = max_health
	randomize()
	
	if damage_detector:
		damage_detector.body_entered.connect(_on_moon_hit_detected)
	
	if hitbox:
		hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)

	await get_tree().physics_frame
	linear_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * planet_speed

func _physics_process(delta):
	if pivot:
		pivot.rotation += moon_orbit_speed * delta
	queue_redraw()

# Update this function in your Earth script
func _on_moon_hit_detected(body):
	if body == self or not body.has_method("take_damage"):
		return

	# 1. USE FLAT DAMAGE
	# We use the moon_damage variable from the top of the script
	# This ensures the damage is predictable and fair.
	var final_damage = moon_damage
	
	# OPTIONAL: If you want it to scale ONLY with mass (not speed):
	# final_damage = moon_damage * body.mass 

	print("Moon Strike on ", body.name, " | Damage: ", final_damage)
	
	# 2. Apply Damage & Effects
	body.take_damage(final_damage)
	flash_timer = 0.2
	apply_hit_stop()
	
	# 3. KEEP THE PHYSICS (The Smack)
	if body is RigidBody2D:
		# We still want the bounce to feel good, so we keep the knockback logic
		var push_dir = (body.global_position - global_position).normalized()
		body.linear_velocity = Vector2.ZERO 
		body.apply_central_impulse(push_dir * moon_knockback)

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.2
	if current_health <= 0:
		queue_free()

# --- REMAINING BOILERPLATE ---
func apply_hit_stop():
	Engine.time_scale = 0.05
	await get_tree().create_timer(0.08, true, false, true).timeout
	Engine.time_scale = 1.0

func _on_weapon_hitbox_body_entered(body):
	if body == self or not body.has_method("take_damage"):
		return
		
	# CALCULATE DAMAGE BASED ON EARTH'S STATS
	var self_speed = linear_velocity.length()
	var impact_energy = (mass * (self_speed ** 2))
	var calculated_damage = impact_energy * damage_multiplier
	
	# Clamp to keep gameplay balanced
	calculated_damage = clamp(calculated_damage, 10.0, 60.0)
	
	body.take_damage(calculated_damage)
	apply_hit_stop()
	flash_timer = 0.1
	
	if body is RigidBody2D:
		var push_dir = (body.global_position - global_position).normalized()
		body.apply_central_impulse(push_dir * 800.0)

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

func _integrate_forces(state):
	if state.linear_velocity.length() > 0:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = 0.5 

func _draw():
	var arc_radius = radius + 20 
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.0, 0.574, 0.767, 1.0)
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)
	
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_pos = Vector2(-75, -radius - 70) 
	var bar_width = 100
	var bar_height = 10
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, bar_height)), Color.GOLD.lerp(Color.RED, 1.0 - hp_pct))
