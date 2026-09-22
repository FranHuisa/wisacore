extends CharacterBody2D

## =========================================================
## WisaCore - Jugador (Clase base: Guerrero)
## Mezcla de combate en tiempo real (movimiento y ataque
## básico posicional) con un sistema de "objetivo bloqueado"
## al estilo tab-target (Golpe de Poder). Las stats vienen de
## un StatBlock (paso 1 del roadmap: sistema de atributos).
## =========================================================

@export var stats: StatBlock

@export var base_move_speed: float = 200.0
@export var sprint_multiplier: float = 1.6

@export var basic_attack_damage: float = 15.0
@export var power_strike_damage: float = 35.0
@export var power_strike_cooldown: float = 4.0

@export var dodge_cooldown: float = 2.0
@export var dodge_speed_multiplier: float = 3.0
@export var dodge_duration: float = 0.2
@export var dodge_stamina_cost: float = 20.0

@export var power_strike_range: float = 110.0
@export var target_select_range: float = 320.0

@export var stamina_regen_per_second: float = 12.0
@export var stamina_regen_delay: float = 0.6

var move_speed: float
var max_health: float
var max_stamina: float
var max_mana: float
var melee_damage_multiplier: float = 1.0
var sprint_stamina_cost: float = 8.0

var inventory: Inventory
var equipment: Equipment
var effective_stats: StatBlock
var known_recipes: Array[Recipe] = []

var current_health: float
var current_stamina: float
var current_mana: float
var current_target: Node2D = null

var power_strike_timer: float = 0.0
var dodge_timer: float = 0.0
var is_dodging: bool = false
var dodge_time_left: float = 0.0
var stamina_regen_cooldown: float = 0.0

var facing_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false

signal health_changed(current: float, max_value: float)
signal stamina_changed(current: float, max_value: float)
signal target_changed(target: Node2D)
signal ability_cooldown_changed(ability_name: String, time_left: float, max_time: float)
signal inventory_changed
signal died

@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Polygon2D = $Sprite


func _ready() -> void:
	if stats == null:
		# Valores por defecto de Guerrero si no se asignó un StatBlock
		# desde el Inspector (útil mientras no exista todavía un
		# sistema de creación de personaje).
		stats = StatBlock.new()
		stats.fuerza = 14.0
		stats.estabilidad = 12.0
		stats.agilidad = 10.0

	equipment = Equipment.new()
	inventory = Inventory.new()
	_add_starting_items()
	known_recipes = RecipeDatabase.get_all_recipes()

	recalculate_stats()
	current_health = max_health
	current_stamina = max_stamina
	current_mana = max_mana

	add_to_group("player")
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)


