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

## Distancia máxima a la que se puede recoger un objeto del suelo.
@export var pickup_range: float = 60.0

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

## Oro persistente (Paso "Oro" del roadmap). Se carga de GameSave al
## empezar y se guarda automáticamente en cada cambio.
var gold: int = 0

## Misiones activas y completadas (Paso "Misiones" del roadmap).
var active_quests: Array[Quest] = []
var completed_quests: Array[Quest] = []

## Objeto del suelo más cercano dentro de "pickup_range" (o null).
var nearby_world_item: WorldItem = null

## Cuando es true, se ignora todo el movimiento/combate del jugador.
## Lo activa main.gd mientras el menú de pausa (ESC) o los ajustes
## están abiertos, para que el personaje no se mueva ni ataque "detrás"
## del menú mientras se está navegando por él.
var input_locked: bool = false

## Árbol de habilidades (BASE, ver skill_tree_database.gd). Puntos de
## partida provisionales para poder probar la ventana ya mismo; cuando
## se defina de dónde vienen de verdad (subir de nivel, misiones...)
## solo hay que cambiar cómo se incrementa "skill_points", el resto
## del sistema no se toca.
var skill_points: int = 3
var skill_tree_nodes: Array[SkillNode] = []
var unlocked_skill_ids: Dictionary = {}

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
signal gold_changed(amount: int)
signal quests_changed
## item_label vacío = ya no hay ningún objeto del suelo al alcance.
signal pickup_target_changed(item_label: String)
signal skill_tree_changed

@onready var attack_area: Area2D = $AttackArea
@onready var sprite: Polygon2D = $Sprite
@onready var head_sprite: Sprite2D = $HeadSprite

## Solo hay sprites de prueba para 6 de las 8 direcciones (falta un
## "puro" izquierda/derecha): para esos dos casos se reutiliza el
## sprite diagonal hacia abajo correspondiente, que es el que menos
## desentona. En cuanto haya sprites propios para esas direcciones,
## basta con añadir las claces "left"/"right" aquí.
var _head_textures: Dictionary = {}


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
	active_quests = QuestDatabase.get_starting_quests()
	skill_tree_nodes = SkillTreeDatabase.get_all_nodes()

	gold = GameSave.get_gold()

	_load_head_textures()
	_update_head_sprite()

	recalculate_stats()
	current_health = max_health
	current_stamina = max_stamina
	current_mana = max_mana

	add_to_group("player")
	health_changed.emit(current_health, max_health)
	stamina_changed.emit(current_stamina, max_stamina)
	gold_changed.emit(gold)


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

	var bracelet := ItemData.new()
	bracelet.item_name = "Brazalete de Bronce"
	bracelet.equip_slot = Equipment.Slot.BRAZALETE
	bracelet.icon_path = "res://assets/ui/icons/bracelet.png"
	bracelet.color = Color(0.6, 0.5, 0.35)
	bracelet.rarity = ItemData.Rarity.POCO_COMUN
	bracelet.description = "Un brazalete pesado de bronce grabado con motivos geométricos."
	bracelet.stat_bonuses = {"destreza": 2.0}
	inventory.add_item(bracelet)

	# El set inicial se equipa directamente para que el personaje
	# empiece ya "vestido" (índices 0-8, en el mismo orden en que se
	# acaban de añadir arriba).
	equip_from_inventory(0)  # Yelmo de Centinela
	equip_from_inventory(1)  # Peto Reforzado
	equip_from_inventory(2)  # Espada Corta
	equip_from_inventory(3)  # Anillo de Agilidad
	equip_from_inventory(4)  # Botas Ligeras
	equip_from_inventory(5)  # Anillo de Fuerza
	equip_from_inventory(6)  # Collar del Peregrino
	equip_from_inventory(7)  # Cinturón de Cuero Reforzado
	equip_from_inventory(8)  # Brazalete de Bronce

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
	# equipamiento puesto y del árbol de habilidades desbloqueado, y
	# recalcula todas las estadísticas derivadas.
	var equip_bonus: Dictionary = equipment.get_total_bonus()
	var skill_bonus: Dictionary = get_total_skill_bonus()
	var effective: StatBlock = stats.duplicate()
	effective.estabilidad += equip_bonus["estabilidad"] + skill_bonus["estabilidad"]
	effective.agilidad += equip_bonus["agilidad"] + skill_bonus["agilidad"]
	effective.destreza += equip_bonus["destreza"] + skill_bonus["destreza"]
	effective.punteria += equip_bonus["punteria"] + skill_bonus["punteria"]
	effective.fuerza += equip_bonus["fuerza"] + skill_bonus["fuerza"]
	effective.voluntad += equip_bonus["voluntad"] + skill_bonus["voluntad"]
	effective.canalizacion += equip_bonus["canalizacion"] + skill_bonus["canalizacion"]
	effective.conexion_elemental += equip_bonus["conexion_elemental"] + skill_bonus["conexion_elemental"]
	effective.vida_base += equip_bonus["vida_base"] + skill_bonus["vida_base"]
	effective.aguante_base += equip_bonus["aguante_base"] + skill_bonus["aguante_base"]
	effective.mana_base += equip_bonus["mana_base"] + skill_bonus["mana_base"]
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


