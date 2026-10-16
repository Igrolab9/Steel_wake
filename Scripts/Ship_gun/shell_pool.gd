extends Node
## Пул снарядов. Больше НЕ autoload-синглтон: создаётся в сцене (см. main.gd),
## а ссылка внедряется в GunController и в каждый снаряд через set_pool().

const SHELL_SCENE := preload("res://Scenes/gun_shell.tscn")
const POOL_SIZE := 50

var _free_shells: Array[GunShell] = []  # стек свободных снарядов
var _active_count: int = 0

func _ready() -> void:
	for i in POOL_SIZE:
		var shell := _create_shell()
		shell.set_process(false)
		shell.set_physics_process(false)
		shell.visible = false
		_free_shells.append(shell)

func get_shell() -> GunShell:
	var shell: GunShell

	if not _free_shells.is_empty():
		shell = _free_shells.pop_back()
	else:
		push_warning("ShellPool exhausted! Creating new shell dynamically.")
		shell = _create_shell()

	# Явный публичный контракт сброса состояния снаряда
	shell.reset_state()
	shell.set_process(true)
	shell.set_physics_process(true)
	shell.visible = true
	_active_count += 1

	return shell

func return_shell(shell: GunShell) -> void:
	if not is_instance_valid(shell):
		return

	shell.set_process(false)
	shell.set_physics_process(false)
	shell.visible = false
	shell.reset_state()

	_active_count -= 1
	_free_shells.append(shell)

func get_active_count() -> int:
	return _active_count

func _create_shell() -> GunShell:
	var shell := SHELL_SCENE.instantiate() as GunShell
	add_child(shell)
	# Внедрение зависимости: снаряд знает о пуле только через явную ссылку.
	shell.set_pool(self)
	return shell