func _add_starting_items() -> void:
	# Objetos de prueba para validar equipamiento e inventario 5x5.
	var helmet := ItemData.new()
	helmet.item_name = "Yelmo de Centinela"
	helmet.equip_slot = Equipment.Slot.CABEZA
	helmet.icon_path = "res://assets/ui/icons/helmet.png"
	helmet.color = Color(0.4, 0.4, 0.45)
	helmet.rarity = ItemData.Rarity.POCO_COMUN
	helmet.description = "Yelmo de acero templado usado por los centinelas de la guardia fronteriza."
	helmet.stat_bonuses = {"estabilidad": 3.0}
	inventory.add_item(helmet)

	var chest := ItemData.new()
	chest.item_name = "Peto Reforzado"
	chest.equip_slot = Equipment.Slot.PECHO
	chest.icon_path = "res://assets/ui/icons/chest.png"
	chest.color = Color(0.35, 0.3, 0.4)
	chest.rarity = ItemData.Rarity.RARO
	chest.description = "Placas de metal reforzadas con remaches. Pesado, pero ofrece buena protección."
	chest.stat_bonuses = {"estabilidad": 2.0, "vida_base": 15.0}
	inventory.add_item(chest)

	var sword := ItemData.new()
	sword.item_name = "Espada Corta"
	sword.equip_slot = Equipment.Slot.ARMA
	sword.icon_path = "res://assets/ui/icons/weapon_sword.png"
	sword.color = Color(0.6, 0.6, 0.65)
	sword.rarity = ItemData.Rarity.COMUN
	sword.description = "Una espada corta de entrenamiento. Ligera y fácil de manejar."
	sword.stat_bonuses = {"fuerza": 4.0}
	inventory.add_item(sword)

	var ring := ItemData.new()
	ring.item_name = "Anillo de Agilidad"
	ring.equip_slot = Equipment.Slot.ACCESORIO_1
	ring.icon_path = "res://assets/ui/icons/ring.png"
	ring.color = Color(0.5, 0.7, 0.6)
	ring.rarity = ItemData.Rarity.EPICO
	ring.description = "Un anillo tallado en jade que agiliza los reflejos de quien lo porta."
	ring.stat_bonuses = {"agilidad": 3.0}
	inventory.add_item(ring)

	var boots := ItemData.new()
	boots.item_name = "Botas Ligeras"
	boots.equip_slot = Equipment.Slot.PIES
	boots.icon_path = "res://assets/ui/icons/boots.png"
	boots.color = Color(0.45, 0.4, 0.35)
	boots.rarity = ItemData.Rarity.COMUN
	boots.description = "Botas de cuero curtido, cómodas para largas caminatas."
	boots.stat_bonuses = {"agilidad": 2.0}
	inventory.add_item(boots)

	var ring2 := ItemData.new()
	ring2.item_name = "Anillo de Fuerza"
	ring2.equip_slot = Equipment.Slot.ACCESORIO_2
	ring2.icon_path = "res://assets/ui/icons/ring.png"
	ring2.color = Color(0.7, 0.55, 0.35)
	ring2.rarity = ItemData.Rarity.POCO_COMUN
	ring2.description = "Un anillo pesado de bronce grabado con runas de fuerza."
	ring2.stat_bonuses = {"fuerza": 2.0}
	inventory.add_item(ring2)

	var necklace := ItemData.new()
	necklace.item_name = "Collar del Peregrino"
	necklace.equip_slot = Equipment.Slot.COLLAR
	necklace.icon_path = "res://assets/ui/icons/necklace.png"
	necklace.color = Color(0.55, 0.75, 0.7)
	necklace.rarity = ItemData.Rarity.RARO
	necklace.description = "Cuentas de piedra pulida ensartadas en un cordón trenzado."
	necklace.stat_bonuses = {"voluntad": 3.0}
	inventory.add_item(necklace)

	var belt := ItemData.new()
	belt.item_name = "Cinturón de Cuero Reforzado"
	belt.equip_slot = Equipment.Slot.CINTURON
	belt.icon_path = "res://assets/ui/icons/belt.png"
	belt.color = Color(0.5, 0.35, 0.22)
	belt.rarity = ItemData.Rarity.COMUN
	belt.description = "Cuero grueso con hebilla de hierro. Añade algo de aguante."
	belt.stat_bonuses = {"aguante_base": 10.0}
	inventory.add_item(belt)

	# El set inicial se equipa directamente para que el personaje
	# empiece ya "vestido" (índices 0-7, en el mismo orden en que se
	# acaban de añadir arriba).
	equip_from_inventory(0)  # Yelmo de Centinela
	equip_from_inventory(1)  # Peto Reforzado
	equip_from_inventory(2)  # Espada Corta
	equip_from_inventory(3)  # Anillo de Agilidad
	equip_from_inventory(4)  # Botas Ligeras
	equip_from_inventory(5)  # Anillo de Fuerza
	equip_from_inventory(6)  # Collar del Peregrino
	equip_from_inventory(7)  # Cinturón de Cuero Reforzado

	# Segundo casco (sin equipar, se queda en la mochila) para poder
	# probar la comparación "nuevo vs. equipado": mejora estabilidad
	# pero penaliza agilidad, así se ve tanto un + en verde como un -
	# en rojo en el tooltip.
	var helmet2 := ItemData.new()
	helmet2.item_name = "Casco de Hierro"
	helmet2.equip_slot = Equipment.Slot.CABEZA
	helmet2.icon_path = "res://assets/ui/icons/helmet.png"
	helmet2.color = Color(0.55, 0.5, 0.5)
	helmet2.rarity = ItemData.Rarity.RARO
	helmet2.description = "Casco macizo de hierro forjado. Más resistente que el yelmo estándar, pero también más pesado."
	helmet2.stat_bonuses = {"estabilidad": 5.0, "agilidad": -1.0}
	inventory.add_item(helmet2)

	var shield := ItemData.new()
	shield.item_name = "Escudo de Madera Reforzado"
	shield.equip_slot = Equipment.Slot.ARMA_SECUNDARIA
	shield.icon_path = "res://assets/ui/icons/shield.png"
	shield.color = Color(0.45, 0.32, 0.22)
	shield.rarity = ItemData.Rarity.COMUN
	shield.description = "Un escudo sencillo de madera con refuerzos de hierro en el borde."
	shield.stat_bonuses = {"estabilidad": 2.0}
	inventory.add_item(shield)
	for i in range(Inventory.SIZE):
		var entry = inventory.get_at(i)
		if entry != null and entry["item"] == shield:
			equip_from_inventory(i)
			break

	var bow := ItemData.new()
	bow.item_name = "Arco Corto de Caza"
	bow.equip_slot = Equipment.Slot.ARMA
	bow.icon_path = "res://assets/ui/icons/weapon_bow.png"
	bow.color = Color(0.5, 0.4, 0.25)
	bow.rarity = ItemData.Rarity.POCO_COMUN
	bow.description = "Arco ligero, pensado para disparos rápidos a corta distancia. Se queda en la mochila para comparar con la Espada Corta equipada."
	bow.stat_bonuses = {"punteria": 3.0}
	inventory.add_item(bow)

	# Materiales de crafteo (del catálogo, para que compartan item_id
	# con las recetas de RecipeDatabase). Cantidades pensadas para
	# poder craftear "Barra de Hierro" y "Vendaje de Tela" ya mismo.
	inventory.add_item(ItemCatalog.get_item("iron_ore"), 6)
	inventory.add_item(ItemCatalog.get_item("wood"), 10)
	inventory.add_item(ItemCatalog.get_item("leather"), 5)
	inventory.add_item(ItemCatalog.get_item("cloth"), 8)


