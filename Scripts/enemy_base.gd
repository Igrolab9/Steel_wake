class_name EnemyBase
extends CharacterBody2D
## Базовый класс врага: движение, здоровье, стрельба (через GunController), жизненный цикл пула.
##
## Контракт для наследников и окружения:
## - сигналы наружу: `died`, `spawned` — внешний код (спавнер, игра) подписывается на них,
##   вместо того чтобы знать о внутренней реакции врага на смерть;
## - спавнер вызывает `set_shell_pool()` + `initialize()` при выдаче из пула и подписывает
##   `return_to_pool()` на сигнал `died` (см. enemy_spawner.gd);
## - темп стрельбы задаётся единственным источником — GunController.FIRE_RATE.

signal died(enemy: EnemyBase)
signal spawned(enemy: EnemyBase)

@export var move_speed: float = 75.0
@export var max_health: float = 1.0
## Ссылка на ствол (Marker2D) — задаётся в инспекторе, без жёсткой привязки к имени узла.
@export var gun_barrel_path: NodePath = ^"Ship_gun/Marker2D"

var _gun: GunController
var _health: HealthComponent
var _shell_pool: Node = null
var _spawner: Node2D = null

@onready var _gun_barrel: Marker2D = get_node_or_null(gun_barrel_path) as Marker2D

func _ready() -> void:
	if _gun_barrel == null:
		push_error("%s: не найден ствол по пути '%s'" % [name, gun_barrel_path])
		return

	# FIRE_RATE не передаётся — темп стрельбы принадлежит GunController (единый источник).
	_gun = GunController.new(_gun_barrel, _shell_pool)
	_health = HealthComponent.new(self, max_health)
	_health.died.connect(_on_death)

	# Скрыт до получения из пула
	_set_active(false)

## Спавнер внедряет пул снарядов перед выдачей врага (до initialize()).
func set_shell_pool(pool: Node) -> void:
	_shell_pool = pool
	if _gun != null:
		_gun.set_shell_pool(pool)

func initialize(spawner: Node2D) -> void:
	_spawner = spawner
	_health.reset(max_health)
	velocity = Vector2.ZERO
	_set_active(true)
	spawned.emit(self)

func _physics_process(delta: float) -> void:
	velocity.y = move_speed
	move_and_slide()

	_gun.update(delta)
	_gun.fire()

func take_damage(amount: float) -> void:
	_health.take_damage(amount)

## Вызывается спавнером по сигналу `died`: враг гасится и возвращается в пул.
func return_to_pool() -> void:
	_set_active(false)
	if is_instance_valid(_spawner) and _spawner.has_method("return_enemy_to_pool"):
		_spawner.return_enemy_to_pool(self)
	else:
		queue_free()

func _on_death() -> void:
	died.emit(self)

func _set_active(active: bool) -> void:
	visible = active
	set_physics_process(active)
	if not active:
		velocity = Vector2.ZERO
