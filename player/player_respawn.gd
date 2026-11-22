class_name PlayerRespawn
extends Node

signal respawned

@export var body: PlayerBody
@export var machine: StateMachine
@export var health: HealthComponent
@export var death: DeathComponent
@export var rig: Node3D
@export var spawn_group := &"player_spawn"
@export var place_at_start := true
@export var protection_time := 1.5

var start_transform := Transform3D.IDENTITY

#region Lifecycle
# Remembers where the body began, listens for death and optionally starts at the spawn.
func _ready() -> void:
	start_transform = body.global_transform
	death.death_finished.connect(respawn)
	if place_at_start:
		place_body.call_deferred()
#endregion

#region Respawn
# Moves the player to the spawn, revives it, resets the state machine and grants brief protection.
func respawn() -> void:
	place_body()
	health.revive()
	body.ceiling_check.force_raycast_update()
	machine.transition(machine.initial_state.name)
	health.set_immune(true)
	get_tree().create_timer(protection_time).timeout.connect(end_protection)
	respawned.emit()

# Puts the body on the spawn facing its direction with no leftover motion or camera tilt.
func place_body() -> void:
	var target := find_spawn_transform()
	body.global_position = target.origin
	body.global_rotation = Vector3(0.0, target.basis.get_euler().y, 0.0)
	body.velocity = Vector3.ZERO
	rig.rotation = Vector3.ZERO

# The active spawn's transform, or where the player began when no spawn exists.
func find_spawn_transform() -> Transform3D:
	for spawn: PlayerSpawn in get_tree().get_nodes_in_group(spawn_group):
		if spawn.active:
			return spawn.global_transform
	return start_transform

# Ends the post-respawn protection.
func end_protection() -> void:
	health.set_immune(false)
#endregion
