extends Node

## =========================================================
## WisaCore - Guardado persistente (autoload / singleton)
##
## El proyecto todavía no tenía ningún sistema de guardado, así que
## este script nace centrado en lo que se pide ahora mismo (el oro
## persistente) pero como una base pensada para crecer: cualquier otro
## dato persistente futuro (nivel, posición, inventario completo...)
## puede guardarse con el mismo ConfigFile y la misma sección/patrón,
## sin tener que crear un sistema nuevo desde cero.
##
## Se registra como autoload "GameSave" en project.godot, así que
## cualquier script puede acceder a él simplemente como "GameSave"
## desde cualquier punto del árbol de escenas.
## =========================================================

const SAVE_PATH := "user://savegame.cfg"
const SECTION := "player"

var gold: int = 0

var _config := ConfigFile.new()


func _ready() -> void:
	_load()


func _load() -> void:
	var err := _config.load(SAVE_PATH)
	if err == OK:
		gold = int(_config.get_value(SECTION, "gold", 0))
	else:
		gold = 0


func get_gold() -> int:
	return gold


## Guarda el oro inmediatamente en disco. Se llama cada vez que el oro
## del jugador cambia (ver Player.add_gold / Player.spend_gold), así
## que siempre queda persistido sin tener que gestionar un "punto de
## guardado" aparte.
func set_gold(amount: int) -> void:
	gold = max(0, amount)
	_config.set_value(SECTION, "gold", gold)
	_config.save(SAVE_PATH)
