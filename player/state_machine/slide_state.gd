class_name SlideState
extends PlayerState

@export var minimum_speed := 8.0
@export var boost_speed := 20.0
@export var friction := 6.0
@export var end_speed := 4.0
@export var slope_gain := 1.2
@export var steer_rate := 2.2
@export var end_state := &"Crouch"
@export var fallback_state := &"Crouch"

#region Lifecycle
# Boosts along the current heading, or falls back to crouch when too slow.
func enter() -> void:
	var entry_velocity := body.get_horizontal_velocity()
	if entry_velocity.length() < minimum_speed:
		request(fallback_state)
		return
	body.set_horizontal_velocity(entry_velocity.normalized() * maxf(entry_velocity.length(), boost_speed))

# Slides with friction, speeds up downhill, carves toward input and ends once speed runs out.
func physics_update(delta: float) -> void:
	body.apply_gravity(delta)
	apply_slope(delta)
	steer(delta)
	body.accelerate_horizontal(Vector3.ZERO, friction, delta)
	if body.get_horizontal_velocity().length() < end_speed:
		request(end_state)
#endregion

#region Helpers
# Adds speed along the downhill direction of the floor.
func apply_slope(delta: float) -> void:
	var downhill := Vector3.DOWN.slide(body.get_floor_normal())
	body.velocity += Vector3(downhill.x, 0.0, downhill.z) * body.gravity * slope_gain * delta

# Turns the slide toward the input direction without changing speed.
func steer(delta: float) -> void:
	var direction := body.get_move_direction()
	var heading := body.get_horizontal_velocity()
	if direction.is_zero_approx() or heading.is_zero_approx():
		return
	var turn := clampf(heading.signed_angle_to(direction, Vector3.UP), -steer_rate * delta, steer_rate * delta)
	body.set_horizontal_velocity(heading.rotated(Vector3.UP, turn))
#endregion
