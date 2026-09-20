extends Resource
class_name Inventory

## =========================================================
## WisaCore - Mochila / inventario (5x5 = 25 ranuras)
## Cada ranura es null (vacía) o un Dictionary {"item": ItemData,
## "quantity": int}.
## =========================================================

const COLUMNS := 5
const ROWS := 5
const SIZE := COLUMNS * ROWS

var slots: Array = []


func _init() -> void:
	slots.resize(SIZE)
	for i in range(SIZE):
		slots[i] = null


func add_item(item: ItemData, quantity: int = 1) -> bool:
	# Primero intenta apilar sobre slots existentes del mismo objeto.
	if item.stack_size > 1:
		for i in range(SIZE):
			var entry = slots[i]
			if entry != null and entry["item"] == item and entry["quantity"] < item.stack_size:
				var space: int = item.stack_size - entry["quantity"]
				var to_add: int = min(space, quantity)
				entry["quantity"] += to_add
				quantity -= to_add
				if quantity <= 0:
					return true

	# Luego busca una ranura vacía.
	for i in range(SIZE):
		if slots[i] == null:
			slots[i] = {"item": item, "quantity": quantity}
			return true

	return false  # Inventario lleno


func find_first_empty() -> int:
	for i in range(SIZE):
		if slots[i] == null:
			return i
	return -1


func remove_at(index: int) -> void:
	slots[index] = null


func set_at(index: int, entry) -> void:
	slots[index] = entry


func get_at(index: int):
	return slots[index]
