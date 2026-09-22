extends Resource
class_name RecipeDatabase

## =========================================================
## WisaCore - Lista de recetas conocidas por el juego.
##
## get_all_recipes() crea instancias NUEVAS de Recipe cada vez que se
## llama. Por eso player.gd la llama una única vez en _ready() y
## guarda el resultado en player.known_recipes: así el estado de
## "unlocked" de cada receta persiste durante la partida en vez de
## reiniciarse cada vez que se abre una ventana.
## =========================================================

static func get_all_recipes() -> Array[Recipe]:
	var list: Array[Recipe] = []

	var r1 := Recipe.new()
	r1.recipe_name = "Barra de Hierro"
	r1.description = "Funde mineral de hierro usando madera como combustible."
	r1.result_id = "iron_bar"
	r1.result_quantity = 1
	r1.materials = {"iron_ore": 2, "wood": 1}
	r1.unlocked = true
	list.append(r1)

	var r2 := Recipe.new()
	r2.recipe_name = "Casco de Hierro Forjado"
	r2.description = "Un casco resistente forjado a partir de barras de hierro, con un ribete de cuero."
	r2.result_id = "iron_helmet_forged"
	r2.result_quantity = 1
	r2.materials = {"iron_bar": 3, "leather": 1}
	r2.unlocked = false  # Ejemplo de receta bloqueada (pendiente de sistema de desbloqueo)
	list.append(r2)

	var r3 := Recipe.new()
	r3.recipe_name = "Vendaje de Tela"
	r3.description = "Un vendaje improvisado. Poco elaborado, pero útil en apuros."
	r3.result_id = "cloth_bandage"
	r3.result_quantity = 2
	r3.materials = {"cloth": 2}
	r3.unlocked = true
	list.append(r3)

	return list
