class_name StatBuffEffect
extends AbilityEffect

@export var modifiers: Array[StatModifier]
@export var duration := 5.0

#region Effect
# Applies the modifiers now and withdraws them when the duration ends.
func apply(context: AbilityComponent) -> void:
	context.stats.add_modifiers(self, modifiers)
	context.get_tree().create_timer(duration).timeout.connect(context.stats.remove_modifiers.bind(self, modifiers))
#endregion
