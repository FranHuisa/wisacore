extends CharacterBody2D

## =========================================================
## WisaCore - Enemigo base ("Aberración")
## Máquina de estados simple: Deambular -> Perseguir -> Atacar -> Morir
## =========================================================

@export var move_speed: float = 90.0
@export var max_health: float = 80.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.2
@export var detection_range: float = 220.0
@export var attack_range: float = 55.0
@export var wander_radius: float = 100.0

enum State { IDLE, CHASE, ATTACK, DEAD }

var current_health: float
var state: State = State.IDLE
var attack_timer: float = 0.0
var wander_target: Vector2
var wander_timer: float = 0.0
var home_position: Vector2
var player_ref: Node2D = null

signal health_changed(current: float, max_value: float)
signal died

@onready var sprite: Polygon2D = $Sprite


func _ready() -> void:
	current_health = max_health
	home_position = global_position
	add_to_group("enemies")
	_pick_new_wander_target()


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	_find_player()
	_update_state(delta)
	move_and_slide()


func _find_player() -> void:
	if player_ref == null or not is_instance_valid(player_ref):
		var players := get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			player_ref = players[0]


func _update_state(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

	if player_ref == null:
		_wander(delta)
		return

	var dist := global_position.distance_to(player_ref.global_position)

	match state:
		State.IDLE:
			if dist <= detection_range:
				state = State.CHASE
			else:
				_wander(delta)

		State.CHASE:
			if dist > detection_range * 1.4:
				state = State.IDLE
				velocity = Vector2.ZERO
			elif dist <= attack_range:
				state = State.ATTACK
				velocity = Vector2.ZERO
			else:
				var dir := (player_ref.global_position - global_position).normalized()
				velocity = dir * move_speed

		State.ATTACK:
			velocity = Vector2.ZERO
			if dist > attack_range:
				state = State.CHASE
			elif attack_timer <= 0.0:
				_attack_player()


func _wander(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		_pick_new_wander_target()

	var dir := wander_target - global_position
	if dir.length() < 5.0:
		velocity = Vector2.ZERO
	else:
		velocity = dir.normalized() * (move_speed * 0.4)


func _pick_new_wander_target() -> void:
	wander_timer = randf_range(2.0, 4.0)
	var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	wander_target = home_position + offset


func _attack_player() -> void:
	attack_timer = attack_cooldown
	if player_ref and player_ref.has_method("take_damage"):
		player_ref.take_damage(attack_damage)


func take_damage(amount: float) -> void:
	if state == State.DEAD:
		return
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()
	else:
		state = State.CHASE


func _die() -> void:
	state = State.DEAD
	sprite.color = Color(0.1, 0.1, 0.1)
	set_physics_process(false)
	died.emit()
	await get_tree().create_timer(1.5).timeout
	queue_free()
