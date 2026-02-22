extends RigidBody2D

# --- MERCURY'S STATS ---
@export var planet_name: String = "Mercury"
@export var planet_speed: float = 900.0
@export var max_health: float = 800.0
@export var rotation_speed: float = 6.0
@export var radius: float = 40.0 

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
	
	can_sleep = false 
	contact_monitor = true
	max_contacts_reported = 32 
	
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
		if random_dir == Vector2.ZERO: random_dir = Vector2.RIGHT
		state.linear_velocity = random_dir * planet_speed
	else:
		state.linear_velocity = state.linear_velocity.normalized() * planet_speed
		
	state.angular_velocity = rotation_speed

# --- MASTER STATUS EFFECT LOOP ---
func _process(delta):
	if flash_timer > 0:
		flash_timer -= delta

	var targets_to_remove = []

	for body in afflicted_targets.keys():
		if not is_instance_valid(body):
			targets_to_remove.append(body)
			continue

		var status = afflicted_targets[body]

		# 1. WHITE FLASH COMBO
		if status.white_flash_timer > 0:
			status.white_flash_timer -= delta
			if status.white_flash_timer <= 0:
				update_body_color(body, status) # Revert from flash
			continue # Skip other effects during flash

		# 2. RED BURN TICK FLASH
		if status.red_flash_timer > 0:
			status.red_flash_timer -= delta
			if status.red_flash_timer <= 0:
				update_body_color(body, status) # Revert from red tick

		# 3. ICE SLOW
		if status.ifslowed:
			status.slow_timer -= delta
			if status.slow_timer <= 0:
				remove_effect(body, "ice") 
				status.ifslowed = false
				body.set("ifslowed", false) 
				restore_target_speed(body, status)
				update_body_color(body, status) # Color change
				print("❄️ Ice expired on ", body.name)

		# 4. FIRE BURN
		if status.onfire:
			status.fire_timer -= delta
			status.fire_tick_timer -= delta
			
			if status.fire_tick_timer <= 0:
				status.fire_tick_timer = 1.0 
				status.red_flash_timer = 0.15 # Set the red tick flash duration
				update_body_color(body, status) # Instantly turn red
				
				print("🔥 FIRE TICK! Dealt 5 damage to ", body.name)
				if body.has_method("take_damage"):
					body.take_damage(5.0) 
					
			if status.fire_timer <= 0:
				remove_effect(body, "fire") 
				status.onfire = false
				body.set("onfire", false) 
				update_body_color(body, status) # Color change
				print("🔥 Fire expired on ", body.name)

		if not status.ifslowed and not status.onfire and status.white_flash_timer <= 0:
			targets_to_remove.append(body)

	for body in targets_to_remove:
		afflicted_targets.erase(body)


# --- CORE COLLISION LOGIC ---
func _on_body_entered(body):
	if body.has_method("take_damage") and body != self:
		
		var local_pos = to_local(body.global_position)
		var hit_ice = local_pos.x < 0
		var hit_fire = local_pos.x >= 0

		var my_speed = linear_velocity.length()
		var impact_energy = (mass * (my_speed ** 2))
		var calculated_damage = clamp(impact_energy * damage_multiplier, 5.0, 50.0)
		
		body.take_damage(calculated_damage)
		apply_hit_stop(0.06)
		flash_timer = 0.2
		
		if body is RigidBody2D:
			var push_dir = (body.global_position - global_position).normalized()
			if push_dir == Vector2.ZERO: push_dir = Vector2.UP
			body.apply_central_impulse(push_dir * 800.0)

		if hit_ice: apply_ice(body)
		if hit_fire: apply_fire(body)


# ==========================================
# ELEMENTAL SYSTEM & VISUALS
# ==========================================

func initialize_status(body):
	if not afflicted_targets.has(body):
		var o_speed = body.get("planet_speed")
		var o_damp = body.linear_damp if body is RigidBody2D else 0.0

		afflicted_targets[body] = {
			"ifslowed": false,
			"slow_timer": 0.0,
			"onfire": false,
			"fire_timer": 0.0,
			"fire_tick_timer": 1.0,
			"white_flash_timer": 0.0,
			"red_flash_timer": 0.0, # <--- NEW for red tick
			"original_color": body.modulate,
			"original_speed": o_speed,
			"original_damp": o_damp,
			"visual_nodes": [] 
		}

