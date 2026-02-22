extends RigidBody2D

# --- NEPTUNE SETTINGS ---
@export var planet_name: String = "Neptune"
@export var planet_speed: float = 500.0
@export var max_health: float = 250.0
@export var radius: float = 200.0
@export var damage_multiplier: float = 0.0001 

@export var storm_slow_factor: float = 0.3 
@export var storm_radius: float = 400.0
@export var freeze_threshold: float = 1.0 
@export var freeze_duration: float = 5.0

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0
var affected_planets = {} 

@onready var hitbox = $weaponhitbox
@onready var storm_area = $Area2D 

func _ready():
	current_health = max_health
	contact_monitor = true
	max_contacts_reported = 5
	if storm_area:
		storm_area.body_entered.connect(_on_storm_entered)
		storm_area.body_exited.connect(_on_storm_exited)
	
	await get_tree().physics_frame
	linear_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * planet_speed

func _process(delta):
	if flash_timer > 0: flash_timer -= delta
	
	for body in affected_planets.keys():
		if is_instance_valid(body):
			var data = affected_planets[body]
			if data["is_frozen"]:
				data["thaw_timer"] -= delta
				if data["thaw_timer"] <= 0:
					_unfreeze_planet(body)
			else:
				data["accel_timer"] += delta
				if data["accel_timer"] >= freeze_threshold:
					_start_freeze(body)

func _physics_process(_delta):
	queue_redraw()

func _integrate_forces(state):
	if planet_speed > 0:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	else:
		state.linear_velocity = Vector2.ZERO
	state.angular_velocity = 1.0

func _draw():
	# 1. DRAW THE ICY ATMOSPHERE (The "Storm")
	# Using multiple rings to create a soft glow effect
	var storm_color = Color(0.4, 0.8, 1.0, 0.05) 
	for i in range(8):
		var r = radius + (storm_radius - radius) * (i / 7.0)
		draw_circle(Vector2.ZERO, r, storm_color)
	
	var arc_radius = radius + 20
	
	# 2. HEALTH BAR (Green to Red)
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = 150
	var bar_pos = Vector2(-bar_width / 2, -arc_radius - 50) 
	draw_rect(Rect2(bar_pos, Vector2(bar_width, 12)), Color.BLACK)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, 12)), health_color)
	
	# 3. DAMAGE ARC
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.2, 0.6, 1.0, 0.4)
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 8.0)

	# 4. FREEZE PROGRESS INDICATORS
	for body in affected_planets.keys():
		if is_instance_valid(body) and not affected_planets[body]["is_frozen"]:
			var prog = affected_planets[body]["accel_timer"] / freeze_threshold
			var rel_pos = body.global_position - global_position
			draw_arc(rel_pos, 110, 0, TAU * prog, 32, Color.CYAN, 4.0)

# --- FREEZE LOGIC ---

func _start_freeze(body):
	var data = affected_planets[body]
	data["is_frozen"] = true
	data["thaw_timer"] = freeze_duration 
	
	body.planet_speed = 0
	body.linear_velocity = Vector2.ZERO
	body.modulate = Color(0.3, 0.6, 2.0, 1.0) 

func _unfreeze_planet(body):
	if not is_instance_valid(body) or not body in affected_planets: return
	
	body.modulate = Color.WHITE 
	var data = affected_planets[body]
	data["is_frozen"] = false
	data["accel_timer"] = 0.0
	
	if storm_area.get_overlapping_bodies().has(body):
		body.planet_speed = data["orig_speed"] * storm_slow_factor
	else:
		body.planet_speed = data["orig_speed"]
		affected_planets.erase(body)
		
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	body.linear_velocity = random_dir * body.planet_speed

func _on_storm_entered(body):
	if body != self and "planet_speed" in body:
		if not body in affected_planets:
			affected_planets[body] = {
				"orig_speed": body.planet_speed, 
				"accel_timer": 0.0, 
				"is_frozen": false,
				"thaw_timer": 0.0
			}
			body.planet_speed *= storm_slow_factor

func _on_storm_exited(body):
	if body in affected_planets:
		if affected_planets[body]["is_frozen"]:
			return 
		
		body.planet_speed = affected_planets[body]["orig_speed"]
		affected_planets.erase(body)

func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		if hitbox.overlaps_body(body):
			var my_energy = mass * (linear_velocity.length() ** 2)
			var damage = clamp(my_energy * damage_multiplier, 10.0, 60.0)
			
			if body in affected_planets and affected_planets[body]["is_frozen"]:
				damage *= 2.0
				_shatter_hit(body)
			else:
				if body is RigidBody2D:
					var dir = (body.global_position - global_position).normalized()
					body.apply_central_impulse(dir * 1000.0)
			
			body.take_damage(damage)
			flash_timer = 0.2
			apply_hit_stop(0.08)

func _shatter_hit(body):
	if body is RigidBody2D and body in affected_planets:
		body.modulate = Color.WHITE
		var data = affected_planets[body]
		var final_speed = data["orig_speed"]
		affected_planets.erase(body) 
		
		body.planet_speed = final_speed
		var push_dir = (body.global_position - global_position).normalized()
		body.linear_velocity = push_dir * 1800.0 
		body.apply_central_impulse(push_dir * 500.0)

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func take_damage(amount):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		for b in affected_planets.keys():
			if is_instance_valid(b): 
				b.planet_speed = affected_planets[b]["orig_speed"]
				b.modulate = Color.WHITE
		queue_free()
