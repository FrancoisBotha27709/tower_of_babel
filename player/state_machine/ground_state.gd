class_name GroundState
extends PlayerState

@export var speed := 14.0
@export var acceleration := 100.0
@export var deceleration := 70.0
@export var overspeed_friction := 6.0

#region Update
# Accelerates toward input; speed above the cap is carried and bled off slowly while still steerable.
func physics_update(delta: float) -> void:
	var direction := body.get_move_direction()
	var current_speed := body.get_horizontal_velocity().length()
	if current_speed > speed and not direction.is_zero_approx():
		carry_momentum(direction, current_speed, delta)
	else:
		var rate := deceleration if direction.is_zero_approx() else acceleration
		body.accelerate_horizontal(direction * speed, rate, delta)
	body.apply_gravity(delta)

# Keeps most of the incoming speed, turning it toward input and losing only a little to friction.
func carry_momentum(direction: Vector3, current_speed: float, delta: float) -> void:
	var carried_speed := maxf(current_speed - overspeed_friction * delta, speed)
	body.set_horizontal_velocity(body.get_horizontal_velocity().normalized() * carried_speed)
	body.accelerate_horizontal(direction * carried_speed, acceleration, delta)
#endregion
