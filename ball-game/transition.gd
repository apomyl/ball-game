extends AnimatedSprite2D

func _ready():
	var screen_size = get_viewport_rect().size
	var texture_size = sprite_frames.get_frame_texture(animation, 0).get_size()
	
	scale = screen_size / texture_size

	play("run")
