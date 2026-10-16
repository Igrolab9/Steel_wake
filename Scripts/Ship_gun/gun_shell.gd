extends Area2D

const LIFETIME := 10.0
const DAMAGE := 1.0

var _lifetime: float = 0.0
var velocity: Vector2 = Vector2.ZERO
var _can_collide: bool = false  # Убедитесь что это есть!

func _ready() -> void:
	_lifetime = 0.0
	_can_collide = false
	monitoring = false
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

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(DAMAGE)
	
	_return_to_pool()

func _return_to_pool() -> void:
	set_deferred("monitoring", false)
	call_deferred("_do_return_to_pool")

func _do_return_to_pool() -> void:
	velocity = Vector2.ZERO
	_lifetime = 0.0  # <-- Сброс времени жизни
	_can_collide = false  # <-- Сброс флага
	ShellPool.return_shell(self)
