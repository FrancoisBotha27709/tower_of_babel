extends Node
class_name PlayerState

signal transition_requested(state_name: StringName)

@export var pressed_transitions: Dictionary[StringName, StringName]
@export var hold_action: StringName
@export var exit_state: StringName
@export var floor_lost_state: StringName
@export var landing_state: StringName
@export var landing_held_transitions: Dictionary[StringName, StringName]
@export var jump_state := &"Jump"
@export_range(0.1, 1.0) var stance_scale := 1.0

var body: PlayerBody

#region Overridable
# Whether the machine may enter this state right now.
func can_enter() -> bool:
	return true

# Runs once when the state becomes active.
func enter() -> void:
	pass

# Runs once when the state stops being active.
func exit() -> void:
	pass

# Runs every physics frame while active, before the body moves.
func physics_update(_delta: float) -> void:
	pass
#endregion

#region Shared
# Asks the machine to switch states, ignoring empty names.
func request(state_name: StringName) -> void:
	if state_name:
		transition_requested.emit(state_name)

# Fires the first configured transition whose action was just pressed.
func handle_input(event: InputEvent) -> void:
	for action in pressed_transitions:
		if event.is_action_pressed(action):
			request(pressed_transitions[action])
			return

# On touchdown picks a buffered jump, a held-action state, or the landing state.
func handle_landing() -> void:
	if not landing_state:
		return
	if body.jump_buffer_remaining > 0.0:
		request(jump_state)
		return
	for action in landing_held_transitions:
		if Input.is_action_pressed(action):
			request(landing_held_transitions[action])
			return
	request(landing_state)
#endregion