## --- Usadas por el arrastrar y soltar del inventario ---

## Dos anillos son intercambiables entre sí; el resto de ranuras solo
## aceptan su propio tipo exacto de objeto.
func _slot_compatible(item_slot: int, target_slot: int) -> bool:
	if item_slot == target_slot:
		return true
	var rings := [Equipment.Slot.ACCESORIO_1, Equipment.Slot.ACCESORIO_2]
	return item_slot in rings and target_slot in rings


## Arrastrar un objeto de una casilla de la mochila a otra: las
## intercambia (si el destino está vacío, simplemente se mueve).
func move_backpack_item(from_index: int, to_index: int) -> void:
	if from_index == to_index or from_index < 0 or to_index < 0:
		return
	var a = inventory.get_at(from_index)
	var b = inventory.get_at(to_index)
	inventory.set_at(from_index, b)
	inventory.set_at(to_index, a)
	inventory_changed.emit()


## Arrastrar un objeto de la mochila a una ranura de equipo concreta
## (no necesariamente a la que tenga asignada por defecto: p. ej. un
## anillo se puede soltar en Anillo 1 o en Anillo 2).
func equip_from_inventory_to_slot(inventory_index: int, target_slot: int) -> void:
	var entry = inventory.get_at(inventory_index)
	if entry == null:
		return
	var item: ItemData = entry["item"]
	if item.equip_slot == -1 or not _slot_compatible(item.equip_slot, target_slot):
		return  # No es equipable, o no encaja en esta ranura.

	var previous: ItemData = equipment.slots.get(target_slot)
	equipment.slots[target_slot] = item
	inventory.remove_at(inventory_index)
	if previous != null:
		inventory.set_at(inventory_index, {"item": previous, "quantity": 1})

	recalculate_stats()
	inventory_changed.emit()


## Arrastrar un objeto equipado a una casilla concreta de la mochila
## (si esa casilla ya tiene algo compatible con la ranura de origen,
## se intercambian; si está vacía, simplemente se desequipa ahí).
func unequip_to_index(from_slot: int, to_index: int) -> void:
	var item: ItemData = equipment.slots.get(from_slot)
	if item == null:
		return
	var existing = inventory.get_at(to_index)
	if existing != null:
		var existing_item: ItemData = existing["item"]
		if existing_item.equip_slot == -1 or not _slot_compatible(existing_item.equip_slot, from_slot):
			return  # La casilla ya tiene algo que no se puede equipar aquí.
		equipment.slots[from_slot] = existing_item
	else:
		equipment.slots[from_slot] = null
	inventory.set_at(to_index, {"item": item, "quantity": 1})

	recalculate_stats()
	inventory_changed.emit()


## Arrastrar un objeto equipado de una ranura a otra (p. ej. Anillo 1
## a Anillo 2). Si ambas tienen algo puesto, se intercambian.
func swap_equipped(slot_a: int, slot_b: int) -> void:
	if slot_a == slot_b:
		return
	var item_a: ItemData = equipment.slots.get(slot_a)
	var item_b: ItemData = equipment.slots.get(slot_b)
	if item_a != null and not _slot_compatible(item_a.equip_slot, slot_b):
		return
	if item_b != null and not _slot_compatible(item_b.equip_slot, slot_a):
		return
	equipment.slots[slot_a] = item_b
	equipment.slots[slot_b] = item_a

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


## --- Oro (persistente vía GameSave) ---

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	GameSave.set_gold(gold)
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if amount <= 0 or gold < amount:
		return false
	gold -= amount
	GameSave.set_gold(gold)
	gold_changed.emit(gold)
	return true


## --- Misiones ---

