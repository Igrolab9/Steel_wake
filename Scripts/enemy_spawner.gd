extends Node2D
## Спавнер врагов: хранит пул экземпляров, выдаёт их по таймеру и принимает обратно.
## Позиция спавна задаётся маркером (spawn_marker_path), а не вычисляется из геометрии уровня.

const ENEMY_POOL_SIZE := 10

@export var enemy_scenes: Array[PackedScene]

@export var min_spawn_time: float = 0.5
@export var max_spawn_time: float = 3.5

## Маркер точки появления врагов — задать в инспекторе (NodePath на Marker2D).
@export var spawn_marker_path: NodePath = ^"SpawnMarker"
## Случайный разброс позиции спавна по X относительно маркера.
@export var spawn_offset_x: float = 150.0

## Путь к узлу пула снарядов (ShellPool в main.tscn) — вместо глобального autoload-синглтона.
@export var shell_pool_path: NodePath = ^"../ShellPool"

var _shell_pool: Node = null
var _spawn_marker: Marker2D = null
var _enemy_pool: Array[EnemyBase] = []
var _active_enemies: Array[EnemyBase] = []
var _spawn_timer: float = 0.0
var _next_spawn_time: float = 0.0

signal enemy_spawned(enemy: EnemyBase)
signal enemy_died(enemy: EnemyBase)

func _ready() -> void:
	_shell_pool = get_node_or_null(shell_pool_path)
	if _shell_pool == null:
		push_warning("Enemy_spawner: пул снарядов не найден по пути '%s' — враги не смогут стрелять." % shell_pool_path)

	_spawn_marker = get_node_or_null(spawn_marker_path) as Marker2D
	if _spawn_marker == null:
		push_warning("Enemy_spawner: маркер спавна не найден по пути '%s'." % spawn_marker_path)

	if enemy_scenes.is_empty():
		push_warning("Enemy_spawner: массив enemy_scenes пуст. Заполни его в инспекторе!")
		set_process(false)
		return

	_initialize_pool()
	_set_next_spawn_time()

func _process(delta: float) -> void:
	_spawn_timer += delta

	if _spawn_timer >= _next_spawn_time:
		_spawn_enemy()
		_spawn_timer = 0.0
		_set_next_spawn_time()

func _initialize_pool() -> void:
	for i in ENEMY_POOL_SIZE:
		var enemy := _create_enemy_instance()
		if enemy == null:
			continue
		_prepare_enemy(enemy)
		_enemy_pool.append(enemy)
		add_child(enemy)

func _create_enemy_instance() -> EnemyBase:
	var scene_index := randi() % enemy_scenes.size()
	var enemy := enemy_scenes[scene_index].instantiate() as EnemyBase
	if enemy == null:
		push_error("Enemy_spawner: сцена инстанцируется не в EnemyBase: %s" % enemy_scenes[scene_index])
	return enemy

## Единая подготовка экземпляра: зависимости + подписка на смерть через сигнал наружу.
func _prepare_enemy(enemy: EnemyBase) -> void:
	enemy.set_shell_pool(_shell_pool)
	# Реакция на смерть живёт вне врага: он лишь испускает сигнал `died` (контракт EnemyBase).
	enemy.died.connect(_on_enemy_died)
	enemy.visible = false
	enemy.set_physics_process(false)

func _spawn_enemy() -> void:
	var enemy := _get_enemy_from_pool()

	if enemy == null:
		enemy = _create_enemy_instance()
		if enemy == null:
			return
		_prepare_enemy(enemy)
		add_child(enemy)

	var base := _spawn_marker.global_position if _spawn_marker != null else global_position
	enemy.global_position = Vector2(
		base.x + randf_range(-spawn_offset_x, spawn_offset_x),
		base.y
	)

	enemy.initialize(self)
	_active_enemies.append(enemy)
	enemy_spawned.emit(enemy)

func _get_enemy_from_pool() -> EnemyBase:
	_enemy_pool = _enemy_pool.filter(func(e): return is_instance_valid(e))

	# Занятость отслеживается явным списком активных, а не признаком visible
	for enemy in _enemy_pool:
		if not _is_active(enemy):
			return enemy
	return null

func return_enemy_to_pool(enemy: EnemyBase) -> void:
	if not is_instance_valid(enemy):
		return
	_active_enemies.erase(enemy)
	enemy.visible = false
	enemy.set_physics_process(false)
	# ВАЖНО: позицию НЕ сбрасываем в Vector2.ZERO — иначе следующий спавн без установки
	# позиции выпустит врага в начале координат; при спавне позиция задаётся явно.
	if not _enemy_pool.has(enemy):
		_enemy_pool.append(enemy)

func _on_enemy_died(enemy: EnemyBase) -> void:
	enemy_died.emit(enemy)
	enemy.return_to_pool()

func _is_active(enemy: EnemyBase) -> bool:
	return _active_enemies.has(enemy) and is_instance_valid(enemy)

func _set_next_spawn_time() -> void:
	_next_spawn_time = randf_range(min_spawn_time, max_spawn_time)
