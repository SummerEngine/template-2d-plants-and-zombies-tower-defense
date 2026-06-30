class_name ResourceSystem
extends Node

signal changed(amount: int)

@export var starting_energy: int = 125
@export var max_energy: int = 300
@export var energy_per_second: float = 4.0

var energy: int = 0
var _fractional_energy: float = 0.0


func _ready() -> void:
	reset()


func _process(delta: float) -> void:
	_fractional_energy += energy_per_second * delta
	if _fractional_energy >= 1.0:
		var gained := int(_fractional_energy)
		_fractional_energy -= gained
		add_energy(gained)


func reset() -> void:
	energy = starting_energy
	_fractional_energy = 0.0
	changed.emit(energy)


func can_spend(cost: int) -> bool:
	return energy >= cost


func spend(cost: int) -> bool:
	if not can_spend(cost):
		return false

	energy -= cost
	changed.emit(energy)
	return true


func add_energy(amount: int) -> void:
	var next_energy := clampi(energy + amount, 0, max_energy)
	if next_energy == energy:
		return

	energy = next_energy
	changed.emit(energy)
