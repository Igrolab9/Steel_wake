extends Node2D

@export var enemy_scenes: Array[PackedScene]

@export var min_spawn_time: float = 0.5
@export var max_spawn_time: float = 3.5

@export var spawn_offset_x: float = 150.0

const POOL_SIZE = 10
var _enemy_pool: Array = []
var _spawn_timer: float = 0.0
var _next_spawn_time: float = 0.0

signal enemy_spawned(enemy)

func _ready():
	if enemy_scenes.is_empty():
		push_warning("Enemy_spawner: массив enemy_scenes пуст. Заполни его в инспекторе!")
		set_process(false)
		return
	
	_initialize_pool()
	_set_next_spawn_time()

func _process(delta: float):
	_spawn_timer += delta
	
	if _spawn_timer >= _next_spawn_time:
		_spawn_enemy()
		_spawn_timer = 0.0
		_set_next_spawn_time()

func _initialize_pool():
	for i in POOL_SIZE:
		var enemy = _create_enemy_instance()
		if enemy == null:
			continue
		enemy.visible = false
		enemy.set_physics_process(false)
		_enemy_pool.append(enemy)
		add_child(enemy)

func _create_enemy_instance() -> Node2D:
	var scene_index = randi() % enemy_scenes.size()
	return enemy_scenes[scene_index].instantiate()

func _spawn_enemy():
	var enemy = _get_enemy_from_pool()
	
	if enemy == null:
		enemy = _create_enemy_instance()
		if enemy == null:
			return
		add_child(enemy)
	
	enemy.global_position = Vector2(
		global_position.x + randf_range(-spawn_offset_x, spawn_offset_x),
		global_position.y
	)
	
	if enemy.has_method("initialize"):
		enemy.initialize(self)
	
	enemy_spawned.emit(enemy)

func _get_enemy_from_pool() -> Node2D:
	# Очищаем пул от удалённых объектов
	_enemy_pool = _enemy_pool.filter(func(e): return is_instance_valid(e))
	
	for enemy in _enemy_pool:
		if is_instance_valid(enemy) and not enemy.visible:
			return enemy
	return null

func return_enemy_to_pool(enemy: Node2D):
	if not is_instance_valid(enemy):
		return
	enemy.visible = false
	enemy.set_physics_process(false)
	enemy.position = Vector2.ZERO

func _set_next_spawn_time():
	_next_spawn_time = randf_range(min_spawn_time, max_spawn_time)
