extends Resource
class_name Equipment

## =========================================================
## WisaCore - Ranuras de equipamiento del personaje
## Cabeza, Pecho, Manos, Piernas, Pies, 2 Accesorios,
## Arma y Arma secundaria.
## =========================================================

enum Slot {
	CABEZA,
	PECHO,
	MANOS,
	PIERNAS,
	PIES,
	ACCESORIO_1,
	ACCESORIO_2,
	ARMA,
	ARMA_SECUNDARIA,
}

const SLOT_NAMES := {
	Slot.CABEZA: "Cabeza",
	Slot.PECHO: "Pecho",
	Slot.MANOS: "Manos",
	Slot.PIERNAS: "Piernas",
	Slot.PIES: "Pies",
	Slot.ACCESORIO_1: "Accesorio 1",
	Slot.ACCESORIO_2: "Accesorio 2",
	Slot.ARMA: "Arma",
	Slot.ARMA_SECUNDARIA: "Arma secundaria",
}

var slots: Dictionary = {}


func _init() -> void:
	for slot in Slot.values():
		slots[slot] = null


func equip(slot: int, item: ItemData) -> ItemData:
	var previous: ItemData = slots[slot]
	slots[slot] = item
	return previous


func unequip(slot: int) -> ItemData:
	var previous: ItemData = slots[slot]
	slots[slot] = null
	return previous


func get_total_bonus() -> Dictionary:
	var totals := {
		"estabilidad": 0.0, "agilidad": 0.0, "destreza": 0.0, "punteria": 0.0,
		"fuerza": 0.0, "voluntad": 0.0, "canalizacion": 0.0, "conexion_elemental": 0.0,
		"vida_base": 0.0, "aguante_base": 0.0, "mana_base": 0.0,
	}
	for slot in slots.keys():
		var item: ItemData = slots[slot]
		if item == null:
			continue
		for key in item.stat_bonuses.keys():
			if totals.has(key):
				totals[key] += item.stat_bonuses[key]
	return totals
