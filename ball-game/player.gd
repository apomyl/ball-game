extends RigidBody2D

# --- PLUTO SETTINGS ---
@export var planet_name: String = "Player"
@export var planet_speed: float = 500.0
@export var max_health: float = 500.0
@export var rotation_speed: float = 2.5
@export var radius: float = 90.0
@export var damage_multiplier: float = 0.001

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0

@onready var hitbox = $weaponhitbox

func _ready():
	#scaling the sprites so that the hitboxes fit the sprite while keeping their size
	self.scale = Vector2(1/PlayerDetails.sprite_scale[PlayerDetails.PlanetName], 1/PlayerDetails.sprite_scale[PlayerDetails.PlanetName])
	$Image.texture = load(PlayerDetails.sprite_file_paths[PlayerDetails.PlanetName])
	$Image.scale = Vector2(PlayerDetails.sprite_scale[PlayerDetails.PlanetName], PlayerDetails.sprite_scale[PlayerDetails.PlanetName])

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

func _integrate_forces(state):
	# Forces the planet to always move at its set speed
	state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _draw():
	# Draw a simple health bar
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = radius * 1.2
	var bar_pos = Vector2(-bar_width / 2, -radius - 30)
	
	draw_rect(Rect2(bar_pos, Vector2(bar_width, 10)), Color.BLACK)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, 10)), Color.WHITE.lerp(Color.RED, 1.0 - hp_pct))

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
	pass
	
