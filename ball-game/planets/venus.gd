extends RigidBody2D

# --- VENUS SETTINGS ---
@export var planet_name: String = "Venus"
@export var planet_speed: float = 600.0
@export var max_health: float = 300.0
@export var radius: float = 180.0
@export var damage_multiplier: float = 0.0001 

# --- ACID CLOUD SETTINGS ---
# Make sure this matches the CollisionShape2D radius of your Area2D!
@export var acid_cloud_radius: float = 450.0 
@export var acid_tick_rate: float = 0.5 # Applies damage every 0.5 seconds
@export var acid_damage_per_tick: float = 8.0 # Damage dealt per tick

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0
var affected_planets = {} # Tracks who is in the cloud and their DoT timers

@onready var hitbox = $weaponhitbox
@onready var acid_area = $Area2D # Looks for the exact name "Area2D"

func _ready():
	current_health = max_health
	contact_monitor = true
	max_contacts_reported = 32
	
	# AUTO-FIX IMAGE LAYERING
	var img = get_node_or_null("Image")
	if img: img.show_behind_parent = true
	
	# Connect the acid cloud signals automatically
	if acid_area:
		acid_area.body_entered.connect(_on_acid_entered)
		acid_area.body_exited.connect(_on_acid_exited)
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	await get_tree().physics_frame
	linear_velocity = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * planet_speed

func _process(delta):
	if flash_timer > 0: 
		flash_timer -= delta
	
	var dead_planets = []
	
	# --- ACID DoT LOOP ---
	for body in affected_planets.keys():
		if is_instance_valid(body):
			var data = affected_planets[body]
			data["tick_timer"] -= delta
			
			# If it's time to take acid damage
			if data["tick_timer"] <= 0:
				data["tick_timer"] = acid_tick_rate # Reset timer
				
				# Deal the acid damage!
				if body.has_method("take_damage"):
					body.take_damage(acid_damage_per_tick)
					
				# Flash them bright green briefly to show they took poison damage
				body.modulate = Color(0.2, 1.0, 0.2, 1.0)
				
				# Reset them back to a sickly green tint after a tiny delay
				get_tree().create_timer(0.1).timeout.connect(func():
					if is_instance_valid(body) and body in affected_planets:
						body.modulate = Color(0.6, 0.9, 0.3, 1.0) # Sickly green tint
				)
		else:
			# Planet died, queue for removal from our dictionary
			dead_planets.append(body)
			
	# Cleanup dead planets so we don't cause errors
	for dead in dead_planets:
		affected_planets.erase(dead)

func _physics_process(_delta):
	# Forces Godot to redraw the healthbar and clouds every frame
	queue_redraw()

func _integrate_forces(state):
	if state.linear_velocity.length() < 10.0:
		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		state.linear_velocity = random_dir * planet_speed
	else:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = 2.0 

# ==========================================
# DRAWING (Acid Cloud, Arc, Healthbar)
# ==========================================
func _draw():
	# 1. DRAW THE ACID CLOUD (Background)
	var cloud_color = Color(0.4, 0.9, 0.1, 0.08) # Toxic yellowish-green
	for i in range(8):
		var r = radius + (acid_cloud_radius - radius) * (i / 7.0)
		draw_circle(Vector2.ZERO, r, cloud_color)
	
	# 2. DRAW RAMMING ARC (Spins with planet)
	var arc_radius = radius + 20
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.6, 0.9, 0.1, 0.6)
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)

	# 3. DRAW HEALTHBAR ABOVE (Non-spinning)
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_w = radius * 1.5
	var bar_h = 12
	
	# Calculate a static "Top" position even while spinning
	var bar_pos_vertical = Vector2(-bar_w / 2, -radius - 60) 
	var bar_offset = bar_pos_vertical.rotated(-rotation) 

	# Force the UI to stay upright
	draw_set_transform(bar_offset, -rotation, Vector2.ONE)
	
	# Draw Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_w, bar_h)), Color.BLACK)
	# Draw Health
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_w * hp_pct, bar_h)), health_color)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# ==========================================
# ACID CLOUD LOGIC
# ==========================================
func _on_acid_entered(body):
	# Only affect things that can take damage, and don't melt ourselves!
	if body != self and body.has_method("take_damage"):
		if not body in affected_planets:
			# Store their original color so we can restore it later
			var orig_color = Color.WHITE
			if "modulate" in body:
				orig_color = body.modulate
				
			affected_planets[body] = {
				"tick_timer": acid_tick_rate, # Start timer
				"orig_color": orig_color
			}
			# Give them a sickly green tint
			body.modulate = Color(0.6, 0.9, 0.3, 1.0)

func _on_acid_exited(body):
	if body in affected_planets:
		# Restore their original color when they escape the cloud
		body.modulate = affected_planets[body]["orig_color"]
		affected_planets.erase(body)

# ==========================================
# CORE COLLISION LOGIC
# ==========================================
func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		if hitbox and hitbox.overlaps_body(body):
			
			var my_energy = mass * (linear_velocity.length() ** 2)
			var damage = clamp(my_energy * damage_multiplier, 10.0, 60.0)
			
			if body is RigidBody2D:
				var dir = (body.global_position - global_position).normalized()
				body.apply_central_impulse(dir * 1200.0)
			
			body.take_damage(damage)
			flash_timer = 0.2
			apply_hit_stop(0.08)
		else:
			# Minor side bump damage
			body.take_damage(2.0)

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

func take_damage(amount):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		# CLEANUP: If Venus dies, cure all planets of the acid!
		for b in affected_planets.keys():
			if is_instance_valid(b): 
				b.modulate = affected_planets[b]["orig_color"]
		get_tree().change_scene_to_file("res://ui/powerups/power1.tscn")