func recalculate_stats() -> void:
	# Combina los atributos base (StatBlock) con los bonus de todo el
	# equipamiento puesto, y recalcula todas las estadísticas derivadas.
	var bonus: Dictionary = equipment.get_total_bonus()
	var effective: StatBlock = stats.duplicate()
	effective.estabilidad += bonus["estabilidad"]
	effective.agilidad += bonus["agilidad"]
	effective.destreza += bonus["destreza"]
	effective.punteria += bonus["punteria"]
	effective.fuerza += bonus["fuerza"]
	effective.voluntad += bonus["voluntad"]
	effective.canalizacion += bonus["canalizacion"]
	effective.conexion_elemental += bonus["conexion_elemental"]
	effective.vida_base += bonus["vida_base"]
	effective.aguante_base += bonus["aguante_base"]
	effective.mana_base += bonus["mana_base"]
	effective_stats = effective

	max_health = effective.get_max_health()
	max_stamina = effective.get_max_stamina()
	max_mana = effective.get_max_mana()
	move_speed = base_move_speed + effective.get_move_speed_bonus()
	melee_damage_multiplier = effective.get_melee_damage_multiplier()
	sprint_stamina_cost = effective.get_sprint_stamina_cost_per_second()

	current_health = min(current_health, max_health)
	current_stamina = min(current_stamina, max_stamina)
	current_mana = min(current_mana, max_mana)

	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)


func equip_from_inventory(inventory_index: int) -> void:
	var entry = inventory.get_at(inventory_index)
	if entry == null:
		return
	var item: ItemData = entry["item"]
	if item.equip_slot == -1:
		return  # No es equipable (material/consumible)

	var previous: ItemData = equipment.equip(item.equip_slot, item)
	inventory.remove_at(inventory_index)
	if previous != null:
		inventory.set_at(inventory_index, {"item": previous, "quantity": 1})

	recalculate_stats()
	inventory_changed.emit()


func unequip_to_inventory(slot: int) -> void:
	var item: ItemData = equipment.slots.get(slot)
	if item == null:
		return
	var free_index := inventory.find_first_empty()
	if free_index == -1:
		return  # Mochila llena, no se puede desequipar

	equipment.unequip(slot)
	inventory.set_at(free_index, {"item": item, "quantity": 1})

	recalculate_stats()
	inventory_changed.emit()


func count_item(item_id: String) -> int:
	var total := 0
	for i in range(Inventory.SIZE):
		var entry = inventory.get_at(i)
		if entry != null and entry["item"].item_id == item_id:
			total += entry["quantity"]
	return total


func can_craft(recipe: Recipe) -> bool:
	if recipe == null or not recipe.unlocked:
		return false
	for item_id in recipe.materials.keys():
		var needed: int = recipe.materials[item_id]
		if count_item(item_id) < needed:
			return false
	return true


func craft(recipe: Recipe) -> bool:
	if not can_craft(recipe):
		return false
	for item_id in recipe.materials.keys():
		_remove_item_quantity(item_id, recipe.materials[item_id])

	var result_item: ItemData = ItemCatalog.get_item(recipe.result_id)
	inventory.add_item(result_item, recipe.result_quantity)

	inventory_changed.emit()
	return true


