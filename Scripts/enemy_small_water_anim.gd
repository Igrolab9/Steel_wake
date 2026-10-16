extends AnimatedSprite2D

const ANIMATION_DEFAULT : String = "default"

func _ready() -> void:
	# loop задаётся в SpriteFrames; play() с аргументом — на случай перезапуска из пула
	play(ANIMATION_DEFAULT)
