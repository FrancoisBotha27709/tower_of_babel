class_name AirState
extends PlayerState

@export var max_air_speed := 14.0
@export var air_acceleration := 60.0
@export var gravity_scale := 1.0
@export var fall_gravity_scale := 1.35
@export var soft_speed_cap := 28.0
@export var soft_cap_drag := 10.0
@export var wall_run_state := &"WallRun"
@export var mantle: MantleState

#region Update
# Quake-style air control that keeps momentum, falls faster than it rises and bleeds extreme speed.
func physics_update(delta: float) -> void:
	var direction := body.get_move_direction()
	var gained := clampf(max_air_speed - body.get_horizontal_velocity().dot(direction), 0.0, air_acceleration * delta)
	body.velocity += direction * gained
	body.apply_gravity(delta, fall_gravity_scale if body.velocity.y < 0.0 else gravity_scale)
	bleed_overspeed(delta)
	check_walls()

# Slowly reduces horizontal speed above the soft cap so chained tricks stay controllable.
func bleed_overspeed(delta: float) -> void:
	var horizontal := body.get_horizontal_velocity()
	if horizontal.length() > soft_speed_cap:
		body.set_horizontal_velocity(horizontal.move_toward(horizontal.normalized() * soft_speed_cap, soft_cap_drag * delta))

# Vaults a reachable ledge, otherwise tries to run along the wall.
func check_walls() -> void:
	if not body.is_on_wall_only():
		return
	request(mantle.name if mantle and mantle.can_enter() else wall_run_state)
#endregion
