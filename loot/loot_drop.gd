class_name LootDrop
extends RefCounted

var entry: LootEntry
var gold := 0
var heal := 0.0

#region Factory
# Builds one rolled drop from an entry and its rolled amounts.
static func create(source_entry: LootEntry, rolled_gold: int, rolled_heal: float) -> LootDrop:
	var drop := LootDrop.new()
	drop.entry = source_entry
	drop.gold = rolled_gold
	drop.heal = rolled_heal
	return drop
#endregion

#region Description
# Text shown in lists: the item name, or the gold and health amounts.
func get_label() -> String:
	if entry.item:
		return entry.item.display_name
	var parts: PackedStringArray = []
	if gold > 0:
		parts.append("%d gold" % gold)
	if heal > 0.0:
		parts.append("+%d health" % roundi(heal))
	return entry.label if parts.is_empty() else ", ".join(parts)
#endregion

#region Granting
# Gives everything this drop holds to whoever carries the matching components; true if anything was taken.
func grant(collector: Node3D) -> bool:
	var granted := false
	if gold > 0 and collector.has_meta(WalletComponent.META_KEY):
		collector.get_meta(WalletComponent.META_KEY).add(gold)
		granted = true
	if heal > 0.0 and collector.has_meta(HealthComponent.META_KEY):
		var health: HealthComponent = collector.get_meta(HealthComponent.META_KEY)
		granted = granted or health.current_health < health.maximum_health
		health.heal(heal)
	if entry.item and collector.has_meta(InventoryComponent.META_KEY):
		granted = collector.get_meta(InventoryComponent.META_KEY).add_item(entry.item) or granted
	return granted
#endregion
