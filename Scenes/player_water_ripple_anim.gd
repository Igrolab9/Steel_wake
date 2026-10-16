extends AnimatedSprite2D

const ANIMATION_DEFAULT : String = "default"

func _ready() -> void:
	# loop задаётся в SpriteFrames
	play(ANIMATION_DEFAULT)
