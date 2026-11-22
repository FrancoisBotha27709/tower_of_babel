class_name HealEffect
extends AbilityEffect

@export var heal_amount := 25.0

#region Effect
# Only worth applying when hurt and still alive.
func can_apply(context: AbilityComponent) -> bool:
	return not context.health.is_dead() and context.health.current_health < context.health.maximum_health

# Restores health.
func apply(context: AbilityComponent) -> void:
	context.health.heal(heal_amount)
#endregion
