class_name GunController
extends RefCounted

const SHELL_SPEED := 500.0
const FIRE_RATE := 2.0

var _barrel: Node2D
var _fire_cooldown: float = 0.0

signal shell_fired(shell_position: Vector2)

func _init(barrel: Node2D) -> void:
	_barrel = barrel
	if _barrel == null:
		push_error("GunController requires a valid barrel Node2D")

func update(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

func fire() -> void:
	if _fire_cooldown > 0.0:
		return
	
	_fire_cooldown = 1.0 / FIRE_RATE
	
	var shell := ShellPool.get_shell()
	
	# Спавним снаряд немного впереди маркера (на 10 пикселей)
	var spawn_offset := Vector2.UP * 10.0  # Смещение вперёд
	var spawn_position := _barrel.global_position + spawn_offset.rotated(_barrel.global_rotation)
	
	shell.global_position = spawn_position
	shell.global_rotation = _barrel.global_rotation
	
	var forward_direction := Vector2.UP.rotated(_barrel.global_rotation)
	shell.velocity = forward_direction * SHELL_SPEED
	
	shell_fired.emit(shell.global_position)
