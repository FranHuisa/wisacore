extends Resource
class_name SkillTreeDatabase

## =========================================================
## WisaCore - Árbol de "Efectos" (BASE): una de las 3 pestañas que
## gestiona la ventana de Árboles (tecla T, ver main.gd), junto con el
## árbol de Habilidades (weapon_skill_tree_database.gd) y el de Recetas
## (recipe_tree_database.gd). Este es el árbol de atributos/stats: 8
## ramas (pestañas), 5 columnas x 5 niveles cada una, generadas con
## SkillTreeGenerators.make_grid_branch() (rejilla con conexión en X
## por vecinos - ver ese script para el detalle de la forma).
##
## Con 8 ramas x 25 nodos (200 en total) escribir cada nodo a mano ya
## no es práctico: aquí solo se define QUÉ rama hay y qué atributo de
## StatBlock sube cada una (mismas claves que ItemData.stat_bonuses:
## estabilidad, agilidad, destreza, punteria, fuerza, voluntad,
## canalizacion, conexion_elemental, vida_base, aguante_base,
## mana_base); nombres y bonus genéricos ("Guerrero 3.2" = rama
## Guerrero, nivel 3, columna 2), listos para rebautizarse uno a uno
## más adelante sin tocar el resto del sistema.
##
## Igual que RecipeDatabase/QuestDatabase: crea instancias NUEVAS cada
## vez que se llama, así que player.gd la llama una sola vez en
## _ready() y guarda el resultado en Player.skill_tree_nodes.
## =========================================================

const COLUMNS := 5
const TIERS := 5

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
		list.append_array(SkillTreeGenerators.make_grid_branch(branch["key"], branch["name"], branch["color"], branch["stat"], COLUMNS, TIERS))
	return list
