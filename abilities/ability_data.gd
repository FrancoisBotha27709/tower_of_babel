class_name AbilityData
extends Resource

@export var display_name := ""
@export var icon: Texture2D
@export var input_action := &""
@export var automatic := false
@export var cooldown := 5.0
@export var effects: Array[AbilityEffect]

#region Use
# Usable when at least one effect has something to do.
func can_use(context: AbilityComponent) -> bool:
	return effects.any(func(effect: AbilityEffect) -> bool: return effect.can_apply(context))

# Applies every effect in order.
func execute(context: AbilityComponent) -> void:
	for effect in effects:
		effect.apply(context)
#endregion
