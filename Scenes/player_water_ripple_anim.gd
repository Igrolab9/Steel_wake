extends AnimatedSprite2D

const ANIMATION_DEFAULT : String = "default"

# Called when the node enters the scene tree for the first time.
func _ready()-> void:
	play(ANIMATION_DEFAULT)
	animation_looped
