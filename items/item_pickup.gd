class_name ItemPickup
extends Area3D

signal collected(inventory: InventoryComponent)

@export var item: ItemData
@export var consume_on_collect := true

#region Lifecycle
# Waits for bodies to touch the pickup.
func _ready() -> void:
	body_entered.connect(on_body_entered)

# Hands the item to any body that carries an inventory, ignoring floors and walls.
func on_body_entered(collector: Node3D) -> void:
	if not collector.has_meta(InventoryComponent.META_KEY):
		return
	var inventory: InventoryComponent = collector.get_meta(InventoryComponent.META_KEY)
	if not inventory.add_item(item):
		return
	collected.emit(inventory)
	if consume_on_collect:
		queue_free()
#endregion