## Llamado desde enemy.gd cuando un enemigo muere (mismo patrón que ya
## usa _attack_player() para llamar a Player.take_damage directamente).
func register_enemy_kill() -> void:
	var changed := false
	for quest in active_quests:
		for objective in quest.objectives:
			if objective.kind == QuestObjective.Kind.KILL_ENEMIES and not objective.is_complete():
				objective.current_amount += 1
				changed = true
	if changed:
		quests_changed.emit()


## Reclama la recompensa de una misión ya completada: consume los
## materiales de sus objetivos de tipo COLLECT_ITEM (con
## _remove_item_quantity, igual que craft() al gastar materiales),
## entrega el oro y el objeto de recompensa (si tiene) y mueve la
## misión de "activas" a "completadas".
func claim_quest_reward(quest: Quest) -> bool:
	if quest == null or not active_quests.has(quest):
		return false
	if not quest.is_complete():
		return false

	for objective in quest.objectives:
		if objective.kind == QuestObjective.Kind.COLLECT_ITEM and objective.target_id != "":
			_remove_item_quantity(objective.target_id, objective.required_amount)

	if quest.reward_gold > 0:
		add_gold(quest.reward_gold)
	if quest.reward_item_id != "":
		inventory.add_item(ItemCatalog.get_item(quest.reward_item_id), quest.reward_item_quantity)

	quest.completed = true
	active_quests.erase(quest)
	completed_quests.append(quest)

	inventory_changed.emit()
	quests_changed.emit()
	return true


## --- Árbol de habilidades ---

## Suma stat_bonuses de todos los nodos desbloqueados, con las mismas
## claves que Equipment.get_total_bonus() (así recalculate_stats() las
## trata exactamente igual).
func get_total_skill_bonus() -> Dictionary:
	var totals := {
		"estabilidad": 0.0, "agilidad": 0.0, "destreza": 0.0, "punteria": 0.0,
		"fuerza": 0.0, "voluntad": 0.0, "canalizacion": 0.0, "conexion_elemental": 0.0,
		"vida_base": 0.0, "aguante_base": 0.0, "mana_base": 0.0,
	}
	for node in skill_tree_nodes:
		if unlocked_skill_ids.has(node.skill_id):
			for key in node.stat_bonuses.keys():
				if totals.has(key):
					totals[key] += node.stat_bonuses[key]
	return totals


func is_skill_unlocked(node: SkillNode) -> bool:
	return unlocked_skill_ids.has(node.skill_id)


## Un nodo se puede desbloquear si no lo está ya, hay puntos suficientes
## y todos sus prerrequisitos (node.requires) ya están desbloqueados.
func can_unlock_skill(node: SkillNode) -> bool:
	if node == null or is_skill_unlocked(node):
		return false
	if skill_points < node.cost:
		return false
	for required_id in node.requires:
		if not unlocked_skill_ids.has(required_id):
			return false
	return true


func unlock_skill(node: SkillNode) -> bool:
	if not can_unlock_skill(node):
		return false
	unlocked_skill_ids[node.skill_id] = true
	skill_points -= node.cost
	recalculate_stats()
	skill_tree_changed.emit()
	return true


## --- Recoger / soltar objetos del suelo ---

## Escanea (por distancia, igual que _cycle_target hace con "enemies")
## el grupo "world_items" para encontrar el más cercano al alcance.
func _scan_nearby_pickup() -> void:
	var items := get_tree().get_nodes_in_group("world_items")
	var closest: WorldItem = null
	var closest_dist := pickup_range

	for candidate in items:
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
			continue
		var dist := global_position.distance_to(candidate.global_position)
		if dist <= closest_dist:
			closest_dist = dist
			closest = candidate

	if closest != nearby_world_item:
		nearby_world_item = closest
		pickup_target_changed.emit("" if closest == null else closest.get_display_name())


func _try_pickup() -> void:
	if nearby_world_item == null or not is_instance_valid(nearby_world_item):
		return
	pickup_world_item(nearby_world_item)


