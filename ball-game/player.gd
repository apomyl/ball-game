extends RigidBody2D

# --- PLUTO SETTINGS ---
@export var planet_name: String = "Player"
@export var planet_speed: float = 1000.0
@export var max_health: float = 100.0
@export var rotation_speed: float = 2.5
@export var radius: float = 200.0
@export var damage_multiplier: float = 0.001

# --- POWERUPS (DEATH STAR) ---
var has_death_star: bool = false
var death_star_cooldown: float = 5.0
var death_star_timer: float = 0.0
var laser_scene = preload("res://powerups/DeathLaser.tscn") # Make sure this file exists!

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0

@onready var hitbox = $weaponhitbox

func _ready():
	#scaling the sprites so that the hitboxes fit the sprite while keeping their size
	self.scale = Vector2(1/PlayerDetails.sprite_scale[PlayerDetails.PlanetName], 1/PlayerDetails.sprite_scale[PlayerDetails.PlanetName])
	$Image.texture = load(PlayerDetails.sprite_file_paths[PlayerDetails.PlanetName])
	$Image.scale = Vector2(PlayerDetails.sprite_scale[PlayerDetails.PlanetName], PlayerDetails.sprite_scale[PlayerDetails.PlanetName])
	
	max_health = 100 + (900*PlayerDetails.BaseHealth/1498)
	planet_speed = 500 + (2500*PlayerDetails.Speed/1498)
	mass = 0.5 + (4*PlayerDetails.Mass/1498)
	
	add_powerups()

	current_health = max_health
	randomize() 
	
	# 1. PHYSICS SETUP
	contact_monitor = true
	max_contacts_reported = 5
	
	# 2. AUTO-CONNECT SIGNALS
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	# 3. INITIAL LAUNCH
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed

func _physics_process(_delta):
	queue_redraw()

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

	# --- DEATH STAR LOGIC ---
	if has_death_star:
		death_star_timer -= delta
		if death_star_timer <= 0:
			fire_death_star_laser()
			death_star_timer = death_star_cooldown

func _integrate_forces(state):
	# Forces the planet to always move at its set speed
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _draw():
	# 1. WEAPON ARC
	var arc_radius = radius + 20
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.88, 0.76, 0.77, 1.0)
	draw_arc(Vector2.ZERO, arc_radius, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)
	
	# 2. HEALTH BAR
	var hp_pct = clamp(float(current_health) / float(max_health), 0.0, 1.0)
	var bar_width = radius * 1.2
	var bar_height = 10
	var bar_pos = Vector2(-bar_width / 2, -radius - 50)
	
	# Background
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	# Health Fill (Lerps Green to Red)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, bar_height)), health_color)

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		queue_free()

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# --- CORE COLLISION LOGIC ---

func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		
		# Check if the hit landed in our designated 'Weapon' zone
		if hitbox and hitbox.overlaps_body(body):
			
			# DAMAGE BASED ON YOUR OWN STATS
			var my_speed = linear_velocity.length()
			var impact_energy = (mass * (my_speed ** 2))
			var calculated_damage = impact_energy * damage_multiplier
			
			# Keep damage within a playable range (Adjust as needed)
			calculated_damage = clamp(calculated_damage, 5.0, 50.0)
			
			body.take_damage(calculated_damage)
			apply_hit_stop(0.06)
			flash_timer = 0.2
			
			if body is RigidBody2D:
				var push_dir = (body.global_position - global_position).normalized()
				body.linear_velocity = Vector2.ZERO 
				body.apply_central_impulse(push_dir * 1000.0)
		else:
			# Minor damage for hitting the 'back' or 'sides' of the planet
			body.take_damage(2.0)
	
func add_powerups():
	# Example: If you want to test the Death Star immediately, uncomment the line below
	# has_death_star = true
	pass

# ==========================================
# DEATH STAR POWERUP LOGIC
# ==========================================

func fire_death_star_laser():
	var target = get_nearest_enemy()
	
	if target != null:
		# 1. Create the laser
		var laser = laser_scene.instantiate()
		
		# 2. Set the laser's starting position to our planet
		laser.global_position = global_position
		
		# 3. Tell the laser we are the shooter (so it doesn't hurt us)
		laser.shooter = self 
		
		# 4. Point the laser directly at the target
		var direction = (target.global_position - global_position).normalized()
		laser.rotation = direction.angle()
		
		# 5. Add it to the main game scene safely using call_deferred
		get_tree().current_scene.add_child.call_deferred(laser)
		
		print("FIRING DEATH STAR LASER AT ", target.name, "!")

func get_nearest_enemy() -> Node2D:
	# Looks for all nodes that have been added to the "enemies" group
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var shortest_distance = INF # Start with an infinitely large distance
	
	for enemy in enemies:
		if is_instance_valid(enemy): 
			var distance = global_position.distance_to(enemy.global_position)
			
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_enemy = enemy
				
	return nearest_enemy
