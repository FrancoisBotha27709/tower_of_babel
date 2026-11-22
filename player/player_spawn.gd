class_name PlayerSpawn
extends Marker3D

@export var group_name := &"player_spawn"
@export var active := true

#region Lifecycle
# Registers so the respawn component can find it without node paths.
func _ready() -> void:
	add_to_group(group_name)
#endregion

#region Activation
# Makes this the only active spawn; connect a checkpoint trigger to this.
func activate() -> void:
	for spawn: PlayerSpawn in get_tree().get_nodes_in_group(group_name):
		spawn.active = spawn == self
#endregion
