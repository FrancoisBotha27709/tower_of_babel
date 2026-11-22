class_name EnemySteering
extends Node

signal jump_requested(height: float)
signal stuck_detected

const MINIMUM_PATH_POINTS := 2
const ESCAPE_TIE_SIDE := 1.0

@export_group("Nodes")
@export var body: CharacterBody3D
@export var navigation_agent: NavigationAgent3D
@export_group("Probing")
@export_range(2, 32) var probe_count := 9
@export_range(0.0, 3.14, 0.01, "radians_as_degrees") var fan_half_spread := 1.75
@export var probe_distance := 3.0
@export var probe_lift_height := 0.15
@export var jump_trigger_distance := 1.2
@export var reevaluate_interval := 0.1
@export_group("Parkour")
@export var maximum_climb_height := 3.0
@export var climb_probe_step := 0.8
@export_range(0.0, 1.0) var climb_cost := 0.3
@export var ledge_probe_distance := 1.0
@export var gap_jump_distance := 3.5
@export var ledge_drop_depth := 2.5
@export var pit_penalty := 6.0
@export var gap_jump_height := 0.6
@export var escape_jump_height := 1.0
@export var drop_height_threshold := 1.5
@export_group("Pursuit")
@export var lead_time := 0.4
@export var lead_minimum_distance := 4.0
@export_group("Weights")
@export var alignment_weight := 1.0
@export var clearance_weight := 3.0
@export var commitment_weight := 0.4
@export var separation_weight := 1.0
@export_group("Separation")
@export var neighbor_group := &"enemies"
@export var separation_radius := 2.5
@export_group("Unstick")
@export var stuck_check_interval := 0.5
@export var stuck_distance := 0.5
@export_range(0.0, 3.14, 0.01, "radians_as_degrees") var escape_turn := 1.57
@export var escape_duration := 0.8

var heading := Vector3.ZERO
var escape_direction := Vector3.ZERO
var drops_allowed := false
var reevaluate_remaining := 0.0
var stuck_check_remaining := 0.0
var escape_remaining := 0.0
var last_check_position := Vector3.ZERO
var ignored_collider: Node
var probe_collision := KinematicCollision3D.new()

#region Lifecycle
# Joins the neighbor group so other enemies can keep their distance.
func _ready() -> void:
	body.add_to_group(neighbor_group)
	last_check_position = body.global_position
#endregion

#region Steering
# Returns the flat direction to move toward the target, re-planned a few times per second.
func steer(target: Node3D, delta: float) -> Vector3:
	ignored_collider = target
	update_stuck(delta)
	reevaluate_remaining -= delta
	if reevaluate_remaining > 0.0:
		return heading
	reevaluate_remaining = reevaluate_interval
	drops_allowed = target.global_position.y < body.global_position.y - drop_height_threshold
	var goal_direction := flat(waypoint_toward(predict_position(target)) - body.global_position).normalized()
	heading = choose_heading(escape_direction if escape_remaining > 0.0 else goal_direction)
	request_jump_if_needed()
	return heading

# Aims where a fast-moving target is going rather than where it is, unless it is already close.
func predict_position(target: Node3D) -> Vector3:
	var distance := flat(target.global_position - body.global_position).length()
	if distance < lead_minimum_distance or not (target is CharacterBody3D):
		return target.global_position
	return target.global_position + flat((target as CharacterBody3D).velocity) * lead_time

# Follows the navigation path when a baked one exists, otherwise heads straight for the goal.
func waypoint_toward(goal: Vector3) -> Vector3:
	if not navigation_agent:
		return goal
	navigation_agent.target_position = goal
	var next_position := navigation_agent.get_next_path_position()
	var has_path := navigation_agent.get_current_navigation_path().size() >= MINIMUM_PATH_POINTS
	return next_position if has_path and not navigation_agent.is_navigation_finished() else goal

# Scores a fan of directions by alignment, clearance, commitment, spacing and pits, then picks the best.
func choose_heading(desired: Vector3) -> Vector3:
	if desired.is_zero_approx():
		return Vector3.ZERO
	var push := separation_push()
	var best_direction := desired
	var best_score := -INF
	for probe_index in probe_count:
		var angle := remap(float(probe_index), 0.0, probe_count - 1.0, -fan_half_spread, fan_half_spread)
		var direction := desired.rotated(Vector3.UP, angle)
		var score := cos(angle) * alignment_weight + measure_clearance(direction) * clearance_weight
		score += direction.dot(heading) * commitment_weight + direction.dot(push) * separation_weight
		if not drops_allowed and is_pit_ahead(direction):
			score -= pit_penalty
		if score > best_score:
			best_score = score
			best_direction = direction
	return best_direction

