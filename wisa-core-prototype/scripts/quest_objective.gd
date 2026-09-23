extends Resource
class_name QuestObjective

## =========================================================
## WisaCore - Objetivo individual dentro de una misión
##
## KILL_ENEMIES: "current_amount" lo incrementa Player.register_enemy_kill()
## cada vez que muere un enemigo (llamado desde enemy.gd, igual que ya
## hace _attack_player() al golpear al jugador directamente).
## COLLECT_ITEM: "current_amount" se recalcula en vivo a partir de
## Player.count_item(target_id) -- la misma función que ya usa el
## crafteo para comparar materiales necesarios vs. los que tienes.
## =========================================================

enum Kind { KILL_ENEMIES, COLLECT_ITEM, CUSTOM }

@export var description: String = ""
@export var kind: Kind = Kind.CUSTOM

## item_id (del ItemCatalog) objetivo, solo para COLLECT_ITEM.
@export var target_id: String = ""

@export var required_amount: int = 1
@export var current_amount: int = 0


func is_complete() -> bool:
	return current_amount >= required_amount
