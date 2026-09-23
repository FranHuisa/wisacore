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
const SECTION_KEYBINDS := "keybinds"
const SECTION_SETTINGS := "settings"

## Teclas por defecto de todo lo que abre una ventana. "controls" es la
## nueva ventana pequeña de controles (antes era un texto siempre visible
## en pantalla). Vive aquí (y no en main.gd/player.gd) porque tanto
## main.gd (I/C/H/Q/R/T/E/N) como player.gd (F, recoger) necesitan leer
## y comparar contra las mismas teclas, y así además quedan guardadas.
const DEFAULT_KEYBINDS := {
	"inventory": KEY_I,
	"character": KEY_C,
	"abilities": KEY_H,
	"recipes": KEY_R,
	"quests": KEY_Q,
	"skills": KEY_T,
	"craft": KEY_E,
	"pickup": KEY_F,
	"controls": KEY_N,
}

var gold: int = 0
var keybinds: Dictionary = {}

var master_volume: float = 1.0
var master_muted: bool = false
var fullscreen: bool = false

var _config := ConfigFile.new()


func _ready() -> void:
	_load()


func _load() -> void:
	var err := _config.load(SAVE_PATH)
	if err == OK:
		gold = int(_config.get_value(SECTION, "gold", 0))
		for action in DEFAULT_KEYBINDS.keys():
			keybinds[action] = int(_config.get_value(SECTION_KEYBINDS, action, DEFAULT_KEYBINDS[action]))
		master_volume = float(_config.get_value(SECTION_SETTINGS, "master_volume", 1.0))
		master_muted = bool(_config.get_value(SECTION_SETTINGS, "master_muted", false))
		fullscreen = bool(_config.get_value(SECTION_SETTINGS, "fullscreen", false))
	else:
		gold = 0
		keybinds = DEFAULT_KEYBINDS.duplicate()
		master_volume = 1.0
		master_muted = false
		fullscreen = false


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


## --- Teclas (rebinding) ---

func get_keybind(action: String) -> int:
	return int(keybinds.get(action, DEFAULT_KEYBINDS.get(action, -1)))


func set_keybind(action: String, keycode: int) -> void:
	keybinds[action] = keycode
	_config.set_value(SECTION_KEYBINDS, action, keycode)
	_config.save(SAVE_PATH)


## --- Ajustes (pantalla / audio) ---

func get_master_volume() -> float:
	return master_volume


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_config.set_value(SECTION_SETTINGS, "master_volume", master_volume)
	_config.save(SAVE_PATH)


func get_master_muted() -> bool:
	return master_muted


func set_master_muted(muted: bool) -> void:
	master_muted = muted
	_config.set_value(SECTION_SETTINGS, "master_muted", master_muted)
	_config.save(SAVE_PATH)


func get_fullscreen() -> bool:
	return fullscreen


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_config.set_value(SECTION_SETTINGS, "fullscreen", fullscreen)
	_config.save(SAVE_PATH)
