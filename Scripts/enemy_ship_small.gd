extends CharacterBody2D

const SPEED := 75.0

var _gun: GunController
var _health: HealthComponent
var _fire_timer: float = 0.0
var _fire_interval: float = 2.0
var _enemy_health: float = 1.0
var _spawner: Node2D = null  # Ссылка на спавнер

@onready var _gun_barrel: Marker2D = $Ship_gun/Marker2D

func _ready() -> void:
	_gun = GunController.new(_gun_barrel)
	_health = HealthComponent.new(self, _enemy_health)
	_health.died.connect(_on_death)
	
	_fire_timer = _fire_interval
	# Скрываем при старте (если из пула)
	visible = false
	set_physics_process(false)

func initialize(spawner: Node2D) -> void:
	_spawner = spawner
	_health.reset(_enemy_health)
	visible = true
	set_physics_process(true)
	_fire_timer = _fire_interval

func _physics_process(delta: float) -> void:
	velocity.y = SPEED
	move_and_slide()
	
	_gun.update(delta)
	_fire_timer += delta
	
	if should_fire():
		_gun.fire()
		_fire_timer = 0.0

func should_fire() -> bool:
	return _fire_timer >= _fire_interval

func take_damage(amount: float) -> void:
	_health.take_damage(amount)

func _on_death() -> void:
	print("Враг уничтожен!")
	_return_to_pool()

func _return_to_pool() -> void:
	# Останавливаем врага
	velocity = Vector2.ZERO
	set_physics_process(false)
	visible = false
	
	# Сбрасываем таймер стрельбы
	_fire_timer = 0.0
	
	# Возвращаем в пул через спавнер
	if _spawner != null and _spawner.has_method("return_enemy_to_pool"):
		_spawner.return_enemy_to_pool(self)
	else:
		# Фоллбэк: если спавнер не найден, удаляем
		queue_free()
