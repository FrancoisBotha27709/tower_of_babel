extends Node
class_name StateMachine

signal state_changed(previous_name: StringName, current_name: StringName)

@export var body: PlayerBody
@export var initial_state: PlayerState

var states: Dictionary[StringName, PlayerState]
var current_state: PlayerState

#region Setup
# Registers child states, wires body signals and enters the initial state.
func _ready() -> void:
	await body.ready
	for state: PlayerState in get_children():
		state.body = body
		state.transition_requested.connect(transition)
		states[state.name] = state
	body.left_floor.connect(func() -> void: current_state.request(current_state.floor_lost_state))
	body.landed.connect(func(_impact_speed: float) -> void: current_state.handle_landing())
	current_state = initial_state
	body.set_stance(current_state.stance_scale)
	current_state.enter()
#endregion

#region Update
# Runs the active state, applies hold-release exits, then moves the body.
func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)
	if current_state.hold_action and not Input.is_action_pressed(current_state.hold_action):
		transition(current_state.exit_state)
	body.move(delta)

# Forwards input to the active state.
func _unhandled_input(event: InputEvent) -> void:
	current_state.handle_input(event)
#endregion

#region Transitions
# Switches state if it exists, allows entry and there is headroom to grow.
func transition(state_name: StringName) -> void:
	var next: PlayerState = states.get(state_name)
	if not next or next == current_state or not next.can_enter():
		return
	if next.stance_scale > current_state.stance_scale and not body.can_stand():
		return
	var previous := current_state
	previous.exit()
	current_state = next
	body.set_stance(next.stance_scale)
	state_changed.emit(previous.name, next.name)
	next.enter()
#endregion