class_name HitboxTrigger
extends Node

@export var hitbox: HitboxComponent
@export var action := &"attack"

#region Input
# Pulses the hitbox when the action is pressed.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(action):
		hitbox.pulse()
#endregion
