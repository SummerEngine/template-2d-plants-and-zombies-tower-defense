class_name RunStats
extends Node

var defeated_total: int = 0
var defeated_by_type: Dictionary = {}
var waves_started: int = 0


func reset() -> void:
	defeated_total = 0
	defeated_by_type.clear()
	waves_started = 0


func record_wave_started(wave_number: int) -> void:
	waves_started = max(waves_started, wave_number)


func record_enemy_defeated(enemy_kind: String) -> void:
	defeated_total += 1
	defeated_by_type[enemy_kind] = int(defeated_by_type.get(enemy_kind, 0)) + 1


func get_summary_lines() -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("Farmers chased off: %s" % defeated_total)
	var enemy_kinds := defeated_by_type.keys()
	enemy_kinds.sort()
	for enemy_kind in enemy_kinds:
		lines.append("%s: %s" % [_title_case(str(enemy_kind)), int(defeated_by_type[enemy_kind])])
	lines.append("Waves reached: %s" % waves_started)
	return lines


func _title_case(value: String) -> String:
	var words := value.replace("_", " ").split(" ")
	var titled_words := PackedStringArray()
	for index in range(words.size()):
		if words[index].is_empty():
			continue
		titled_words.append(words[index].substr(0, 1).to_upper() + words[index].substr(1))
	return " ".join(titled_words)
