class_name LootEntry
extends Resource

@export var label := ""
@export var pickup_scene: PackedScene
@export var item: ItemData
@export var weight := 1.0
@export_group("Gold")
@export var gold_minimum := 0
@export var gold_maximum := 0
@export_group("Health")
@export var heal_minimum := 0.0
@export var heal_maximum := 0.0

#region Rolling
# Rolls the concrete amounts for one drop of this entry.
func roll() -> LootDrop:
	return LootDrop.create(self, randi_range(gold_minimum, gold_maximum), randf_range(heal_minimum, heal_maximum))
#endregion
