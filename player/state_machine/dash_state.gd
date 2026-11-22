class_name DashState
extends PlayerState

signal charges_changed(charges: float)
signal dash_started
signal dash_ended

@export var dash_speed := 40.0
@export var duration := 0.18
@export var exit_speed := 18.0
@export_range(0.0, 1.0) var momentum_keep := 0.9
@export var maximum_charges := 3
@export var recharge_time := 1.5
@export var ground_exit_state := &"Run"

var charges := 0.0
var elapsed := 0.0
var entry_speed := 0.0
var dash_direction := Vector3.ZERO

#region Charges
# Starts with full charges and announces them.
func _ready() -> void:
	charges = maximum_charges
	charges_changed.emit(charges)

# Regenerates charges over time and announces each change.
func _physics_process(delta: float) -> void:
	if charges < maximum_charges:
		charges = minf(charges + delta / recharge_time, maximum_charges)
		charges_changed.emit(charges)

# Requires at least one full charge.
func can_enter() -> bool:
	return charges >= 1.0
#endregion

#region Lifecycle
# Spends a charge, remembers the incoming speed and dashes toward input, or forward when idle.
func enter() -> void:
	charges -= 1.0
	charges_changed.emit(charges)
	elapsed = 0.0
	entry_speed = body.get_horizontal_velocity().length()
	dash_direction = body.get_move_direction()
	if dash_direction.is_zero_approx():
		dash_direction = -body.global_basis.z
	dash_started.emit()

# Announces the end of the dash however it ended, so effects like immunity always stop.
func exit() -> void:
	dash_ended.emit()

# Holds a flat constant-speed dash, then exits keeping most of the speed the player came in with.
func physics_update(delta: float) -> void:
	elapsed += delta
	body.velocity = dash_direction * dash_speed
	if elapsed >= duration:
		body.set_horizontal_velocity(dash_direction * maxf(exit_speed, entry_speed * momentum_keep))
		request(ground_exit_state if body.is_on_floor() else exit_state)
#endregion
