extends Resource
class_name Quest

## =========================================================
## WisaCore - Misión
## Igual de espíritu que Recipe (scripts/recipe.gd): un Resource de
## datos simple, sin lógica de negocio; la lógica vive en player.gd
## (register_enemy_kill, claim_quest_reward) y en main.gd (la ventana).
## =========================================================

@export var quest_id: String = ""
@export var quest_name: String = "Misión"
@export var description: String = ""
@export var objectives: Array[QuestObjective] = []

@export var reward_gold: int = 0
@export var reward_item_id: String = ""
@export var reward_item_quantity: int = 1

## Se pone a true cuando se reclama la recompensa (Player.claim_quest_reward).
@export var completed: bool = false


func is_complete() -> bool:
	for objective in objectives:
		if not objective.is_complete():
			return false
	return not objectives.is_empty()
