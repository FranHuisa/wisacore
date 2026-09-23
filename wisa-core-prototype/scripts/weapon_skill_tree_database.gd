extends Resource
class_name WeaponSkillTreeDatabase

## =========================================================
## WisaCore - Árbol de "Habilidades" (BASE): otra de las 3 pestañas de
## la ventana de Árboles (tecla T, ver main.gd). Distinto en FORMA del
## árbol de Efectos (rejilla 5x5 por vecinos): aquí cada clase empieza
## en un único nodo "Nivel 1" y se abre ("se divide") en tantos
## carriles como armas tenga esa clase, cada uno subiendo en línea
## recta hasta el nivel 5. Además hay una pestaña aparte para Escudo
## (un solo carril, sin clase asociada).
##
## La forma (raíz + carriles) la genera
## SkillTreeGenerators.make_fanout_branch(); aquí solo se define qué
## arma tiene cada clase y qué atributo de StatBlock sube.
## =========================================================

const LEVELS := 5

const CLASSES := [
	{"key": "guerrero_arma", "name": "Guerrero", "color": Color(0.70, 0.20, 0.25), "stat": "fuerza",
		"weapons": ["Espada", "Hacha", "Lanza", "Maza"]},
	{"key": "mago_arma", "name": "Mago", "color": Color(0.45, 0.35, 0.75), "stat": "canalizacion",
		"weapons": ["Bastón", "Orbe", "Cetro"]},
	{"key": "clerigo_arma", "name": "Clérigo", "color": Color(0.85, 0.75, 0.35), "stat": "voluntad",
		"weapons": ["Bastón", "Talismán", "Grimorio"]},
	{"key": "picaro_arma", "name": "Pícaro", "color": Color(0.35, 0.70, 0.45), "stat": "agilidad",
		"weapons": ["Dagas", "Arco corto", "Arco largo", "Garras"]},
	{"key": "ingeniero_arma", "name": "Ingeniero", "color": Color(0.80, 0.50, 0.20), "stat": "destreza",
		"weapons": ["Revólver", "Rifle", "Cuchillas mecánicas", "Guanteletes mecánicos", "Martillo mecánico"]},
	{"key": "escudo", "name": "Escudo", "color": Color(0.55, 0.55, 0.60), "stat": "estabilidad",
		"weapons": ["Escudo"]},
]


static func get_all_nodes() -> Array[SkillNode]:
	var list: Array[SkillNode] = []
	for entry in CLASSES:
		var weapons: Array = entry["weapons"]
		var lane_names: Array[String] = []
		var lane_keys: Array[String] = []
		for weapon_name in weapons:
			lane_names.append(weapon_name)
			lane_keys.append(_slug(weapon_name))
		list.append_array(SkillTreeGenerators.make_fanout_branch(entry["key"], entry["name"], entry["color"], entry["stat"], lane_keys, lane_names, LEVELS))
	return list


## IDs internos estables (minúsculas, sin espacios ni acentos) para
## usarlos como parte del skill_id: "Arco corto" -> "arco_corto".
static func _slug(text: String) -> String:
	var result := text.to_lower()
	result = result.replace(" ", "_")
	result = result.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
	return result
