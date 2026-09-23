extends Resource
class_name SkillTreeDatabase

## =========================================================
## WisaCore - Árbol de habilidades: contenido de ejemplo (BASE)
##
## 3 ramas de ejemplo (Combate, Resistencia, Agilidad), cada una una
## pestaña independiente en la ventana. Dentro de cada pestaña hay 2
## columnas (0 y 1) por 3 niveles (0 = abajo del todo, sube hacia
## arriba), y cada nodo requiere el nodo de la COLUMNA OPUESTA del
## nivel de abajo -> las líneas de conexión se cruzan formando una X
## entre cada dos niveles según van hacia arriba.
##
## Igual que RecipeDatabase/QuestDatabase: crea instancias NUEVAS cada
## vez que se llama, así que player.gd la llama una sola vez en
## _ready() y guarda el resultado en Player.skill_tree_nodes. Cambiar
## ramas, nombres, bonus o costes aquí no requiere tocar ninguna otra
## parte del sistema (ventana, Player, guardado).
## =========================================================

static func get_all_nodes() -> Array[SkillNode]:
	var list: Array[SkillNode] = []

	# --- Rama: Combate (pestaña 1) ---
	var combat_color := Color(0.70, 0.20, 0.25)
	list.append(_make_node("combat_0_0", "Golpe Certero", "Afina la técnica de ataque cuerpo a cuerpo.", "Combate", combat_color, 1, [], Vector2i(0, 0), {"fuerza": 2.0}))
	list.append(_make_node("combat_0_1", "Instinto de Batalla", "Agudiza los reflejos al entrar en combate.", "Combate", combat_color, 1, [], Vector2i(1, 0), {"fuerza": 2.0}))
	list.append(_make_node("combat_1_0", "Combo Salvaje", "Encadena golpes cada vez más rápido.", "Combate", combat_color, 1, ["combat_0_1"], Vector2i(0, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_1_1", "Ataque en Cadena", "Convierte cada golpe en el inicio del siguiente.", "Combate", combat_color, 1, ["combat_0_0"], Vector2i(1, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_2_0", "Maestría Marcial", "Dominio casi total del combate cuerpo a cuerpo.", "Combate", combat_color, 2, ["combat_1_1"], Vector2i(0, 2), {"fuerza": 5.0}))
	list.append(_make_node("combat_2_1", "Furia Imparable", "Una furia que no conoce límites.", "Combate", combat_color, 2, ["combat_1_0"], Vector2i(1, 2), {"fuerza": 5.0}))

	# --- Rama: Resistencia (pestaña 2) ---
	var tank_color := Color(0.35, 0.55, 0.75)
	list.append(_make_node("tank_0_0", "Piel de Acero", "Refuerza la estabilidad ante los golpes.", "Resistencia", tank_color, 1, [], Vector2i(0, 0), {"estabilidad": 2.0}))
	list.append(_make_node("tank_0_1", "Aguante Férreo", "Amplía la resistencia física de base.", "Resistencia", tank_color, 1, [], Vector2i(1, 0), {"vida_base": 10.0}))
	list.append(_make_node("tank_1_0", "Vitalidad", "Aumenta la reserva de vida máxima.", "Resistencia", tank_color, 1, ["tank_0_1"], Vector2i(0, 1), {"vida_base": 15.0}))
	list.append(_make_node("tank_1_1", "Muro Viviente", "Convierte el cuerpo en una defensa sólida.", "Resistencia", tank_color, 1, ["tank_0_0"], Vector2i(1, 1), {"estabilidad": 3.0}))
	list.append(_make_node("tank_2_0", "Inquebrantable", "Vuelve al Guerrero casi imposible de derribar.", "Resistencia", tank_color, 2, ["tank_1_1"], Vector2i(0, 2), {"estabilidad": 4.0, "vida_base": 10.0}))
	list.append(_make_node("tank_2_1", "Coraza Definitiva", "La máxima expresión de la resistencia física.", "Resistencia", tank_color, 2, ["tank_1_0"], Vector2i(1, 2), {"vida_base": 25.0}))

	# --- Rama: Agilidad (pestaña 3) ---
	var agi_color := Color(0.35, 0.70, 0.45)
	list.append(_make_node("agi_0_0", "Pies Ligeros", "Mejora la soltura de movimientos.", "Agilidad", agi_color, 1, [], Vector2i(0, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_0_1", "Reflejos Rápidos", "Afila la capacidad de reacción.", "Agilidad", agi_color, 1, [], Vector2i(1, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_1_0", "Danza de Esquiva", "Cada movimiento se vuelve una evasión.", "Agilidad", agi_color, 1, ["agi_0_1"], Vector2i(0, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_1_1", "Paso Fantasma", "Moverse deja de tener resistencia.", "Agilidad", agi_color, 1, ["agi_0_0"], Vector2i(1, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_2_0", "Viento Fugaz", "Una agilidad casi sobrehumana.", "Agilidad", agi_color, 2, ["agi_1_1"], Vector2i(0, 2), {"agilidad": 5.0}))
	list.append(_make_node("agi_2_1", "Sombra Veloz", "Se mueve más rápido de lo que el ojo sigue.", "Agilidad", agi_color, 2, ["agi_1_0"], Vector2i(1, 2), {"agilidad": 5.0}))

	return list


static func _make_node(id: String, name: String, desc: String, branch: String, color: Color, cost: int, requires: Array[String], grid_pos: Vector2i, bonuses: Dictionary) -> SkillNode:
	var node := SkillNode.new()
	node.skill_id = id
	node.skill_name = name
	node.description = desc
	node.branch = branch
	node.color = color
	node.cost = cost
	node.requires = requires
	node.grid_position = grid_pos
	node.stat_bonuses = bonuses
	return node