# Pushes away from nearby neighbors, stronger the closer they are.
func separation_push() -> Vector3:
	var push := Vector3.ZERO
	for neighbor: Node3D in get_tree().get_nodes_in_group(neighbor_group):
		var offset := flat(body.global_position - neighbor.global_position)
		if neighbor == body or offset.length() >= separation_radius or offset.is_zero_approx():
			continue
		push += offset.normalized() * (1.0 - offset.length() / separation_radius)
	return push
#endregion

#region Probing
# Free space ahead as a 0 to 1 ratio; climbable obstacles count as nearly free, taller ones cost more.
func measure_clearance(direction: Vector3) -> float:
	var low_ratio := probe_ratio(direction, probe_lift_height)
	if low_ratio >= 1.0:
		return 1.0
	var lift := find_clear_lift(direction)
	return low_ratio if is_inf(lift) else 1.0 - climb_cost * lift / maximum_climb_height

# Lowest lifted height at which the way ahead is free, or infinity when nothing within climbing reach is.
func find_clear_lift(direction: Vector3) -> float:
	var lift := probe_lift_height + climb_probe_step
	while lift <= maximum_climb_height:
		if probe_ratio(direction, lift) >= 1.0:
			return lift
		lift += climb_probe_step
	return INF

# Sweeps the body shape along a direction at a lifted height, ignoring floors and the target.
func probe_ratio(direction: Vector3, lift_height: float) -> float:
	var origin := body.global_transform.translated(Vector3.UP * lift_height)
	if not body.test_move(origin, direction * probe_distance, probe_collision):
		return 1.0
	var is_floor := probe_collision.get_normal().y >= cos(body.floor_max_angle)
	if is_floor or probe_collision.get_collider() == ignored_collider:
		return 1.0
	return probe_collision.get_travel().length() / probe_distance

# True when there is ground a short way ahead or somewhere a jump could land.
func has_floor_at(direction: Vector3, distance: float) -> bool:
	return body.test_move(body.global_transform.translated(direction * distance), Vector3.DOWN * ledge_drop_depth)

# True when walking that way would drop into a pit that cannot be jumped.
func is_pit_ahead(direction: Vector3) -> bool:
	return not (has_floor_at(direction, ledge_probe_distance) or has_floor_at(direction, gap_jump_distance))

# Asks for a jump over a close obstacle or across a gap, sized to the height needed.
func request_jump_if_needed() -> void:
	if heading.is_zero_approx() or not body.is_on_floor():
		return
	var blocked_distance := probe_ratio(heading, probe_lift_height) * probe_distance
	if blocked_distance <= jump_trigger_distance:
		var lift := find_clear_lift(heading)
		if not is_inf(lift):
			jump_requested.emit(lift)
	elif not has_floor_at(heading, ledge_probe_distance) and has_floor_at(heading, gap_jump_distance):
		jump_requested.emit(gap_jump_height)
#endregion

#region Unstick
# Measures progress on an interval and starts an escape when the body barely moved.
func update_stuck(delta: float) -> void:
	escape_remaining = maxf(escape_remaining - delta, 0.0)
	stuck_check_remaining -= delta
	if stuck_check_remaining > 0.0:
		return
	stuck_check_remaining = stuck_check_interval
	var moved := flat(body.global_position - last_check_position).length()
	last_check_position = body.global_position
	if moved < stuck_distance and escape_remaining <= 0.0 and not heading.is_zero_approx():
		begin_escape()

# Sidesteps toward whichever side is more open and hops in case a ledge is the problem.
func begin_escape() -> void:
	var open_left := measure_clearance(heading.rotated(Vector3.UP, escape_turn))
	var open_right := measure_clearance(heading.rotated(Vector3.UP, -escape_turn))
	var side := signf(open_left - open_right)
	if is_zero_approx(side):
		side = ESCAPE_TIE_SIDE
	escape_direction = heading.rotated(Vector3.UP, side * escape_turn)
	escape_remaining = escape_duration
	reevaluate_remaining = 0.0
	stuck_detected.emit()
	jump_requested.emit(escape_jump_height)
#endregion

#region Helpers
# Drops the vertical part of a vector.
func flat(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
#endregion
