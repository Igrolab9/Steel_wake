extends Node

const SHELL_SCENE := preload("res://Scenes/gun_shell.tscn")
const POOL_SIZE := 50

var _pool: Array[Area2D] = []
var _active_shells: Array[Area2D] = []

func _ready() -> void:
	for i in POOL_SIZE:
		var shell := SHELL_SCENE.instantiate() as Area2D
		shell.set_process(false)
		shell.set_physics_process(false)
		shell.visible = false
		add_child(shell)
		_pool.append(shell)

func get_shell() -> Area2D:
	var shell: Area2D
	
	if _pool.size() > 0:
		shell = _pool.pop_back()
	else:
		push_warning("ShellPool exhausted! Creating new shell dynamically.")
		shell = SHELL_SCENE.instantiate() as Area2D
		add_child(shell)
	
	shell.set_process(true)
	shell.set_physics_process(true)
	shell.visible = true
	shell._lifetime = 0.0  # <-- ДОБАВИТЬ: сброс времени жизни
	shell._can_collide = false  # <-- ДОБАВИТЬ: сброс флага коллизии
	_active_shells.append(shell)
	
	return shell

func return_shell(shell: Area2D) -> void:
	shell.set_process(false)
	shell.set_physics_process(false)
	shell.visible = false
	shell.velocity = Vector2.ZERO
	shell.monitoring = false  # <-- ДОБАВИТЬ эту строку!
	
	_active_shells.erase(shell)
	_pool.append(shell)
