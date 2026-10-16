extends CharacterBody2D

var _player_health : float = 10.0

var _movement: PlayerMovement
var _gun: GunController
var _health: HealthComponent # <-- Новый компонент

## Путь к узлу пула снарядов (ShellPool в main.tscn) — внедряется извне, без глобального синглтона.
@export var shell_pool_path: NodePath = ^"../ShellPool"

@onready var _gun_barrel: Marker2D = $Ship_gun/Marker2D
@onready var _gunshot_sound : AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	_movement = PlayerMovement.new(self)
	var shell_pool := get_node_or_null(shell_pool_path)
	if shell_pool == null:
		push_error("Ship_player: пул снарядов не найден по пути '%s'." % shell_pool_path)
	_gun = GunController.new(_gun_barrel, shell_pool)
	
	# Инициализируем здоровье (например, 100 единиц)
	_health = HealthComponent.new(self, _player_health)
	_health.died.connect(_on_death)
	
	_gun.shell_fired.connect(_on_shell_fired)

func _physics_process(delta: float) -> void:
	_movement.update(delta)
	_gun.update(delta)
	
	if Input.is_action_just_pressed("ui_accept"):
		_gun.fire()

# Этот метод вызывает снаряд при столкновении!
func take_damage(amount: float) -> void:
	print("Получен урон!")
	_health.take_damage(amount)

func _on_death() -> void:
	print("Игрок погиб! Game Over.")
	# Здесь будет логика конца игры: остановка времени, показ экрана проигрыша и т.д.
	# set_process(false)
	# set_physics_process(false)

func _on_shell_fired(position: Vector2) -> void:
	_gunshot_sound.play()
