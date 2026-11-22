extends PlayerState
class_name WallRunState

@export var wall_run_speed := 16.0
@export var minimum_entry_speed := 8.0
@export_range(0.0, 90.0) var maximum_approach_angle := 70.0
@export_range(0.0, 1.0) var maximum_wall_normal_y := 0.2
@export var gravity_scale := 0.1
@export var stick_speed := 2.0
@export var maximum_duration := 2.0
@export var reenter_delay := 0.3

var run_speed := 0.0
var direction_sign := 1.0
var elapsed := 0.0
var last_exit_seconds := -INF

#region Helpers
# Current time in seconds.
func get_seconds() -> float:
	return Time.get_ticks_msec() / 1000.0

# Horizontal velocity from before the last collision.
func get_incoming_velocity() -> Vector3:
	return Vector3(body.previous_velocity.x, 0.0, body.previous_velocity.z)
#endregion

#region Lifecycle
# Accepts vertical walls hit fast enough at a glancing angle.
func can_enter() -> bool:
	if not body.is_on_wall() or get_seconds() - last_exit_seconds < reenter_delay:
		return false
	var normal := body.get_wall_normal()
	var incoming := get_incoming_velocity()
	if incoming.length() < minimum_entry_speed or absf(normal.y) > maximum_wall_normal_y:
		return false
	var approach_angle := rad_to_deg(asin(clampf(-incoming.normalized().dot(normal), -1.0, 1.0)))
	return approach_angle >= 0.0 and approach_angle <= maximum_approach_angle

# Locks the run direction along the wall, keeping any extra entry speed.
func enter() -> void:
	var incoming := get_incoming_velocity()
	body.wall_normal = body.get_wall_normal()
	direction_sign = signf(body.wall_normal.cross(Vector3.UP).dot(incoming))
	run_speed = maxf(incoming.length(), wall_run_speed)
	body.velocity.y = maxf(body.velocity.y, 0.0)
	elapsed = 0.0

# Starts the re-entry cooldown.
func exit() -> void:
	last_exit_seconds = get_seconds()

# Runs along the wall with light gravity and a push into the wall to keep contact.
func physics_update(delta: float) -> void:
	elapsed += delta
	if not body.is_on_wall() or elapsed >= maximum_duration:
		request(exit_state)
		return
	body.wall_normal = body.get_wall_normal()
	var run_direction := body.wall_normal.cross(Vector3.UP).normalized() * direction_sign
	body.apply_gravity(delta, gravity_scale)
	body.set_horizontal_velocity(run_direction * run_speed - body.wall_normal * stick_speed)
#endregion