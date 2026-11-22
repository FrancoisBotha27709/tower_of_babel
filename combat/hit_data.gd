class_name HitData
extends RefCounted

var damage := 0.0
var knockback := Vector3.ZERO
var source: Node

#region Factory
# Builds a hit; add new fields here to extend what a hit carries.
static func create(hit_damage: float, hit_knockback: Vector3, hit_source: Node) -> HitData:
	var hit := HitData.new()
	hit.damage = hit_damage
	hit.knockback = hit_knockback
	hit.source = hit_source
	return hit
#endregion
