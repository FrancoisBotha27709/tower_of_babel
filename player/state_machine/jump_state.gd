class_name JumpState
extends PlayerState

@export var jump_speed := 11.0
@export var requires_floor := true
@export var wall_push_speed := 0.0
@export var momentum_gain := 0.0
@export var momentum_cap := 24.0
@export var next_state := &"Air"

#region Lifecycle
# Floor jumps need ground or coyote time; wall jumps skip the check.
func can_enter() -> bool:
	return not requires_floor or body.coyote_remaining > 0.0

# Applies the jump impulse, adds a capped speed bonus, optionally pushes off the last wall, then hands off.
func enter() -> void:
	body.velocity.y = jump_speed
	body.velocity += body.wall_normal * wall_push_speed
	add_momentum()
	body.coyote_remaining = 0.0
	body.jump_buffer_remaining = 0.0
	body.jumped.emit()
	request(next_state)

# Rewards chained jumps: speeds up along the current heading without pushing past the cap.
func add_momentum() -> void:
	var horizontal := body.get_horizontal_velocity()
	if horizontal.is_zero_approx() or is_zero_approx(momentum_gain):
		return
	var boosted_speed := minf(horizontal.length() + momentum_gain, maxf(horizontal.length(), momentum_cap))
	body.set_horizontal_velocity(horizontal.normalized() * boosted_speed)
#endregion
