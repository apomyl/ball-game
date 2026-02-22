extends StaticBody2D

# --- SUN SETTINGS ---
@export var planet_name: String = "Sun"
@export var max_health: float = 10000.0 
@export var radius: float = 1000.0      
@export var burn_damage: float = 30.0  
@export var burn_radius: float = 1500.0 
@export var rotation_speed: float = 0.5 

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0
var affected_planets = [] 

@onready var heat_area = $Area2D 

func _ready():
	current_health = max_health
	if heat_area:
		heat_area.body_entered.connect(_on_heat_entered)
		heat_area.body_exited.connect(_on_heat_exited)

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta
	
	# Rotate the sun (The surface and corona will spin)
	rotation += rotation_speed * delta
	
	queue_redraw()
	
	for body in affected_planets:
		if is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(burn_damage * delta)

func _draw():
	# --- 1. SPINNING VISUALS (Corona & Surface) ---
	# These will rotate because they are drawn relative to the node
	var time = Time.get_ticks_msec() / 1000.0
	for i in range(6):
		var layer_pulse = sin(time * 2.0 + i) * 30.0
		var current_r = lerp(radius, burn_radius, float(i + 1) / 6.0) + layer_pulse
		var alpha = lerp(0.2, 0.02, float(i) / 6.0)
		draw_circle(Vector2.ZERO, current_r, Color(1.0, 0.6, 0.0, alpha))
	
	var surface_color = Color(1, 1, 1, 1) if flash_timer > 0 else Color(1.0, 0.9, 0.0, 0.8)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 128, surface_color, 20.0)
	
	# --- 2. STABILIZED BOSS HEALTH BAR (SCREEN SPACE) ---
	# We use draw_set_transform to cancel out the Sun's rotation for the UI
	draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE)
	
	var inv = get_canvas_transform().affine_inverse()
	var screen_size = get_viewport_rect().size
	var scale_factor = inv.get_scale().x
	
	# Bar Dimensions
	var bar_width = screen_size.x * 0.8 * scale_factor
	var bar_height = 30 * scale_factor
	
	# Position Calculation
	var screen_top_center = inv * Vector2(screen_size.x / 2, 80)
	var bar_pos = screen_top_center - Vector2(bar_width / 2, 0)

	# Draw Background
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0, 0, 0, 0.7))
	
	# Draw Health Fill
	var hp_pct = clamp(float(current_health) / float(max_health), 0.0, 1.0)
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, bar_height)), health_color)
	
	# Reset transform so subsequent frames don't stack rotations
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

# --- SIGNALS & DAMAGE ---
func _on_heat_entered(body):
	if body != self and not body in affected_planets:
		affected_planets.append(body)

func _on_heat_exited(body):
	if body in affected_planets:
		affected_planets.erase(body)

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		get_tree().change_scene_to_file("res://ui/winning_scene.tscn")
