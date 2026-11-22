class_name ShopOffer
extends Node

@export var interactable: Interactable
@export var stock: Array[ItemData]
@export var panel_group := &"shop_panel"

#region Lifecycle
# Opens the shop whenever the stall is used.
func _ready() -> void:
	interactable.interacted.connect(open_shop)

# Finds the shop panel through its group and hands it this stall's stock.
func open_shop(user: Node3D) -> void:
	var panel: ShopPanel = get_tree().get_first_node_in_group(panel_group)
	if panel:
		panel.open_shop(stock, user)
#endregion
