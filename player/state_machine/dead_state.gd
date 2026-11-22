class_name DeadState
extends PlayerState

@export var friction := 30.0

#region Update
# Coasts to a stop and falls; takes no input.
func physics_update(delta: float) -> void:
	body.accelerate_horizontal(Vector3.ZERO, friction, delta)
	body.apply_gravity(delta)
#endregion
