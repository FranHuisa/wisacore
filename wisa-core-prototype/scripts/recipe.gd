extends Resource
class_name Recipe

## =========================================================
## WisaCore - Receta de crafteo
## "materials" es un Dictionary item_id (String) -> cantidad (int)
## necesaria. "unlocked" indica si el jugador puede craftearla ya;
## más adelante esto se podrá cambiar en tiempo real cuando exista
## un sistema de desbloqueo (por descubrimiento, nivel, NPC, etc.).
## =========================================================

@export var recipe_name: String = "Receta"
@export var description: String = ""
@export var result_id: String = ""
@export var result_quantity: int = 1
@export var materials: Dictionary = {}
@export var unlocked: bool = true
