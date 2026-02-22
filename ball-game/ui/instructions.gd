extends Control

@onready var astronaut_sprite: AnimatedSprite2D = $Astronaut/AstronautSprite
@onready var bubble: Control = $Astronaut/Speech
@onready var text_label: RichTextLabel = $Astronaut/Speech/Text
@onready var timer: Timer = $SequenceTimer

# -------------------------
# EDIT THESE
# -------------------------
var char_delay := 0.03
var after_full_text_wait := 2.5
var between_bubbles_wait := 0.4

var talk_anim_name := "talk"
var end_anim_name := "end"

var pages := [
	"Welcome to SpaceBallz! You will be able to customise your own exoplanet so that you can battle all the planets in our Solar System! Remember! The faster the planet, the less weight, and so the less power, you need to find the perfect balance!",
	"Good luck! You've got this!!"
]

# -------------------------
# INTERNAL
# -------------------------
var _page_index := 0
var _typing := false


func _ready() -> void:
	# Start talk loop immediately and keep it going during text/between bubbles
	astronaut_sprite.play(talk_anim_name)

	text_label.text = ""
	text_label.visible_characters = 0
	bubble.visible = true

	_show_page(0)


func _show_page(index: int) -> void:
	_page_index = index
	_typing = true

	text_label.text = pages[index]
	text_label.visible_characters = 0

	_type_next_character()


func _type_next_character() -> void:
	if not _typing:
		return

	text_label.visible_characters += 1

	if text_label.visible_characters >= text_label.get_total_character_count():
		_typing = false
		_on_finished_typing()
		return

	timer.stop()
	timer.one_shot = true
	timer.wait_time = char_delay
	timer.timeout.connect(_on_timer_type, CONNECT_ONE_SHOT)
	timer.start()


func _on_timer_type() -> void:
	_type_next_character()


func _on_finished_typing() -> void:
	timer.stop()
	timer.one_shot = true
	timer.wait_time = after_full_text_wait
	timer.timeout.connect(_on_timer_after_page, CONNECT_ONE_SHOT)
	timer.start()


func _on_timer_after_page() -> void:
	if _page_index < pages.size() - 1:
		# Hide briefly, then show next bubble
		bubble.visible = false

		timer.stop()
		timer.one_shot = true
		timer.wait_time = between_bubbles_wait
		timer.timeout.connect(_on_timer_next_page, CONNECT_ONE_SHOT)
		timer.start()
	else:
		# Finished all pages -> hide bubble and play end anim
		bubble.visible = false
		_play_end_animation_then_change_scene()


func _on_timer_next_page() -> void:
	bubble.visible = true
	_show_page(_page_index + 1)


# -------------------------
# END ANIM -> NEXT SCENE
# -------------------------
func _play_end_animation_then_change_scene() -> void:
	# Stop current talk anim (optional; end anim will replace it anyway)
	# astronaut_sprite.stop()

	if not astronaut_sprite.sprite_frames.has_animation(end_anim_name):
		push_warning("End animation not found: " + end_anim_name)
		get_tree().change_scene_to_file("res://ui/creation.tscn")
		return

	# Connect to animation_finished ONLY for the end animation
	astronaut_sprite.animation_finished.connect(_on_astronaut_animation_finished, CONNECT_ONE_SHOT)

	# Play the end animation (make sure it is NOT looping in SpriteFrames)
	astronaut_sprite.play(end_anim_name)


func _on_astronaut_animation_finished() -> void:
	# Only change scenes if the animation that just finished is the end animation
	if astronaut_sprite.animation == end_anim_name:
		get_tree().change_scene_to_file("res://ui/creation.tscn")