func _remove_item_quantity(item_id: String, amount: int) -> void:
	var remaining := amount
	for i in range(Inventory.SIZE):
		if remaining <= 0:
			break
		var entry = inventory.get_at(i)
		if entry == null or entry["item"].item_id != item_id:
			continue
		var take: int = min(remaining, entry["quantity"])
		entry["quantity"] -= take
		remaining -= take
		if entry["quantity"] <= 0:
			inventory.remove_at(i)


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_handle_timers(delta)
	_handle_movement(delta)


func _input(event: InputEvent) -> void:
	if is_dead:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_TAB:
				_cycle_target()
			KEY_1:
				_basic_attack()
			KEY_2:
				_power_strike()
			KEY_SPACE:
				_dodge()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_basic_attack()


func _handle_timers(delta: float) -> void:
	if power_strike_timer > 0.0:
		power_strike_timer = max(0.0, power_strike_timer - delta)
		ability_cooldown_changed.emit("power_strike", power_strike_timer, power_strike_cooldown)

	if dodge_timer > 0.0:
		dodge_timer = max(0.0, dodge_timer - delta)
		ability_cooldown_changed.emit("dodge", dodge_timer, dodge_cooldown)

	if is_dodging:
		dodge_time_left -= delta
		if dodge_time_left <= 0.0:
			is_dodging = false

	if stamina_regen_cooldown > 0.0:
		stamina_regen_cooldown -= delta


func _handle_movement(delta: float) -> void:
	var input_vector := Vector2.ZERO

	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		input_vector.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		input_vector.y += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		input_vector.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		input_vector.x += 1.0

	input_vector = input_vector.normalized()

	if input_vector != Vector2.ZERO:
		facing_direction = input_vector
		attack_area.position = facing_direction * 15.0

	var wants_to_sprint := Input.is_physical_key_pressed(KEY_SHIFT) and input_vector != Vector2.ZERO
	var is_sprinting := false

	var speed := move_speed
	if is_dodging:
		speed *= dodge_speed_multiplier
	elif wants_to_sprint and current_stamina > 0.0:
		speed *= sprint_multiplier
		is_sprinting = true

	if is_sprinting:
		_consume_stamina(sprint_stamina_cost * delta)
	else:
		_regen_stamina(delta)

	velocity = input_vector * speed
	move_and_slide()


func _consume_stamina(amount: float) -> void:
	current_stamina = max(0.0, current_stamina - amount)
	stamina_regen_cooldown = stamina_regen_delay
	stamina_changed.emit(current_stamina, max_stamina)


func _regen_stamina(delta: float) -> void:
	if stamina_regen_cooldown > 0.0 or current_stamina >= max_stamina:
		return
	current_stamina = min(max_stamina, current_stamina + stamina_regen_per_second * delta)
	stamina_changed.emit(current_stamina, max_stamina)


func _cycle_target() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var candidates: Array = []

	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) <= target_select_range:
			candidates.append(enemy)

	if candidates.is_empty():
		current_target = null
		target_changed.emit(null)
		return

	candidates.sort_custom(func(a, b): return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position))

	if current_target == null or not candidates.has(current_target):
		current_target = candidates[0]
	else:
		var idx := candidates.find(current_target)
		current_target = candidates[(idx + 1) % candidates.size()]

	target_changed.emit(current_target)


func _basic_attack() -> void:
	# Ataque en tiempo real: golpea a quien esté dentro del área frontal,
	# sin necesidad de tener un objetivo bloqueado.
	var damage := basic_attack_damage * melee_damage_multiplier
	var bodies := attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies") and body.has_method("take_damage"):
			body.take_damage(damage)


func _power_strike() -> void:
	# Habilidad tipo tab-target: requiere un objetivo bloqueado con Tab
	# y que esté dentro de rango, pero no requiere apuntar con precisión.
	if power_strike_timer > 0.0:
		return
	if current_target == null or not is_instance_valid(current_target):
		return
	if global_position.distance_to(current_target.global_position) > power_strike_range:
		return

	power_strike_timer = power_strike_cooldown
	var damage := power_strike_damage * melee_damage_multiplier
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage)


func _dodge() -> void:
	if dodge_timer > 0.0 or is_dodging:
		return
	if current_stamina < dodge_stamina_cost:
		return

	dodge_timer = dodge_cooldown
	is_dodging = true
	dodge_time_left = dodge_duration
	_consume_stamina(dodge_stamina_cost)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health = max(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		_die()


func _die() -> void:
	is_dead = true
	sprite.color = Color(0.2, 0.2, 0.2)
	died.emit()
