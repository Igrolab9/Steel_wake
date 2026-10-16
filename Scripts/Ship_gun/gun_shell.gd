extends Area2D

const LIFETIME := 10.0
const DAMAGE := 1.0

var _lifetime: float = 0.0
var velocity: Vector2 = Vector2.ZERO
## Снаряд игнорирует коллизии в первый кадр после выдачи из пула,
## чтобы не задеть того, кто его выстрелил (Area2D может «увидеть» уже существующий контакт).
var _can_collide: bool = false
var _pool: Node = null  # Пул, в который снаряд вернётся; внедряется явно через set_pool()

func _ready() -> void:
	reset_state()
	body_entered.connect(_on_body_entered)
	z_index = 10

func _physics_process(delta: float) -> void:
	_lifetime += delta

	# Включаем коллизии только через 1 кадр
	if not _can_collide:
		_can_collide = true
		monitoring = true

	global_position += velocity * delta

	if _lifetime >= LIFETIME:
		_return_to_pool()

## Внедрение зависимости: пул передаётся извне, а не берётся из глобального autoload.
func set_pool(pool: Node) -> void:
	_pool = pool

func get_pool() -> Node:
	return _pool

## Публичный контракт сброса снаряда перед выдачей/после возврата —
## вместо прямых записей в приватные поля из пула.
func reset_state() -> void:
	_lifetime = 0.0
	velocity = Vector2.ZERO
	_can_collide = false
	monitoring = false

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)

	_return_to_pool()

func _return_to_pool() -> void:
	set_deferred("monitoring", false)
	call_deferred("_do_return_to_pool")

func _do_return_to_pool() -> void:
	reset_state()
	# Пул внедряется владельцем сцены (см. main.gd) — без глобального autoload-синглтона.
	if _pool != null and is_instance_valid(_pool):
		_pool.return_shell(self)
	else:
		push_warning("GunShell: ссылка на пул снарядов не установлена, удаляю снаряд.")
		queue_free()
