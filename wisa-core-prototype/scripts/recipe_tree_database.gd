extends Resource
class_name RecipeTreeDatabase

## =========================================================
## WisaCore - Árbol de "Recetas" (BASE): la tercera pestaña de la
## ventana de Árboles (tecla T, ver main.gd). Misma FORMA que el árbol
## de Efectos (rejilla 5x5 con conexión en X por vecinos, ver
## SkillTreeGenerators.make_grid_branch()), una rama/pestaña por tipo
## de crafteo: Cocina, Ingeniería, Artesanía Arcana y Artesanía.
##
## Estos nodos todavía NO desbloquean recetas reales del sistema de
## crafteo (RecipeDatabase / Player.known_recipes): de momento es solo
## la progresión visual, igual que arrancaron el resto de árboles de
## esta BASE. Conectar cada nodo con una Recipe real (para que
## desbloquearlo añada esa receta a known_recipes) es el siguiente
## paso natural sobre esta base, cuando se decida qué receta va en cada
## nodo.
## =========================================================

const COLUMNS := 5
const TIERS := 5

const BRANCHES := [
	{"key": "cocina", "name": "Cocina", "color": Color(0.80, 0.55, 0.25)},
	{"key": "ingenieria_craft", "name": "Ingeniería", "color": Color(0.35, 0.45, 0.65)},
	{"key": "arcana", "name": "Artesanía Arcana", "color": Color(0.55, 0.35, 0.75)},
	{"key": "artesania", "name": "Artesanía", "color": Color(0.55, 0.45, 0.30)},
]


static func get_all_nodes() -> Array[SkillNode]:
	var list: Array[SkillNode] = []
	for branch in BRANCHES:
		# stat_key = "" -> sin bonus de stats (ver get_total_skill_bonus
		# en player.gd, que por eso no suma este árbol).
		list.append_array(SkillTreeGenerators.make_grid_branch(branch["key"], branch["name"], branch["color"], "", COLUMNS, TIERS))
	return list
