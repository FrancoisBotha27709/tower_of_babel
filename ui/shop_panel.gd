class_name ShopPanel
extends UIPanel

const PRICE_FORMAT := "%s - %d gold"

@export var buy_list: EntryList
@export var sell_list: EntryList
@export var buy_button: Button
@export var sell_button: Button
@export var gold_label: Label
@export var message_label: Label
@export_range(0.0, 1.0) var sell_ratio := 0.5
@export var group_name := &"shop_panel"

var stock: Array[ItemData] = []

#region Lifecycle
# Registers by group so stalls can find the panel, and wires the buttons.
func _ready() -> void:
	super()
	add_to_group(group_name)
	buy_button.pressed.connect(buy_selected)
	sell_button.pressed.connect(sell_selected)
#endregion

#region Display
# Opens the shop with a stall's stock.
func open_shop(new_stock: Array[ItemData], opening_user: Node3D) -> void:
	stock = new_stock
	message_label.text = ""
	open(opening_user)

# Lists the stock at full price and the carried items at their sell price.
func refresh() -> void:
	var inventory: InventoryComponent = user.get_meta(InventoryComponent.META_KEY)
	var buy_labels: PackedStringArray = []
	for item in stock:
		buy_labels.append(PRICE_FORMAT % [item.get_listing(), item.value])
	var sell_labels: PackedStringArray = []
	for item in inventory.stacks:
		sell_labels.append(PRICE_FORMAT % [item.get_listing(inventory.stacks[item]), get_sell_price(item)])
	buy_list.show_entries(stock, buy_labels)
	sell_list.show_entries(inventory.stacks.keys(), sell_labels)
	gold_label.text = "Gold: %d" % user.get_meta(WalletComponent.META_KEY).gold
#endregion

#region Trading
# Buys the selected stock item when it fits in the inventory and the gold is there.
func buy_selected() -> void:
	var item: ItemData = buy_list.get_selected_entry()
	var inventory: InventoryComponent = user.get_meta(InventoryComponent.META_KEY)
	if not item:
		return
	if not inventory.can_accept(item):
		return say("You cannot carry that.")
	if not user.get_meta(WalletComponent.META_KEY).spend(item.value):
		return say("Not enough gold.")
	inventory.add_item(item)
	say("Bought %s." % item.display_name)
	refresh()

# Sells one copy of the selected carried item.
func sell_selected() -> void:
	var item: ItemData = sell_list.get_selected_entry()
	if not item:
		return
	var inventory: InventoryComponent = user.get_meta(InventoryComponent.META_KEY)
	user.get_meta(WalletComponent.META_KEY).add(get_sell_price(item))
	inventory.remove_item(item)
	say("Sold %s." % item.display_name)
	refresh()

# What the shop pays for an item.
func get_sell_price(item: ItemData) -> int:
	return floori(item.value * sell_ratio)

# Shows a short result message.
func say(message: String) -> void:
	message_label.text = message
#endregion
