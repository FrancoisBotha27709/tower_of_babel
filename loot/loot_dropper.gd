class_name LootDropper
extends Node

@export var death: DeathComponent
@export var body: Node3D
@export var container: Node
@export var table: LootTable
@export_range(0.0, 1.0) var drop_chance := 0.5
@export var scatter_radius := 1.5
@export var drop_height := 0.8

#region Lifecycle
# Drops loot the moment the owner starts dying.
func _ready() -> void:
	death.dying.connect(drop_loot)
#endregion

#region Dropping
# Rolls the chance, then spawns a pickup for every drop in the table roll.
func drop_loot() -> void:
	if randf() > drop_chance:
		return
	for drop in table.roll():
		spawn_pickup(drop)

# Instances the entry's pickup scene around the owner and hands it the drop.
func spawn_pickup(drop: LootDrop) -> void:
	var pickup: LootPickup = drop.entry.pickup_scene.instantiate()
	(container if container else body.get_parent()).add_child(pickup)
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, scatter_radius)
	pickup.global_position = body.global_position + Vector3(offset.x, drop_height, offset.y)
	pickup.configure(drop)
#endregion
