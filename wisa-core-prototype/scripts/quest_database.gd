extends Resource
class_name QuestDatabase

## =========================================================
## WisaCore - Lista de misiones iniciales del jugador.
##
## Igual que RecipeDatabase.get_all_recipes(), crea instancias NUEVAS
## cada vez que se llama, así que player.gd la llama una única vez en
## _ready() y guarda el resultado en Player.active_quests para que el
## progreso persista durante la partida.
## =========================================================

static func get_starting_quests() -> Array[Quest]:
	var list: Array[Quest] = []

	var q1 := Quest.new()
	q1.quest_id = "hunt_aberrations"
	q1.quest_name = "Limpieza de Aberraciones"
	q1.description = "El pueblo necesita que reduzcas el número de Aberraciones de la zona."
	var obj1 := QuestObjective.new()
	obj1.description = "Derrota Aberraciones"
	obj1.kind = QuestObjective.Kind.KILL_ENEMIES
	obj1.required_amount = 3
	q1.objectives = [obj1]
	q1.reward_gold = 25
	list.append(q1)

	var q2 := Quest.new()
	q2.quest_id = "gather_iron"
	q2.quest_name = "Mineral para el Herrero"
	q2.description = "Recolecta mineral de hierro para las forjas del pueblo."
	var obj2 := QuestObjective.new()
	obj2.description = "Consigue Mineral de Hierro"
	obj2.kind = QuestObjective.Kind.COLLECT_ITEM
	obj2.target_id = "iron_ore"
	obj2.required_amount = 10
	q2.objectives = [obj2]
	q2.reward_gold = 15
	q2.reward_item_id = "cloth_bandage"
	q2.reward_item_quantity = 2
	list.append(q2)

	return list
