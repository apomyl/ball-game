extends RigidBody2D

# --- PLANET SETTINGS ---
@export var planet_name: String = "Earth"
@export var planet_speed: float = 600.0
@export var max_health: float = 100.0 
@export var radius: float = 180.0

# --- MOON SETTINGS ---
@export var moon_orbit_speed: float = 2.0
@export var moon_damage: float = 10.0 
@export var moon_knockback: float = 2000.0 

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0

@onready var pivot = $MoonPivot
@onready var hitbox = $weaponhitbox

# UPDATED PATH: This matches your exact hierarchy in the screenshot
@onready var damage_detector = $MoonPivot/Moon/Area2D

func _ready():
	current_health = max_health
	randomize()
	
	# 1. Connect the Area2D inside the Moon for damage/physics
	if damage_detector:
		damage_detector.body_entered.connect(_on_moon_hit_detected)
		print("System: Moon Damage Detector Active")
	
	# 2. Connect the Weapon Hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_weapon_hitbox_body_entered)

	# Initial launch
	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	linear_velocity = random_dir * planet_speed

func _physics_process(delta):
	if pivot:
		pivot.rotation += moon_orbit_speed * delta
	queue_redraw()

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

func _integrate_forces(state):
	# Maintain orbital speed momentum
	if state.linear_velocity.length() > 0:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = 0.5 

func _draw():
	# Weapon Arc
	var arc_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(0.88, 0.0, 0.774, 0.4)
	draw_arc(Vector2.ZERO, radius + 15, deg_to_rad(-90), deg_to_rad(90), 32, arc_color, 10.0)
	
	# Health Bar
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_pos = Vector2(-75, -radius - 70) 
	draw_rect(Rect2(bar_pos, Vector2(150, 15)), Color.BLACK)
	draw_rect(Rect2(bar_pos, Vector2(150 * hp_pct, 15)), Color.GREEN.lerp(Color.RED, 1.0 - hp_pct))

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.2
	if current_health <= 0:
		queue_free()

func apply_hit_stop():
	Engine.time_scale = 0.03
	# Wait for 0.08 seconds in real-time
	await get_tree().create_timer(0.03, true, false, true).timeout
	Engine.time_scale = 1.0

# --- SIGNAL HANDLERS ---

func _on_moon_hit_detected(body):
	# Ignore self and non-damageable objects
	if body == self or not body.has_method("take_damage"):
		return

	print("!!! HYBRID MOON STRIKE ON: ", body.name, " !!!")
	
	# 1. Apply Damage
	body.take_damage(moon_damage)
	
	# 2. Impact Feel
	flash_timer = 0.2
	apply_hit_stop()
	
	# 3. Physics Launch (The 'Bouncing' Force)
	if body is RigidBody2D:
		# Calculate vector from Earth Center -> Target
		var push_dir = (body.global_position - global_position).normalized()
		
		# Clear current speed so the punch feels clean
		body.linear_velocity = Vector2.ZERO 
		body.apply_central_impulse(push_dir * moon_knockback)

func _on_weapon_hitbox_body_entered(body):
	if body != self and body.has_method("take_damage"):
		body.take_damage(20)
