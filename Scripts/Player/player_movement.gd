class_name PlayerMovement
extends RefCounted

const SPEED := 200.0

var _body: CharacterBody2D

signal direction_changed(new_direction: int)

func _init(body: CharacterBody2D) -> void:
	_body = body
	if _body == null:
		push_error("PlayerMovement requires a valid CharacterBody2D")

func update(delta: float) -> void:
	# Пробрасываем delta в логику
	_handle_movement(delta) 
	_body.move_and_slide()

# Принимаем delta для корректного замедления
func _handle_movement(delta: float) -> void:
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		_body.velocity.x = direction * SPEED
		direction_changed.emit(sign(direction))
	else:
		# Умножаем на delta, чтобы торможение было независимым от FPS
		_body.velocity.x = move_toward(_body.velocity.x, 0, SPEED * delta)

func get_velocity() -> Vector2:
	return _body.velocity
