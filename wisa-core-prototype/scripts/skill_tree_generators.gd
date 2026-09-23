extends RefCounted
class_name SkillTreeGenerators

## =========================================================
## WisaCore - Generadores de formas de árbol, compartidos por los 3
## *_database.gd (SkillTreeDatabase = Efectos, WeaponSkillTreeDatabase =
## Habilidades, RecipeTreeDatabase = Recetas), para no repetir la misma
## lógica de generación en cada uno. Cada *_database.gd solo dice QUÉ
## ramas/nombres/colores/stat tiene; el CÓMO se coloca y conecta cada
## nodo vive aquí.
## =========================================================

## --- Rejilla (columnas x niveles), conexión en X por VECINOS ---
##
## Cada nodo requiere sus dos vecinos diagonales de la fila de abajo
## (columna - 1 y columna + 1, los que existan): el nodo de en medio de
## una fila conecta con los dos vecinos de la fila de arriba y
## viceversa, formando una X entre cada dos columnas vecinas. Lo usan
## el árbol de Efectos y el árbol de Recetas.
##
## "stat_key" vacío ("") = los nodos no dan bonus de stats (caso de
## Recetas, que todavía no desbloquea nada del sistema de crafteo real,
## solo es la progresión visual de esta BASE).
static func make_grid_branch(key: String, branch_name: String, color: Color, stat_key: String, columns: int, tiers: int) -> Array[SkillNode]:
	var nodes: Array[SkillNode] = []
	for tier in range(tiers):
		for col in range(columns):
			var id := "%s_%d_%d" % [key, tier, col]

			var requires: Array[String] = []
			if tier > 0:
				if col - 1 >= 0:
					requires.append("%s_%d_%d" % [key, tier - 1, col - 1])
				if col + 1 < columns:
					requires.append("%s_%d_%d" % [key, tier - 1, col + 1])

			var cost := 1 + int(tier / 2.0)
			var bonuses: Dictionary = {}
			if stat_key != "":
				bonuses[stat_key] = 2.0 + float(tier) * 1.5

			var node_name := "%s %d.%d" % [branch_name, tier + 1, col + 1]
			var desc := "Mejora de la rama %s (nivel %d, columna %d)." % [branch_name, tier + 1, col + 1]

			nodes.append(make_node(id, node_name, desc, branch_name, color, cost, requires, Vector2i(col, tier), bonuses))
	return nodes


## --- Abanico (raíz única + N carriles en paralelo) ---
##
## Un solo nodo raíz en el nivel 0 ("empieza en nivel 1") del que
## salen "lane_keys.size()" carriles (uno por arma), cada uno subiendo
## en línea recta hasta "levels - 1" niveles más arriba: el primer nodo
## de cada carril requiere solo la raíz, y cada nodo siguiente requiere
## el anterior del MISMO carril. Lo usa el árbol de Habilidades (una
## rama por clase + Escudo).
static func make_fanout_branch(key: String, branch_name: String, color: Color, stat_key: String, lane_keys: Array[String], lane_names: Array[String], levels: int) -> Array[SkillNode]:
	var nodes: Array[SkillNode] = []
	var lane_count := lane_keys.size()
	var root_col := int((lane_count - 1) / 2.0)
	var root_id := "%s_root" % key

	nodes.append(make_node(root_id, "%s (Nivel 1)" % branch_name, "Punto de partida de la rama %s." % branch_name, branch_name, color, 0, [], Vector2i(root_col, 0), {}))

	var costs := [1, 1, 2, 2, 3, 3, 4, 4]
	var bonus_values := [1.5, 2.5, 3.5, 5.0, 6.5, 8.0, 9.5, 11.0]
	var numerals := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]

	for lane_idx in range(lane_count):
		var lane_key: String = lane_keys[lane_idx]
		var lane_name: String = lane_names[lane_idx]
		var previous_id := root_id
		for level in range(1, levels):
			var id := "%s_%s_%d" % [key, lane_key, level]
			var idx: int = min(level - 1, costs.size() - 1)
			var cost: int = costs[idx]
			var bonuses: Dictionary = {}
			if stat_key != "":
				bonuses[stat_key] = bonus_values[idx]
			var numeral: String = numerals[idx] if idx < numerals.size() else str(level)
			var node_name := "%s %s" % [lane_name, numeral]
			var desc := "Progresión con %s (rama %s, nivel %d)." % [lane_name, branch_name, level + 1]

			nodes.append(make_node(id, node_name, desc, branch_name, color, cost, [previous_id], Vector2i(lane_idx, level), bonuses))
			previous_id = id
	return nodes


static func make_node(id: String, name: String, desc: String, branch: String, color: Color, cost: int, requires: Array[String], grid_pos: Vector2i, bonuses: Dictionary) -> SkillNode:
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
