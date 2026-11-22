class_name MantleState
extends PlayerState

@export var reach_height := 1.8
@export var probe_distance := 0.8
@export var rise_speed := 13.0
@export var forward_speed := 9.0
@export var pop_speed := 5.0
@export var stick_speed := 3.0
@export var maximum_duration := 0.5
@export_range(0.0, 1.0) var maximum_wall_normal_y := 0.2
@export_range(0.0, 1.0) var minimum_intent := 0.3

var into_wall := Vector3.ZERO
var elapsed := 0.0

#region Lifecycle
# Needs an airborne wall contact, the player heading into it and free space on top of the ledge.
func can_enter() -> bool:
	if not body.is_on_wall_only() or absf(body.get_wall_normal().y) > maximum_wall_normal_y:
		return false
	var toward_wall := -body.get_wall_normal()
	return get_intent().dot(toward_wall) >= minimum_intent and is_ledge_within_reach(toward_wall)

# Locks onto the wall being climbed.
func enter() -> void:
	into_wall = -body.get_wall_normal()
	body.wall_normal = body.get_wall_normal()
	elapsed = 0.0

# Rises along the wall, then pops forward onto the ledge the moment the way is clear.
func physics_update(delta: float) -> void:
	elapsed += delta
	if elapsed >= maximum_duration:
		request(exit_state)
	elif not body.test_move(body.global_transform, into_wall * probe_distance):
		body.set_horizontal_velocity(into_wall * forward_speed)
		body.velocity.y = pop_speed
		request(exit_state)
	else:
		body.velocity = Vector3.UP * rise_speed + into_wall * stick_speed
#endregion

#region Helpers
# Where the player wants to go: input first, otherwise the direction they were moving.
func get_intent() -> Vector3:
	var intent := body.get_move_direction()
	if intent.is_zero_approx():
		intent = Vector3(body.previous_velocity.x, 0.0, body.previous_velocity.z).normalized()
	return intent

# True when nothing blocks rising to reach height and nothing blocks stepping forward up there.
func is_ledge_within_reach(toward_wall: Vector3) -> bool:
	var start := body.global_transform
	var raised := start.translated(Vector3.UP * reach_height)
	return not body.test_move(start, Vector3.UP * reach_height) and not body.test_move(raised, toward_wall * probe_distance)
#endregion
