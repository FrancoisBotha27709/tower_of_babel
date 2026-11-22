class_name StatBinder
extends Node

@export var stats: StatsComponent
@export var target: Node
@export var stat: StatDefinition
@export var property := &""

var base_value := 0.0

#region Lifecycle
# Remembers the property's own value as the base and keeps it in sync with the stat.
func _ready() -> void:
	base_value = float(target.get(property))
	stats.stat_changed.connect(on_stat_changed)
	apply()
#endregion

#region Sync
# Re-applies the property when the bound stat changes.
func on_stat_changed(changed: StatDefinition) -> void:
	if changed == stat:
		apply()

# Writes the stat's final value onto the target property.
func apply() -> void:
	target.set(property, stats.get_value(stat, base_value))
#endregion