func apply_ice(body):
	initialize_status(body)
	var status = afflicted_targets[body]
	
	if not status.ifslowed:
		status.ifslowed = true
		status.slow_timer = 4.0 
		body.set("ifslowed", true) 

		var ice_instance = ice_effect_scene.instantiate()
		ice_instance.name = "IceVisual"
		body.add_child(ice_instance)
		status.visual_nodes.append(ice_instance)
		
		update_body_color(body, status) # <--- ADDED BLUE HUE

		if status.original_speed != null:
			body.set("planet_speed", status.original_speed * 0.4) 
		elif body is RigidBody2D:
			body.linear_damp = 5.0 

	check_combo(body, status)

func apply_fire(body):
	initialize_status(body)
	var status = afflicted_targets[body]

	if not status.onfire:
		status.onfire = true
		status.fire_timer = 3.0 
		body.set("onfire", true) 
		
		var fire_instance = fire_effect_scene.instantiate()
		fire_instance.name = "FireVisual"
		body.add_child(fire_instance)
		status.visual_nodes.append(fire_instance)

	check_combo(body, status)

func check_combo(body, status):
	if status.ifslowed and status.onfire:
		print("💥 THERMAL SHOCK COMBO!")
		
		status.ifslowed = false
		status.onfire = false
		body.set("ifslowed", false)
		body.set("onfire", false)
		restore_target_speed(body, status)

		remove_effect(body, "all")

		status.white_flash_timer = 0.15 
		update_body_color(body, status) # Trigger white flash

		var steam = steam_effect_scene.instantiate()
		body.add_child(steam)

		if body.has_method("take_damage"):
			body.take_damage(combo_damage)

# NEW HIERARCHICAL COLOR FUNCTION
func update_body_color(body, status):
	if not is_instance_valid(body): return

	# PRIORITY 1: White Flash from Combo
	if status.white_flash_timer > 0:
		body.modulate = Color(4.0, 4.0, 4.0, 1.0) # Glow White
	# PRIORITY 2: Red Tick from Burn
	elif status.red_flash_timer > 0:
		body.modulate = Color.RED
	# PRIORITY 3: Blue Hue from Slow
	elif status.ifslowed:
		body.modulate = Color(0.4, 0.7, 1.0) # Icy Blue
	# PRIORITY 4: Return to normal
	else:
		body.modulate = status.original_color

func remove_effect(body, type):
	if not afflicted_targets.has(body): return
	var status = afflicted_targets[body]
	
	for node in status.visual_nodes:
		if is_instance_valid(node):
			if type == "all" or (type == "ice" and "IceVisual" in node.name) or (type == "fire" and "FireVisual" in node.name):
				node.queue_free()
	
	if type == "all":
		status.visual_nodes.clear()

func restore_target_speed(body, status):
	if status.original_speed != null:
		body.set("planet_speed", status.original_speed)
	elif body is RigidBody2D:
		body.linear_damp = status.original_damp

func _draw():
	var hp_pct = clamp(current_health / max_health, 0.0, 1.0)
	var bar_width = radius * 1.2
	var bar_pos = Vector2(-bar_width / 2, -radius - 30)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, 10)), Color.BLACK)
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_pct, 10)), Color.WHITE.lerp(Color.RED, 1.0 - hp_pct))

func take_damage(amount: float):
	current_health -= amount
	flash_timer = 0.1
	if current_health <= 0:
		clear_effects_before_death() 
		queue_free()

func clear_effects_before_death():
	for body in afflicted_targets.keys():
		if is_instance_valid(body):
			remove_effect(body, "all")
			var status = afflicted_targets[body]
			body.set("ifslowed", false)
			body.set("onfire", false)
			restore_target_speed(body, status)
			body.modulate = status.original_color

func apply_hit_stop(duration: float):
	Engine.time_scale = 0.05
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
