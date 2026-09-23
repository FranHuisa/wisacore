extends Resource
class_name SkillTreeDatabase

## =========================================================
## WisaCore - Árbol de habilidades: contenido de ejemplo (BASE)
##
## Esto es una base de partida con 3 ramas de ejemplo (Combate,
## Resistencia, Agilidad) a 3 niveles cada una, pensada para validar
## la ventana y el flujo de desbloqueo. Los nombres, bonus, costes y
## número de ramas/niveles son fáciles de cambiar aquí sin tocar
## ninguna otra parte del sistema (ventana, Player, guardado).
##
## Igual que RecipeDatabase/QuestDatabase: crea instancias NUEVAS cada
## vez que se llama, así que player.gd la llama una sola vez en
## _ready() y guarda el resultado en Player.skill_tree_nodes.
## =========================================================

static func get_all_nodes() -> Array[SkillNode]:
	var list: Array[SkillNode] = []

	# --- Rama: Combate (columna 0) ---
	var combat_color := Color(0.70, 0.20, 0.25)

	var combat1 := SkillNode.new()
	combat1.skill_id = "combat_1"
	combat1.skill_name = "Golpe Certero"
	combat1.description = "Afina la técnica de ataque cuerpo a cuerpo."
	combat1.branch = "Combate"
	combat1.color = combat_color
	combat1.cost = 1
	combat1.requires = []
	combat1.grid_position = Vector2i(0, 0)
	combat1.stat_bonuses = {"fuerza": 2.0}
	list.append(combat1)

	var combat2 := SkillNode.new()
	combat2.skill_id = "combat_2"
	combat2.skill_name = "Furia de Batalla"
	combat2.description = "Intensifica la fuerza de cada golpe en combate."
	combat2.branch = "Combate"
	combat2.color = combat_color
	combat2.cost = 1
	combat2.requires = ["combat_1"]
	combat2.grid_position = Vector2i(0, 1)
	combat2.stat_bonuses = {"fuerza": 3.0}
	list.append(combat2)

	var combat3 := SkillNode.new()
	combat3.skill_id = "combat_3"
	combat3.skill_name = "Maestría Marcial"
	combat3.description = "Dominio total del combate cuerpo a cuerpo."
	combat3.branch = "Combate"
	combat3.color = combat_color
	combat3.cost = 2
	combat3.requires = ["combat_2"]
	combat3.grid_position = Vector2i(0, 2)
	combat3.stat_bonuses = {"fuerza": 6.0}
	list.append(combat3)

	# --- Rama: Resistencia (columna 1) ---
	var tank_color := Color(0.35, 0.55, 0.75)

	var tank1 := SkillNode.new()
	tank1.skill_id = "tank_1"
	tank1.skill_name = "Piel de Acero"
	tank1.description = "Refuerza la estabilidad ante los golpes."
	tank1.branch = "Resistencia"
	tank1.color = tank_color
	tank1.cost = 1
	tank1.requires = []
	tank1.grid_position = Vector2i(1, 0)
	tank1.stat_bonuses = {"estabilidad": 2.0}
	list.append(tank1)

	var tank2 := SkillNode.new()
	tank2.skill_id = "tank_2"
	tank2.skill_name = "Vitalidad"
	tank2.description = "Aumenta la reserva de vida máxima."
	tank2.branch = "Resistencia"
	tank2.color = tank_color
	tank2.cost = 1
	tank2.requires = ["tank_1"]
	tank2.grid_position = Vector2i(1, 1)
	tank2.stat_bonuses = {"vida_base": 15.0}
	list.append(tank2)

	var tank3 := SkillNode.new()
	tank3.skill_id = "tank_3"
	tank3.skill_name = "Inquebrantable"
	tank3.description = "Vuelve al Guerrero casi imposible de derribar."
	tank3.branch = "Resistencia"
	tank3.color = tank_color
	tank3.cost = 2
	tank3.requires = ["tank_2"]
	tank3.grid_position = Vector2i(1, 2)
	tank3.stat_bonuses = {"estabilidad": 4.0, "vida_base": 20.0}
	list.append(tank3)

	# --- Rama: Agilidad (columna 2) ---
	var agi_color := Color(0.35, 0.70, 0.45)

	var agi1 := SkillNode.new()
	agi1.skill_id = "agi_1"
	agi1.skill_name = "Pies Ligeros"
	agi1.description = "Mejora los reflejos y la soltura de movimientos."
	agi1.branch = "Agilidad"
	agi1.color = agi_color
	agi1.cost = 1
	agi1.requires = []
	agi1.grid_position = Vector2i(2, 0)
	agi1.stat_bonuses = {"agilidad": 2.0}
	list.append(agi1)

	var agi2 := SkillNode.new()
	agi2.skill_id = "agi_2"
	agi2.skill_name = "Reflejos"
	agi2.description = "Afila la capacidad de reacción en combate."
	agi2.branch = "Agilidad"
	agi2.color = agi_color
	agi2.cost = 1
	agi2.requires = ["agi_1"]
	agi2.grid_position = Vector2i(2, 1)
	agi2.stat_bonuses = {"agilidad": 3.0}
	list.append(agi2)

	var agi3 := SkillNode.new()
	agi3.skill_id = "agi_3"
	agi3.skill_name = "Viento Fugaz"
	agi3.description = "Una agilidad casi sobrehumana."
	agi3.branch = "Agilidad"
	agi3.color = agi_color
	agi3.cost = 2
	agi3.requires = ["agi_2"]
	agi3.grid_position = Vector2i(2, 2)
	agi3.stat_bonuses = {"agilidad": 5.0}
	list.append(agi3)

	return list
