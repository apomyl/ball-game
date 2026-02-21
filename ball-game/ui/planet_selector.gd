extends Control

@onready var name_label: RichTextLabel = $Name
@onready var planet_tex: TextureRect = $Planet
@onready var left_btn: TextureButton = $LeftButton
@onready var right_btn: TextureButton = $RightButton
@onready var thumbs: HBoxContainer = $HBoxContainer


var planets := [
{ "name": "Jinzor", "tex": preload("res://assets/exoplanet1.png") },
{ "name": "Pacoria IX", "tex": preload("res://assets/exoplanet2.png") },
{ "name": "Apostis Major", "tex": preload("res://assets/exoplanet3.png") },
{ "name": "Selenara", "tex": preload("res://assets/exoplanet4.png") },
{ "name": "Sangor Prime", "tex": preload("res://assets/exoplanet5.png") },
]

var index: int = 0
var is_animating: bool = false
var thumb_buttons: Array[TextureButton] = []
func _ready() -> void:
	left_btn.pressed.connect(_on_left_pressed)
	right_btn.pressed.connect(_on_right_pressed)
	build_thumbnails()
	apply_planet(index, true)
	
func _on_left_pressed() -> void:
	change_index(-1)
func _on_right_pressed() -> void:
	change_index(1)
	
func build_thumbnails() -> void:
# Clear existing thumbnails
	for c in thumbs.get_children():
		c.queue_free()
	thumb_buttons.clear()
	# Build new
	for i in range(planets.size()):
		var b := TextureButton.new()
		b.texture_normal = planets[i]["tex"]
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.custom_minimum_size = Vector2(140, 90)
		b.focus_mode = Control.FOCUS_NONE
		b.modulate = Color(1, 1, 1, 0.55)
		# IMPORTANT: capture i into a local variable so the lambda uses the correct value
		var idx := i
		b.pressed.connect(func():
			if is_animating:
				return
			animate_to(idx)
			)
		thumbs.add_child(b)
		thumb_buttons.append(b)
		
func change_index(dir: int) -> void:
	if is_animating:
		return
		
	var new_index := (index + dir) % planets.size()
	if new_index < 0:
		new_index = planets.size() - 1
	animate_to(new_index)
		
func animate_to(new_index: int) -> void:
	if is_animating:
		return
	is_animating = true
	# Flick animation:
	# 1) shrink + fade out
	# 2) swap
	# 3) bounce back in
	var t := create_tween()
	t.set_trans(Tween.TRANS_QUAD)
	t.set_ease(Tween.EASE_IN)
	t.tween_property(planet_tex, "scale", Vector2(0.75, 0.75), 0.10)
	t.parallel().tween_property(planet_tex, "modulate:a",0.0, 0.10)
	t.parallel().tween_property(name_label, "modulate:a",0.0, 0.10)
	# Swap AFTER fade out
	t.tween_callback(func():
		apply_planet(new_index, true) # <-- no named argument (fixes your error)
	)
	t.set_ease(Tween.EASE_OUT)
	t.tween_property(planet_tex, "scale", Vector2(1.08, 1.08), 0.12)
	t.parallel().tween_property(planet_tex, "modulate:a",1.0, 0.12)
	t.parallel().tween_property(name_label, "modulate:a",1.0, 0.12)
	t.tween_property(planet_tex, "scale", Vector2(1.0, 1.0), 0.08)
	t.tween_callback(func():
		is_animating = false
	)
	
func apply_planet(i: int, instant: bool = false) -> void:
	index = i
	planet_tex.texture = planets[index]["tex"]
	name_label.text = planets[index]["name"]
	update_thumbnail_highlight()
	if instant:
		planet_tex.scale = Vector2.ONE
		planet_tex.modulate.a = 1.0
		name_label.modulate.a = 1.0
		
func update_thumbnail_highlight() -> void:
	for i in range(thumb_buttons.size()):
		var b := thumb_buttons[i]
		if i == index:
			b.modulate = Color(1, 1, 1, 1.0)
			b.scale = Vector2(1.05, 1.05)
		else:
			b.modulate = Color(1, 1, 1, 0.55)
			b.scale = Vector2(1.0, 1.0)
