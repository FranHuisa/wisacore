extends Resource
class_name SkillNode

## =========================================================
## WisaCore - Nodo del árbol de habilidades
##
## Un Resource de datos puro (igual espíritu que Recipe/Quest): sin
## lógica de negocio. La lógica de desbloqueo vive en player.gd
## (can_unlock_skill / unlock_skill) y el dibujado en main.gd.
##
## "stat_bonuses" usa las MISMAS claves que ItemData.stat_bonuses
## (estabilidad, agilidad, destreza, punteria, fuerza, voluntad,
## canalizacion, conexion_elemental, vida_base, aguante_base,
## mana_base), así que Player.recalculate_stats() puede sumarlas
## exactamente igual que ya hace con el equipo.
## =========================================================

@export var skill_id: String = ""
@export var skill_name: String = "Habilidad"
@export var description: String = ""

## Nombre de la rama a la que pertenece, solo para agrupar visualmente
## (color y organización en la ventana). No afecta a la lógica.
@export var branch: String = ""
@export var color: Color = Color(0.5, 0.5, 0.5)

## Coste en puntos de habilidad para desbloquearlo.
@export var cost: int = 1

## IDs de otros SkillNode que deben estar desbloqueados antes que este.
## Vacío = disponible desde el principio (raíz de una rama).
@export var requires: Array[String] = []

## Posición en la rejilla del árbol: x = columna (rama), y = fila (tier).
## Puramente visual, la usa main.gd para colocar el nodo y trazar las
## líneas de conexión con sus prerrequisitos.
@export var grid_position: Vector2i = Vector2i.ZERO

## Bonus de atributos que aporta al desbloquearlo. Mismo formato que
## ItemData.stat_bonuses.
@export var stat_bonuses: Dictionary = {}
