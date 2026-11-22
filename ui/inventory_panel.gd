class_name InventoryPanel
extends UIPanel

@export var entry_list: EntryList
@export var gold_label: Label
@export var description_label: Label

#region Lifecycle
# Describes whichever item is clicked.
func _ready() -> void:
	super()
	entry_list.entry_chosen.connect(describe)
#endregion

#region Display
# Lists every carried item with its stack count and shows the gold.
func refresh() -> void:
	var inventory: InventoryComponent = user.get_meta(InventoryComponent.META_KEY)
	var labels: PackedStringArray = []
	for item in inventory.stacks:
		labels.append(item.get_listing(inventory.stacks[item]))
	entry_list.show_entries(inventory.stacks.keys(), labels)
	gold_label.text = "Gold: %d" % user.get_meta(WalletComponent.META_KEY).gold
	description_label.text = ""

# Shows the description and value of one item.
func describe(item: ItemData) -> void:
	description_label.text = "%s\nValue: %d gold" % [item.description, item.value]
#endregion