## Recoge un objeto del suelo. El oro se suma directamente a "gold" (no
## ocupa hueco de mochila); el resto de objetos pasan por
## Inventory.has_space_for() antes de tocar nada: si no hay espacio, no
## se recoge (ni se toca el inventario ni se destruye el objeto del suelo).
func pickup_world_item(world_item: WorldItem) -> bool:
	if world_item == null or not is_instance_valid(world_item):
		return false
	var item: ItemData = world_item.item_data
	var quantity: int = world_item.quantity
	if item == null or quantity <= 0:
		return false

	if item.is_currency:
		add_gold(quantity)
		_remove_nearby_world_item(world_item)
		return true

	if not inventory.has_space_for(item, quantity):
		return false  # No hay espacio: no se recoge.

	if inventory.add_item(item, quantity):
		_remove_nearby_world_item(world_item)
		inventory_changed.emit()
		return true

	return false


func _remove_nearby_world_item(world_item: WorldItem) -> void:
	if nearby_world_item == world_item:
		nearby_world_item = null
		pickup_target_changed.emit("")
	# queue_free() no borra el nodo al instante (Godot lo difiere al final
	# del frame), así que si no lo sacamos del grupo ya mismo, el siguiente
	# _scan_nearby_pickup() (que corre cada frame de física) todavía lo
	# encontraría -sigue siendo válido un instante más- y, como el jugador
	# está encima, lo volvería a seleccionar como "más cercano": el aviso
	# de recoger reaparecería con el objeto que se acaba de recoger.
	if world_item.is_in_group("world_items"):
		world_item.remove_from_group("world_items")
	world_item.queue_free()


## Suelta "quantity" unidades del objeto en la ranura "index" de la
## mochila (se ajusta automáticamente si se pide más de lo que hay), y
## las materializa como un WorldItem delante del jugador.
func drop_item_from_backpack(index: int, quantity: int) -> bool:
	var entry = inventory.get_at(index)
	if entry == null:
		return false
	var item: ItemData = entry["item"]
	var available: int = entry["quantity"]
	var drop_quantity: int = clampi(quantity, 1, available)

	var world_item := WorldItem.new()
	world_item.item_data = item
	world_item.quantity = drop_quantity
	var parent := get_parent()
	if parent == null:
		return false
	parent.add_child(world_item)
	world_item.global_position = global_position + facing_direction * 40.0 + Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))

	if drop_quantity >= available:
		inventory.remove_at(index)
	else:
		entry["quantity"] -= drop_quantity

	inventory_changed.emit()
	return true


## --- Sprite de cabeza (prueba de arte direccional) ---

func _load_head_textures() -> void:
	_head_textures = {
		"up": preload("res://assets/character/armour/cabeza-sin-nada-up.png"),
		"down": preload("res://assets/character/armour/cabeza-sin-nada-down.png"),
		"up_right": preload("res://assets/character/armour/cabeza-sin-nada-diagonal-arriba-derecha.png"),
		"up_left": preload("res://assets/character/armour/cabeza-sin-nada-diagonal-arriba-izq.png"),
		"down_right": preload("res://assets/character/armour/cabeza-sin-nada-dia-abajo-dere.png"),
		"down_left": preload("res://assets/character/armour/cabeza-sin-nada-diagonal.png"),
	}


## Traduce "facing_direction" (siempre uno de los 8 vectores posibles
## del movimiento en cruz/diagonal de _handle_movement) al sprite de
## cabeza correspondiente. Solo hay arte de prueba para 6 direcciones;
## para "izquierda"/"derecha" puros se reutiliza el diagonal hacia
## abajo del mismo lado, que es el que menos desentona visualmente.
func _update_head_sprite() -> void:
	if head_sprite == null or _head_textures.is_empty():
		return

	var dir := facing_direction
	if dir == Vector2.ZERO:
		return

	var deg := rad_to_deg(dir.angle())  # 0=derecha, 90=abajo, -90=arriba, 180/-180=izquierda
	var key: String

	if deg > -22.5 and deg <= 67.5:
		key = "down_right"
	elif deg > 67.5 and deg <= 112.5:
		key = "down"
	elif deg > 112.5 and deg <= 157.5:
		key = "down_left"
	elif deg > 157.5 or deg <= -157.5:
		key = "down_left"
	elif deg > -157.5 and deg <= -112.5:
		key = "up_left"
	elif deg > -112.5 and deg <= -67.5:
		key = "up"
	else:
		key = "up_right"

	head_sprite.texture = _head_textures.get(key)


func _physics_process(delta: float) -> void:
	if is_dead or input_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_handle_timers(delta)
	_handle_movement(delta)
	_scan_nearby_pickup()


func _input(event: InputEvent) -> void:
	if is_dead or input_locked:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == GameSave.get_keybind("pickup"):
			_try_pickup()
			return
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
		_update_head_sprite()

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
