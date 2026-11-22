class_name HealthComponent
extends Node

signal damaged(hit: HitData)
signal healed(amount: float)
signal revived
signal health_changed(current: float, maximum: float)
signal died

const META_KEY := &"health"

@export var body: Node
@export var maximum_health := 100.0: set = set_maximum_health
@export var invulnerable := false

var current_health := 0.0
var immune := false

#region Lifecycle
# Lets pickups find this health through the body, starts at full health and announces it.
func _ready() -> void:
	if body:
		body.set_meta(META_KEY, self)
	current_health = maximum_health
	health_changed.emit(current_health, maximum_health)
#endregion

#region Damage
# Dead or immune things ignore hits completely; otherwise always announces the hit and only reduces health when not invulnerable.
func apply_hit(hit: HitData) -> void:
	if is_dead() or immune:
		return
	damaged.emit(hit)
	if invulnerable:
		return
	current_health = maxf(current_health - hit.damage, 0.0)
	health_changed.emit(current_health, maximum_health)
	if current_health <= 0.0:
		died.emit()

# Temporarily ignores every hit, with no reaction at all; used for dash frames and spawn protection.
func set_immune(value: bool) -> void:
	immune = value

# True once health has run out.
func is_dead() -> bool:
	return current_health <= 0.0
#endregion

#region Recovery
# Restores health up to the maximum; the dead stay dead.
func heal(amount: float) -> void:
	if is_dead():
		return
	current_health = minf(current_health + amount, maximum_health)
	healed.emit(amount)
	health_changed.emit(current_health, maximum_health)

# Brings the dead back at full health.
func revive() -> void:
	current_health = maximum_health
	revived.emit()
	health_changed.emit(current_health, maximum_health)

# Changes the cap; raising it also grants the difference as current health.
func set_maximum_health(value: float) -> void:
	var difference := value - maximum_health
	maximum_health = value
	if not is_node_ready() or is_dead():
		return
	current_health = clampf(current_health + maxf(difference, 0.0), 0.0, maximum_health)
	health_changed.emit(current_health, maximum_health)
#endregion
