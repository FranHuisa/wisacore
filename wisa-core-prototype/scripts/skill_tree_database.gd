extends Resource
class_name SkillTreeDatabase

## =========================================================
## WisaCore - Árbol de habilidades: contenido de ejemplo (BASE)
##
## 8 ramas (una pestaña cada una): Guerrero, Pícaro, Clérigo, Mago,
## Ingeniero, Elaboración, Ingeniería y Competencias. Cada una tiene 5
## columnas (0 a 4) por 5 niveles (0 = abajo del todo, sube hacia
## arriba).
##
## Con 8 ramas x 5 columnas x 5 niveles (200 nodos) escribir cada nodo
## a mano ya no es práctico, así que esta BASE los genera por código
## con _make_branch(): nombres y bonus genéricos ("Guerrero 3.2" = rama
## Guerrero, nivel 3, columna 2), listos para que se rebauticen uno a
## uno más adelante sin tocar el resto del sistema (ni main.gd ni
## Player). Lo único que hay que cambiar aquí para ajustar el
## contenido real es la lista BRANCHES de más abajo.
##
## Conexión en X por VECINOS (igual que antes, ahora con 5 niveles):
## cada nodo requiere sus dos vecinos diagonales de la fila de abajo
## (columna - 1 y columna + 1, los que existan) -> el "2" de una fila
## conecta con el "1" y el "3" de la fila de arriba, y viceversa.
##
##   Fila 2:   1     2     3     4     5
##              \   / \   / \   / \   /
##   Fila 1:   1     2     3     4     5
##
## Las columnas de los extremos (1 y 5) solo tienen un vecino, así que
## solo piden esa única columna; las del medio piden las DOS columnas
## vecinas de abajo (AND). Se repite igual entre cada dos niveles según
## se sube.
##
## Igual que RecipeDatabase/QuestDatabase: crea instancias NUEVAS cada
## vez que se llama, así que player.gd la llama una sola vez en
## _ready() y guarda el resultado en Player.skill_tree_nodes.
## =========================================================

const COLUMNS := 5
const TIERS := 5

## Una entrada por rama/pestaña: clave interna (para los IDs de nodo),
## nombre visible, color y qué atributo de StatBlock sube (mismas
## claves que ItemData.stat_bonuses: estabilidad, agilidad, destreza,
## punteria, fuerza, voluntad, canalizacion, conexion_elemental,
## vida_base, aguante_base, mana_base).
const BRANCHES := [
	{"key": "guerrero", "name": "Guerrero", "color": Color(0.70, 0.20, 0.25), "stat": "fuerza"},
	{"key": "picaro", "name": "Pícaro", "color": Color(0.35, 0.70, 0.45), "stat": "agilidad"},
	{"key": "clerigo", "name": "Clérigo", "color": Color(0.85, 0.75, 0.35), "stat": "voluntad"},
	{"key": "mago", "name": "Mago", "color": Color(0.45, 0.35, 0.75), "stat": "canalizacion"},
	{"key": "ingeniero", "name": "Ingeniero", "color": Color(0.80, 0.50, 0.20), "stat": "destreza"},
	{"key": "elaboracion", "name": "Elaboración", "color": Color(0.30, 0.65, 0.65), "stat": "punteria"},
	{"key": "ingenieria", "name": "Ingeniería", "color": Color(0.35, 0.45, 0.65), "stat": "conexion_elemental"},
	{"key": "competencias", "name": "Competencias", "color": Color(0.55, 0.55, 0.55), "stat": "estabilidad"},
]


static func get_all_nodes() -> Array[SkillNode]:
	var list: Array[SkillNode] = []
	for branch in BRANCHES:
		list.append_array(_make_branch(branch["key"], branch["name"], branch["color"], branch["stat"]))
	return list


static func _make_branch(key: String, branch_name: String, color: Color, stat_key: String) -> Array[SkillNode]:
	var nodes: Array[SkillNode] = []
	for tier in range(TIERS):
		for col in range(COLUMNS):
			var id := "%s_%d_%d" % [key, tier, col]

			# Vecinos diagonales de la fila de abajo (los que existan).
			var requires: Array[String] = []
			if tier > 0:
				if col - 1 >= 0:
					requires.append("%s_%d_%d" % [key, tier - 1, col - 1])
				if col + 1 < COLUMNS:
					requires.append("%s_%d_%d" % [key, tier - 1, col + 1])

			var cost := 1 + int(tier / 2.0)
			var bonus_value := 2.0 + float(tier) * 1.5
			var node_name := "%s %d.%d" % [branch_name, tier + 1, col + 1]
			var desc := "Mejora de la rama %s (nivel %d, columna %d)." % [branch_name, tier + 1, col + 1]

			nodes.append(_make_node(id, node_name, desc, branch_name, color, cost, requires, Vector2i(col, tier), {stat_key: bonus_value}))
	return nodes


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
