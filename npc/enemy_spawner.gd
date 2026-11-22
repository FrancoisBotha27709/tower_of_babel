class_name EnemySpawner
extends Marker3D

signal spawned(enemy: Node3D)

@export var enemy_scene: PackedScene
@export var container: Node
@export var bonus_items: Array[ItemData]
@export var auto_spawn := true
@export var initial_count := 1
@export var maximum_alive := 3
@export var spawn_interval := 8.0
@export var total_limit := 0
@export var spawn_radius := 2.0

var alive := 0
var spawned_total := 0
var interval_remaining := 0.0

#region Lifecycle
# Spawns the opening group once the scene has finished loading.
func _ready() -> void:
	interval_remaining = spawn_interval
	for spawn_index in initial_count:
		spawn.call_deferred()

# Spawns on a timer while enabled.
func _process(delta: float) -> void:
	if not auto_spawn:
		return
	interval_remaining -= delta
	if interval_remaining <= 0.0:
		interval_remaining = spawn_interval
		spawn()
#endregion

#region Spawning
# Creates one enemy near the marker when the limits allow, gives it the bonus items and returns it.
func spawn() -> Node3D:
	var limit_reached := total_limit > 0 and spawned_total >= total_limit
	if alive >= maximum_alive or limit_reached:
		return null
	var enemy: Node3D = enemy_scene.instantiate()
	(container if container else get_parent()).add_child(enemy)
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(0.0, spawn_radius)
	enemy.global_position = global_position + Vector3(offset.x, 0.0, offset.y)
	enemy.global_rotation.y = global_rotation.y
	enemy.tree_exiting.connect(on_enemy_removed)
	alive += 1
	spawned_total += 1
	give_bonus_items(enemy)
	spawned.emit(enemy)
	return enemy

# Equips the bonus items on the new enemy's inventory.
func give_bonus_items(enemy: Node) -> void:
	if not enemy.has_meta(InventoryComponent.META_KEY):
		return
	var inventory: InventoryComponent = enemy.get_meta(InventoryComponent.META_KEY)
	for item in bonus_items:
		inventory.add_item(item)

# Frees a slot when an enemy leaves the tree.
func on_enemy_removed() -> void:
	alive -= 1
#endregion
