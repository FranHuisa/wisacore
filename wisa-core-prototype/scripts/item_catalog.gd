extends Resource
class_name ItemCatalog

## =========================================================
## WisaCore - Catálogo de objetos por item_id
##
## Punto único donde se definen los materiales y objetos que puede
## producir el sistema de crafteo. Usar siempre ItemCatalog.get_item(id)
## en vez de crear un ItemData nuevo a mano, para que dos referencias
## al mismo id (p. ej. "iron_ore" pedido por una receta y "iron_ore"
## en la mochila) compartan item_id y se apilen/comparen bien.
## =========================================================

static var _cache: Dictionary = {}


static func get_item(id: String) -> ItemData:
	if _cache.has(id):
		return _cache[id]
	var item := _build_item(id)
	_cache[id] = item
	return item


static func _build_item(id: String) -> ItemData:
	var item := ItemData.new()
	item.item_id = id

	match id:
		"iron_ore":
			item.item_name = "Mineral de Hierro"
			item.item_type = ItemData.ItemType.MATERIAL
			item.stack_size = 20
			item.rarity = ItemData.Rarity.COMUN
			item.color = Color(0.5, 0.35, 0.3)
			item.description = "Mineral en bruto. Se puede fundir para forjar equipo básico."
		"wood":
			item.item_name = "Madera"
			item.item_type = ItemData.ItemType.MATERIAL
			item.stack_size = 20
			item.rarity = ItemData.Rarity.COMUN
			item.color = Color(0.45, 0.32, 0.20)
			item.description = "Troncos cortados, listos para usar como combustible o material de construcción."
		"leather":
			item.item_name = "Cuero"
			item.item_type = ItemData.ItemType.MATERIAL
			item.stack_size = 20
			item.rarity = ItemData.Rarity.COMUN
			item.color = Color(0.42, 0.28, 0.20)
			item.description = "Piel curtida, flexible y resistente."
		"cloth":
			item.item_name = "Tela"
			item.item_type = ItemData.ItemType.MATERIAL
			item.stack_size = 20
			item.rarity = ItemData.Rarity.COMUN
			item.color = Color(0.75, 0.72, 0.60)
			item.description = "Retazos de tela basta. Útil para vendajes y forros."
		"iron_bar":
			item.item_name = "Barra de Hierro"
			item.item_type = ItemData.ItemType.MATERIAL
			item.stack_size = 20
			item.rarity = ItemData.Rarity.POCO_COMUN
			item.color = Color(0.65, 0.65, 0.70)
			item.description = "Hierro fundido y moldeado en una barra lista para forjar."
		"iron_helmet_forged":
			item.item_name = "Casco de Hierro Forjado"
			item.item_type = ItemData.ItemType.EQUIPO
			item.equip_slot = Equipment.Slot.CABEZA
			item.rarity = ItemData.Rarity.RARO
			item.color = Color(0.6, 0.6, 0.65)
			item.description = "Casco forjado a mano a partir de barras de hierro. Sólido y fiable."
			item.stat_bonuses = {"estabilidad": 6.0}
		"cloth_bandage":
			item.item_name = "Vendaje de Tela"
			item.item_type = ItemData.ItemType.CONSUMIBLE
			item.stack_size = 10
			item.rarity = ItemData.Rarity.COMUN
			item.color = Color(0.80, 0.78, 0.70)
			item.description = "Un vendaje improvisado. Poco elaborado, pero útil en apuros."
		"gold_coin":
			item.item_name = "Bolsa de Oro"
			item.item_type = ItemData.ItemType.MATERIAL
			item.stack_size = 999
			item.rarity = ItemData.Rarity.COMUN
			item.color = Color(0.85, 0.65, 0.15)
			item.is_currency = true
			item.description = "Un puñado de monedas. Se añade directamente a tu oro al recogerla, no ocupa hueco en la mochila."
		_:
			push_warning("ItemCatalog: item_id desconocido '%s'" % id)
			item.item_name = "Objeto desconocido (%s)" % id

	return item
