extends AnimatedSprite2D

func _ready():
	Engine.time_scale = 1.0
	var screen_size = get_viewport_rect().size
	var texture_size = sprite_frames.get_frame_texture(animation, 0).get_size()
	
	scale = screen_size / texture_size
	
	animation_finished.connect(_on_animation_finished)

	play("run")
	speed_scale = 1.0

func _on_animation_finished():
	get_tree().change_scene_to_file("res://ui/battles/battle.tscn")
	
