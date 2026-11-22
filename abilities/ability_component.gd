class_name AbilityComponent
extends Node

signal ability_granted(ability: AbilityData)
signal ability_revoked(ability: AbilityData)
signal ability_used(ability: AbilityData)
signal ability_ready(ability: AbilityData)

@export var body: Node3D
@export var stats: StatsComponent
@export var health: HealthComponent
@export var accepts_input := false
@export var cooldown_rate_stat: StatDefinition

var granted: Dictionary[AbilityData, int]
var cooldowns: Dictionary[AbilityData, float]

#region Lifecycle
# Only listens for input when this owner is player controlled.
func _ready() -> void:
	set_process_unhandled_input(accepts_input)

# Counts cooldowns down and fires automatic abilities that are ready.
func _process(delta: float) -> void:
	tick_cooldowns(delta)
	for ability: AbilityData in granted.keys():
		if ability.automatic:
			use(ability)

# Fires any granted ability whose input action was just pressed.
func _unhandled_input(event: InputEvent) -> void:
	for ability: AbilityData in granted.keys():
		if InputMap.has_action(ability.input_action) and event.is_action_pressed(ability.input_action):
			use(ability)
#endregion

#region Granting
# Adds one copy of an ability; stacked copies keep it alive until all are revoked.
func grant(ability: AbilityData) -> void:
	var count: int = granted.get(ability, 0)
	granted[ability] = count + 1
	if count == 0:
		ability_granted.emit(ability)

# Removes one copy of an ability and forgets it when none remain.
func revoke(ability: AbilityData) -> void:
	if not granted.has(ability):
		return
	var count: int = granted[ability] - 1
	if count > 0:
		granted[ability] = count
		return
	granted.erase(ability)
	cooldowns.erase(ability)
	ability_revoked.emit(ability)
#endregion

#region Use
# Runs the ability if it is off cooldown and allowed, then starts its cooldown.
func use(ability: AbilityData) -> bool:
	if cooldowns.has(ability) or not ability.can_use(self):
		return false
	if ability.cooldown > 0.0:
		cooldowns[ability] = ability.cooldown
	ability.execute(self)
	ability_used.emit(ability)
	return true

# Remaining cooldown from 1 (just used) to 0 (ready), for diegetic displays.
func cooldown_ratio(ability: AbilityData) -> float:
	return cooldowns.get(ability, 0.0) / maxf(ability.cooldown, 0.001)

# Advances cooldowns, faster when a cooldown rate stat is set.
func tick_cooldowns(delta: float) -> void:
	var rate := stats.get_value(cooldown_rate_stat, 1.0) if stats and cooldown_rate_stat else 1.0
	for ability: AbilityData in cooldowns.keys():
		cooldowns[ability] -= delta * rate
		if cooldowns[ability] <= 0.0:
			cooldowns.erase(ability)
			ability_ready.emit(ability)
#endregion
