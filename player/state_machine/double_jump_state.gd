class_name DoubleJumpState
extends JumpState

@export var machine: StateMachine
@export var reset_states: Array[StringName] = [&"Run", &"Walk", &"Crouch", &"Slide", &"WallRun"]
@export var ground_clearance := 1.0

var used := false

#region Lifecycle
# Recharges the extra jump whenever the player touches the ground or a wall.
func _ready() -> void:
	machine.state_changed.connect(on_state_changed)

# Allowed while ground jump time remains, or once per airtime when not about to land.
func can_enter() -> bool:
	return body.coyote_remaining > 0.0 or (not used and not is_ground_close())

# A coyote jump is a normal jump; only a true mid-air jump spends the extra one.
func enter() -> void:
	used = used or body.coyote_remaining <= 0.0
	super()
#endregion

#region Charge
# Recharges when the machine enters a ground or wall state.
func on_state_changed(_previous: StringName, current: StringName) -> void:
	if reset_states.has(current):
		used = false

# True when ground is within reach below, so an early press stays a buffered ground jump.
func is_ground_close() -> bool:
	return body.test_move(body.global_transform, Vector3.DOWN * ground_clearance)
#endregion
