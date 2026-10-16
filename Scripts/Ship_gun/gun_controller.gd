class_name GunController
extends RefCounted
## Управление стрельбой. Темп стрельбы — единый источник истины (FIRE_RATE):
## ни игрок, ни враги не держат собственных таймеров.

const SHELL_SPEED := 500.0
const FIRE_RATE := 2.0

var _barrel: Node2D
var _shell_pool: Node
var _fire_cooldown: float = 0.0

signal shell_fired(shell_position: Vector2)

## Зависимости (ствол и пул) передаются извне — GunController не обращается к глобальным синглтонам.
func _init(barrel: Node2D, shell_pool: Node) -> void:
	_barrel = barrel
	_shell_pool = shell_pool
	if _barrel == null:
		push_error("GunController requires a valid barrel Node2D")
	if _shell_pool == null:
		push_error("GunController requires a valid ShellPool")

func update(delta: float) -> void:
	if _fire_cooldown > 0.0:
		_fire_cooldown -= delta

## Позволяет заменить/установить пул снарядов после создания контроллера
## (например, спавнер внедряет его во враг до первой стрельбы).
func set_shell_pool(pool: Node) -> void:
	_shell_pool = pool

func fire() -> void:
	if _fire_cooldown > 0.0 or _shell_pool == null:
		return

	_fire_cooldown = 1.0 / FIRE_RATE

	var shell := _shell_pool.get_shell()

	# Снаряжаем маркером немного впереди (по локальной «оси ствола» маркера — вверх).
	var muzzle_offset := Vector2.UP * 10.0
	shell.global_position = _barrel.global_position + muzzle_offset.rotated(_barrel.global_rotation)
	shell.global_rotation = _barrel.global_rotation

	var forward_direction := Vector2.UP.rotated(_barrel.global_rotation)
	shell.velocity = forward_direction * SHELL_SPEED

	shell_fired.emit(shell.global_position)
