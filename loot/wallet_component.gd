class_name WalletComponent
extends Node

signal gold_changed(total: int)

const META_KEY := &"wallet"

@export var body: Node
@export var starting_gold := 0

var gold := 0

#region Lifecycle
# Lets pickups and shops find this wallet through the body.
func _ready() -> void:
	body.set_meta(META_KEY, self)
	gold = starting_gold
	gold_changed.emit(gold)
#endregion

#region Gold
# Adds gold and announces the new total.
func add(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

# Takes gold only when there is enough; true if it was paid.
func spend(amount: int) -> bool:
	if gold < amount:
		return false
	add(-amount)
	return true
#endregion
