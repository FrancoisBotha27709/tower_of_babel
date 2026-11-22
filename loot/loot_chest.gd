class_name LootChest
extends Node

signal emptied

@export var interactable: Interactable
@export var table: LootTable
@export var panel_group := &"loot_panel"

var drops: Array[LootDrop] = []

#region Lifecycle
# Rolls the contents once and opens them whenever the chest is used.
func _ready() -> void:
	drops = table.roll()
	interactable.interacted.connect(open_chest)

# Shows what is left in the chest; the panel removes drops as they are taken.
func open_chest(user: Node3D) -> void:
	var panel: LootPanel = get_tree().get_first_node_in_group(panel_group)
	if panel:
		panel.open_loot(drops, user)
#endregion
