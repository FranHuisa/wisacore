extends Resource
class_name SkillTreeDatabase

## =========================================================
## WisaCore - Árbol de habilidades: contenido de ejemplo (BASE)
##
## 3 ramas de ejemplo (Combate, Resistencia, Agilidad), cada una una
## pestaña independiente en la ventana. Dentro de cada pestaña hay 5
## columnas (0 a 4) por 3 niveles (0 = abajo del todo, sube hacia
## arriba).
##
## Conexión en X por VECINOS (no por columna opuesta): cada nodo de la
## fila de arriba requiere sus dos vecinos diagonales de la fila de
## abajo (columna - 1 y columna + 1, los que existan). Ejemplo con 5
## columnas (1..5 aquí para que se lea igual que lo pidió el usuario,
## en el código las columnas van de 0 a 4):
##
##   Fila 2:   1     2     3     4     5
##              \   / \   / \   / \   /
##   Fila 1:   1     2     3     4     5
##
## O sea: el "2" de la fila 1 conecta hacia el "1" y el "3" de la fila
## 2 (sus dos vecinos), y a su vez el "2" de la fila 2 requiere TANTO
## el "1" como el "3" de la fila 1 (sus dos vecinos de abajo) -> para
## desbloquear una columna del medio hacen falta las DOS columnas
## vecinas de abajo. Las columnas de los extremos (1 y 5) solo tienen
## un vecino, así que solo necesitan esa única columna. Esto se repite
## igual entre cada dos niveles según se sube (de ahí el "viceversa").
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
	list.append(_make_node("combat_0_2", "Filo Rápido", "Afila cada arma antes del primer golpe.", "Combate", combat_color, 1, [], Vector2i(2, 0), {"fuerza": 2.0}))
	list.append(_make_node("combat_0_3", "Puño de Hierro", "Endurece los golpes desnudos.", "Combate", combat_color, 1, [], Vector2i(3, 0), {"fuerza": 2.0}))
	list.append(_make_node("combat_0_4", "Ojo del Cazador", "Detecta el punto débil del enemigo.", "Combate", combat_color, 1, [], Vector2i(4, 0), {"fuerza": 2.0}))
	list.append(_make_node("combat_1_0", "Combo Salvaje", "Encadena golpes cada vez más rápido.", "Combate", combat_color, 1, ["combat_0_1"], Vector2i(0, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_1_1", "Ataque en Cadena", "Convierte cada golpe en el inicio del siguiente.", "Combate", combat_color, 1, ["combat_0_0", "combat_0_2"], Vector2i(1, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_1_2", "Ruptura de Guardia", "Quiebra cualquier defensa enemiga.", "Combate", combat_color, 1, ["combat_0_1", "combat_0_3"], Vector2i(2, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_1_3", "Embate Brutal", "Cada golpe pesa como dos.", "Combate", combat_color, 1, ["combat_0_2", "combat_0_4"], Vector2i(3, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_1_4", "Corte Preciso", "Encuentra el hueco exacto entre la armadura.", "Combate", combat_color, 1, ["combat_0_3"], Vector2i(4, 1), {"fuerza": 3.0}))
	list.append(_make_node("combat_2_0", "Maestría Marcial", "Dominio casi total del combate cuerpo a cuerpo.", "Combate", combat_color, 2, ["combat_1_1"], Vector2i(0, 2), {"fuerza": 5.0}))
	list.append(_make_node("combat_2_1", "Furia Imparable", "Una furia que no conoce límites.", "Combate", combat_color, 2, ["combat_1_0", "combat_1_2"], Vector2i(1, 2), {"fuerza": 5.0}))
	list.append(_make_node("combat_2_2", "Tormenta de Acero", "Una lluvia de golpes imposible de frenar.", "Combate", combat_color, 2, ["combat_1_1", "combat_1_3"], Vector2i(2, 2), {"fuerza": 5.0}))
	list.append(_make_node("combat_2_3", "Golpe Sísmico", "Un solo golpe capaz de sacudir el suelo.", "Combate", combat_color, 2, ["combat_1_2", "combat_1_4"], Vector2i(3, 2), {"fuerza": 5.0}))
	list.append(_make_node("combat_2_4", "Verdugo", "La sentencia final de cualquier duelo.", "Combate", combat_color, 2, ["combat_1_3"], Vector2i(4, 2), {"fuerza": 5.0}))

	# --- Rama: Resistencia (pestaña 2) ---
	var tank_color := Color(0.35, 0.55, 0.75)
	list.append(_make_node("tank_0_0", "Piel de Acero", "Refuerza la estabilidad ante los golpes.", "Resistencia", tank_color, 1, [], Vector2i(0, 0), {"estabilidad": 2.0}))
	list.append(_make_node("tank_0_1", "Aguante Férreo", "Amplía la resistencia física de base.", "Resistencia", tank_color, 1, [], Vector2i(1, 0), {"vida_base": 10.0}))
	list.append(_make_node("tank_0_2", "Nervios de Hierro", "Mantiene la calma bajo cualquier golpe.", "Resistencia", tank_color, 1, [], Vector2i(2, 0), {"estabilidad": 2.0}))
	list.append(_make_node("tank_0_3", "Reserva Vital", "Guarda fuerzas para cuando más se necesitan.", "Resistencia", tank_color, 1, [], Vector2i(3, 0), {"vida_base": 10.0}))
	list.append(_make_node("tank_0_4", "Postura Firme", "Una base que nada logra mover.", "Resistencia", tank_color, 1, [], Vector2i(4, 0), {"estabilidad": 2.0}))
	list.append(_make_node("tank_1_0", "Vitalidad", "Aumenta la reserva de vida máxima.", "Resistencia", tank_color, 1, ["tank_0_1"], Vector2i(0, 1), {"vida_base": 15.0}))
	list.append(_make_node("tank_1_1", "Muro Viviente", "Convierte el cuerpo en una defensa sólida.", "Resistencia", tank_color, 1, ["tank_0_0", "tank_0_2"], Vector2i(1, 1), {"estabilidad": 3.0}))
	list.append(_make_node("tank_1_2", "Corazón de Piedra", "Un núcleo que no cede ante el daño.", "Resistencia", tank_color, 1, ["tank_0_1", "tank_0_3"], Vector2i(2, 1), {"vida_base": 15.0}))
	list.append(_make_node("tank_1_3", "Bastión", "Se planta y no retrocede ni un paso.", "Resistencia", tank_color, 1, ["tank_0_2", "tank_0_4"], Vector2i(3, 1), {"estabilidad": 3.0}))
	list.append(_make_node("tank_1_4", "Sangre Espesa", "El cuerpo resiste heridas que matarían a otros.", "Resistencia", tank_color, 1, ["tank_0_3"], Vector2i(4, 1), {"vida_base": 15.0}))
	list.append(_make_node("tank_2_0", "Inquebrantable", "Vuelve al Guerrero casi imposible de derribar.", "Resistencia", tank_color, 2, ["tank_1_1"], Vector2i(0, 2), {"estabilidad": 4.0, "vida_base": 10.0}))
	list.append(_make_node("tank_2_1", "Coraza Definitiva", "La máxima expresión de la resistencia física.", "Resistencia", tank_color, 2, ["tank_1_0", "tank_1_2"], Vector2i(1, 2), {"vida_base": 25.0}))
	list.append(_make_node("tank_2_2", "Titán", "Un cuerpo hecho para absorber cualquier golpe.", "Resistencia", tank_color, 2, ["tank_1_1", "tank_1_3"], Vector2i(2, 2), {"estabilidad": 4.0, "vida_base": 10.0}))
	list.append(_make_node("tank_2_3", "Alma de Piedra", "Ni el dolor ni el miedo lo alcanzan ya.", "Resistencia", tank_color, 2, ["tank_1_2", "tank_1_4"], Vector2i(3, 2), {"vida_base": 25.0}))
	list.append(_make_node("tank_2_4", "Fortaleza Eterna", "Una muralla que el tiempo no logra desgastar.", "Resistencia", tank_color, 2, ["tank_1_3"], Vector2i(4, 2), {"estabilidad": 4.0, "vida_base": 10.0}))

	# --- Rama: Agilidad (pestaña 3) ---
	var agi_color := Color(0.35, 0.70, 0.45)
	list.append(_make_node("agi_0_0", "Pies Ligeros", "Mejora la soltura de movimientos.", "Agilidad", agi_color, 1, [], Vector2i(0, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_0_1", "Reflejos Rápidos", "Afila la capacidad de reacción.", "Agilidad", agi_color, 1, [], Vector2i(1, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_0_2", "Paso Ágil", "Cada paso cuesta menos esfuerzo.", "Agilidad", agi_color, 1, [], Vector2i(2, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_0_3", "Instinto Felino", "Anticipa el movimiento antes de que ocurra.", "Agilidad", agi_color, 1, [], Vector2i(3, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_0_4", "Equilibrio Perfecto", "Nunca pierde pie, pase lo que pase.", "Agilidad", agi_color, 1, [], Vector2i(4, 0), {"agilidad": 2.0}))
	list.append(_make_node("agi_1_0", "Danza de Esquiva", "Cada movimiento se vuelve una evasión.", "Agilidad", agi_color, 1, ["agi_0_1"], Vector2i(0, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_1_1", "Paso Fantasma", "Moverse deja de tener resistencia.", "Agilidad", agi_color, 1, ["agi_0_0", "agi_0_2"], Vector2i(1, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_1_2", "Salto Felino", "Salta y cae sin hacer un solo ruido.", "Agilidad", agi_color, 1, ["agi_0_1", "agi_0_3"], Vector2i(2, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_1_3", "Corriente Veloz", "El cuerpo fluye como el agua entre los golpes.", "Agilidad", agi_color, 1, ["agi_0_2", "agi_0_4"], Vector2i(3, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_1_4", "Reacción Instantánea", "Responde antes incluso de pensar.", "Agilidad", agi_color, 1, ["agi_0_3"], Vector2i(4, 1), {"agilidad": 3.0}))
	list.append(_make_node("agi_2_0", "Viento Fugaz", "Una agilidad casi sobrehumana.", "Agilidad", agi_color, 2, ["agi_1_1"], Vector2i(0, 2), {"agilidad": 5.0}))
	list.append(_make_node("agi_2_1", "Sombra Veloz", "Se mueve más rápido de lo que el ojo sigue.", "Agilidad", agi_color, 2, ["agi_1_0", "agi_1_2"], Vector2i(1, 2), {"agilidad": 5.0}))
	list.append(_make_node("agi_2_2", "Ráfaga", "Cruza el campo de batalla en un parpadeo.", "Agilidad", agi_color, 2, ["agi_1_1", "agi_1_3"], Vector2i(2, 2), {"agilidad": 5.0}))
	list.append(_make_node("agi_2_3", "Paso del Vacío", "Se desliza entre los golpes como si no existieran.", "Agilidad", agi_color, 2, ["agi_1_2", "agi_1_4"], Vector2i(3, 2), {"agilidad": 5.0}))
	list.append(_make_node("agi_2_4", "Fantasma Errante", "Nadie logra seguirle el paso.", "Agilidad", agi_color, 2, ["agi_1_3"], Vector2i(4, 2), {"agilidad": 5.0}))

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
