extends RigidBody2D

# --- MERCURY'S STATS ---
@export var planet_name: String = "Mercury"
@export var planet_speed: float = 900.0
@export var max_health: float = 800.0
@export var rotation_speed: float = 6.0
# !!! IMPORTANT: If arcs are inside the planet, INCREASE THIS NUMBER in the Inspector !!!
@export var radius: float = 80.0 

@export var damage_multiplier: float = 0.0001 
@export var combo_damage: float = 40.0 

# Load the visual effects
var fire_effect_scene = preload("res://effectsnstuff/FireEffect.tscn")
var ice_effect_scene = preload("res://effectsnstuff/IceEffect.tscn")
var steam_effect_scene = preload("res://effectsnstuff/SteamEffect.tscn")

# --- INTERNAL STATE ---
var current_health: float
var flash_timer: float = 0.0
var afflicted_targets: Dictionary = {}

func _ready():
	current_health = max_health
	randomize() 
	
	# PHYSICS SETUP
	can_sleep = false 
	contact_monitor = true
	max_contacts_reported = 32 
	
	# AUTO-FIX IMAGE LAYERING: Forces arcs/healthbar to the front
	var img = get_node_or_null("Image")
	if img: img.show_behind_parent = true
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	await get_tree().physics_frame
	var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	linear_velocity = random_dir * planet_speed

func _physics_process(_delta):
	queue_redraw()

func _integrate_forces(state):
	if state.linear_velocity.length() < 10.0:
		var random_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		state.linear_velocity = random_dir * planet_speed
	else:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
	state.angular_velocity = rotation_speed

func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

	var targets_to_remove = []
	for body in afflicted_targets.keys():
		if not is_instance_valid(body):
			targets_to_remove.append(body)
			continue
		var status = afflicted_targets[body]
		
		if status.white_flash_timer > 0:
			status.white_flash_timer -= delta
			if status.white_flash_timer <= 0: update_body_color(body, status)
			continue 

		if status.red_flash_timer > 0:
			status.red_flash_timer -= delta
			if status.red_flash_timer <= 0: update_body_color(body, status)

		if status.ifslowed:
			status.slow_timer -= delta
			if status.slow_timer <= 0:
				remove_effect(body, "ice")
				status.ifslowed = false
				restore_target_speed(body, status)
				update_body_color(body, status)

		if status.onfire:
			status.fire_timer -= delta
			status.fire_tick_timer -= delta
			if status.fire_tick_timer <= 0:
				status.fire_tick_timer = 1.0
				status.red_flash_timer = 0.15
				update_body_color(body, status)
				if body.has_method("take_damage"): body.take_damage(5.0)
			if status.fire_timer <= 0:
				remove_effect(body, "fire")
				status.onfire = false
				update_body_color(body, status)

		if not status.ifslowed and not status.onfire and status.white_flash_timer <= 0:
			targets_to_remove.append(body)

	for body in targets_to_remove:
		afflicted_targets.erase(body)

func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		var local_pos = to_local(body.global_position)
		var hit_ice = local_pos.x < 0
		var hit_fire = local_pos.x >= 0
		
		body.take_damage(clamp((mass * (linear_velocity.length()**2)) * damage_multiplier, 5.0, 50.0))
		flash_timer = 0.2
		apply_hit_stop(0.06)
		
		if body is RigidBody2D:
			body.apply_central_impulse((body.global_position - global_position).normalized() * 800.0)
		
		if hit_ice: apply_ice(body)
		if hit_fire: apply_fire(body)

func initialize_status(body):
	if not afflicted_targets.has(body):
		afflicted_targets[body] = {
			"ifslowed": false, "slow_timer": 0.0,
			"onfire": false, "fire_timer": 0.0, "fire_tick_timer": 1.0,
			"white_flash_timer": 0.0, "red_flash_timer": 0.0,
			"original_color": body.modulate,
			"original_speed": body.get("planet_speed"),
			"original_damp": body.linear_damp if body is RigidBody2D else 0.0,
			"visual_nodes": []
		}

func apply_ice(body):
	initialize_status(body)
	var status = afflicted_targets[body]
	if not status.ifslowed:
		status.ifslowed = true
		status.slow_timer = 4.0
		var ice = ice_effect_scene.instantiate()
		body.add_child(ice)
		status.visual_nodes.append(ice)
		if status.original_speed: body.set("planet_speed", status.original_speed * 0.4)
		update_body_color(body, status)
	check_combo(body, status)

func apply_fire(body):
	initialize_status(body)
	var status = afflicted_targets[body]
	if not status.onfire:
		status.onfire = true
		status.fire_timer = 3.0
		var fire = fire_effect_scene.instantiate()
		body.add_child(fire)
		status.visual_nodes.append(fire)
	check_combo(body, status)

func check_combo(body, status):
	if status.ifslowed and status.onfire:
		status.ifslowed = false
		status.onfire = false
		restore_target_speed(body, status)
		remove_effect(body, "all")
		status.white_flash_timer = 0.15
		update_body_color(body, status)
		body.add_child(steam_effect_scene.instantiate())
		if body.has_method("take_damage"): body.take_damage(combo_damage)

func update_body_color(body, status):
	if not is_instance_valid(body): return
	if status.white_flash_timer > 0: body.modulate = Color(4,4,4,1)
	elif status.red_flash_timer > 0: body.modulate = Color.RED
	elif status.ifslowed: body.modulate = Color(0.4, 0.7, 1.0)
	else: body.modulate = status.original_color

func remove_effect(body, type):
	if not afflicted_targets.has(body): return
	for node in afflicted_targets[body].visual_nodes:
		if is_instance_valid(node): node.queue_free()
	if type == "all": afflicted_targets[body].visual_nodes.clear()

func restore_target_speed(body, status):
	if status.original_speed: body.set("planet_speed", status.original_speed)

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0: 
		get_tree().change_scene_to_file("res://ui/powerups/power1.tscn")

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0

# ==========================================
# DRAWING (SLIGHT GAP FOR ARCS)
# ==========================================
func _draw():
	# 1. DRAW ARCS WITH A GAP
	# If the arcs are still too close, increase the '25' or the 'radius' in Inspector
	var arc_distance = radius + 25 
	
	# Flash white on hit
	var ice_c = Color.WHITE if flash_timer > 0 else Color(0, 0.7, 1.0, 0.6)
	var fire_c = Color.WHITE if flash_timer > 0 else Color(1.0, 0.4, 0.0, 0.6)

	# Right Side (Fire)
	draw_arc(Vector2.ZERO, arc_distance, deg_to_rad(-90), deg_to_rad(90), 32, fire_c, 10.0)
	# Left Side (Ice)
	draw_arc(Vector2.ZERO, arc_distance, deg_to_rad(90), deg_to_rad(270), 32, ice_c, 10.0)

	# 2. DRAW HEALTHBAR ABOVE (Non-spinning)
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_w = radius * 2.0
	var bar_h = 12
	
	# Calculate a static "Top" position even while spinning
	var bar_pos_vertical = Vector2(-bar_w / 2, -radius - 70) # Gap for healthbar too
	var bar_offset = bar_pos_vertical.rotated(-rotation) 

	# Force the UI to stay upright
	draw_set_transform(bar_offset, -rotation, Vector2.ONE)
	
	# Draw Background
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_w, bar_h)), Color.BLACK)
	# Draw Health
	var health_color = Color.GREEN.lerp(Color.RED, 1.0 - hp_pct)
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_w * hp_pct, bar_h)), health_color)
	
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
