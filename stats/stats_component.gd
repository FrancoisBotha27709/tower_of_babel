class_name StatsComponent
extends Node

signal stat_changed(stat: StatDefinition)

var sources: Dictionary[Resource, Array]

#region Modifiers
# Registers modifiers under a source so they can be withdrawn together later.
func add_modifiers(source: Resource, modifiers: Array[StatModifier]) -> void:
	sources.get_or_add(source, []).append_array(modifiers)
	announce(modifiers)

# Removes one copy of each modifier from a source and forgets the source once empty.
func remove_modifiers(source: Resource, modifiers: Array[StatModifier]) -> void:
	var held: Array = sources.get(source, [])
	for modifier in modifiers:
		held.erase(modifier)
	if held.is_empty():
		sources.erase(source)
	announce(modifiers)

# Tells listeners which stats just changed.
func announce(modifiers: Array[StatModifier]) -> void:
	for modifier in modifiers:
		if modifier.stat:
			stat_changed.emit(modifier.stat)
#endregion

#region Query
# Final value of a stat: (base + flat bonuses) * (1 + percent bonuses), clamped to the stat's limits.
func get_value(stat: StatDefinition, base_value := 0.0) -> float:
	var flat_total := 0.0
	var percent_total := 0.0
	for held: Array in sources.values():
		for modifier: StatModifier in held:
			if modifier.stat == stat:
				flat_total += modifier.flat_bonus
				percent_total += modifier.percent_bonus
	return clampf((base_value + flat_total) * (1.0 + percent_total), stat.minimum_value, stat.maximum_value)
#endregion
