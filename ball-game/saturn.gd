extends RigidBody2D

# --- SATURN SETTINGS ---
@export var planet_name: String = "Saturn"
@export var planet_speed: float = 700.0
@export var max_health: float = 300.0
@export var rotation_speed: float = 1.5
@export var radius: float = 260.0
@export var damage_multiplier: float = 0.0001 

@export var ring_slow_factor: float = 0.5
@export var ring_damage_per_second: float = 3.0
@export var ring_inner_radius: float = 290.0 
@export var ring_outer_radius: float = 420.0

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0
var affected_planets = {} 

@onready var hitbox = $weaponhitbox
@onready var ring_area = $Area2D

func _ready():
	current_health = max_health
	randomize() 
	contact_monitor = true
	max_contacts_reported = 5
	
	if ring_area:
		ring_area.body_entered.connect(_on_ring_entered)
		ring_area.body_exited.connect(_on_ring_exited)
	
	if hitbox:
		hitbox.collision_layer = 0
		hitbox.collision_mask = 1 
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta
	
	for body in affected_planets.keys():
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(ring_damage_per_second * delta)

func _physics_process(_delta):
	queue_redraw()

func _integrate_forces(state):
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _draw():
	# --- TEXTURED RING DRAWING LOGIC ---
	
	# Palette: Sandy, Tan, and Cream tones
	var base_tan = Color(0.92, 0.87, 0.75)
	var shadow_tan = Color(0.75, 0.70, 0.60)
	var highlight_cream = Color(1.0, 0.95, 0.85)
	
	var total_span = ring_outer_radius - ring_inner_radius
	var inner_end = ring_inner_radius + (total_span * 0.65)
	var outer_start = inner_end + (total_span * 0.05) # The Gap
	
	# 1. INNER RING MICRO-BANDS (Textured Section)
	var inner_sub_bands = 14
	var inner_width = inner_end - ring_inner_radius
	var inner_step = inner_width / inner_sub_bands
	
	for i in range(inner_sub_bands):
		var current_r = ring_inner_radius + (i * inner_step) + (inner_step / 2.0)
		
		# Alternating colors and alphas to create 'grooves'
		var color_mix = base_tan
		if i % 3 == 0: color_mix = highlight_cream
		elif i % 2 == 0: color_mix = shadow_tan
		
		# Maintain high transparency (0.05 to 0.2 range)
		var alpha = 0.08 + (sin(i * 1.5) * 0.05)
		color_mix.a = clamp(alpha, 0.04, 0.18)
		
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 128, color_mix, inner_step)

	# 2. OUTER RING MICRO-BANDS (Textured Section)
	var outer_sub_bands = 8
	var outer_width = ring_outer_radius - outer_start
	var outer_step = outer_width / outer_sub_bands
	
	for j in range(outer_sub_bands):
		var current_r = outer_start + (j * outer_step) + (outer_step / 2.0)
		
		var color_mix = base_tan
		if j % 2 == 0: color_mix = shadow_tan
		
		# Outer rings are usually even more faint
		var alpha = 0.05 + (cos(j * 2.0) * 0.03)
		color_mix.a = clamp(alpha, 0.03, 0.12)
		
		draw_arc(Vector2.ZERO, current_r, 0, TAU, 128, color_mix, outer_step)

	# --- UI & ARCS ---
	var arc_radius = radius + 20
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(1, 0.8, 0.4, 0.4)
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)
	
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = 200
	var bar_pos = Vector2(-bar_width / 2, -arc_radius - 60) 
	
	draw_rect(Rect2(bar_pos, Vector2(bar_width, 15)), Color.BLACK)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, 15)), health_color)

# --- LOGIC REMAINS UNCHANGED ---
func _on_ring_entered(body):
	if body != self and "planet_speed" in body:
		affected_planets[body] = body.planet_speed
		body.planet_speed *= ring_slow_factor

func _on_ring_exited(body):
	if body in affected_planets:
		body.planet_speed = affected_planets[body]
		affected_planets.erase(body)

func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		if hitbox and hitbox.overlaps_body(body):
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var calculated_damage = clamp(impact_energy * damage_multiplier, 15.0, 80.0)
			
			body.take_damage(calculated_damage + (max_health-current_health)/5)
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
		for body in affected_planets:
			if is_instance_valid(body): body.planet_speed = affected_planets[body]
		get_tree().change_scene_to_file("res://ui/powerups/power1.tscn")

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
