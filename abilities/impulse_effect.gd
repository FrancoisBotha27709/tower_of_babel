class_name ImpulseEffect
extends AbilityEffect

@export var local_impulse := Vector3(0.0, 8.0, -20.0)

#region Effect
# Needs a character body to push.
func can_apply(context: AbilityComponent) -> bool:
	return context.body is CharacterBody3D

# Launches the body along its own facing.
func apply(context: AbilityComponent) -> void:
	var character := context.body as CharacterBody3D
	character.velocity += character.global_basis * local_impulse
#endregion
