class_name InventoryComponent
extends Node

signal item_added(item: ItemData)
signal item_removed(item: ItemData)
signal item_equipped(slot: SlotDefinition, item: ItemData)
signal item_rejected(item: ItemData)

const META_KEY := &"inventory"

@export var body: Node
@export var stats: StatsComponent
@export var abilities: AbilityComponent
@export var allowed_slots: Array[SlotDefinition]
@export var starting_items: Array[ItemData]

var equipped: Dictionary[SlotDefinition, ItemData]
var stacks: Dictionary[ItemData, int]

#region Lifecycle
# Lets pickups find this inventory through the body, then equips the starting items.
func _ready() -> void:
	body.set_meta(META_KEY, self)
	for item in starting_items:
		add_item(item)
#endregion

#region Items
# Adds an item: equipment replaces what is in its slot, upgrades stack.
func add_item(item: ItemData) -> bool:
	if not can_accept(item):
		item_rejected.emit(item)
		return false
	var slot := item.get_slot()
	if slot and equipped.has(slot):
		remove_item(equipped[slot])
	stacks[item] = stacks.get(item, 0) + 1
	stats.add_modifiers(item, item.modifiers)
	for ability in item.abilities:
		if abilities:
			abilities.grant(ability)
	if slot:
		equipped[slot] = item
		item_equipped.emit(slot, item)
	item_added.emit(item)
	return true

# Removes one copy of an item and takes back its modifiers and abilities.
func remove_item(item: ItemData) -> bool:
	if not stacks.has(item):
		return false
	stats.remove_modifiers(item, item.modifiers)
	for ability in item.abilities:
		if abilities:
			abilities.revoke(ability)
	stacks[item] -= 1
	if stacks[item] <= 0:
		stacks.erase(item)
		if item.get_slot():
			equipped.erase(item.get_slot())
	item_removed.emit(item)
	return true

# Equipment needs an allowed slot and must be new; upgrades need free stacks.
func can_accept(item: ItemData) -> bool:
	var slot := item.get_slot()
	if slot:
		return allowed_slots.has(slot) and equipped.get(slot) != item
	return stacks.get(item, 0) < item.get_stack_limit()
#endregion
