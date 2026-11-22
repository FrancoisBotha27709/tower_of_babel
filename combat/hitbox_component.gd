class_name HitboxComponent
extends Area3D

signal hit_landed(hurtbox: HurtboxComponent)

@export var damage := 10.0
@export var knockback_force := 0.0
@export var pulse_duration := 0.15
@export var always_active := false
@export var source: Node3D

#region Lifecycle
# Starts disabled unless always active, and listens for hurtboxes.
func _ready() -> void:
	monitorable = false
	monitoring = always_active
	area_entered.connect(on_area_entered)

# Enables the hitbox for a short window.
func pulse() -> void:
	set_deferred("monitoring", true)
	get_tree().create_timer(pulse_duration).timeout.connect(set_deferred.bind("monitoring", false))
#endregion

#region Hits
# Delivers a hit to any hurtbox that enters, pushing it away from the source.
func on_area_entered(area: Area3D) -> void:
	var hurtbox := area as HurtboxComponent
	if not hurtbox:
		return
	var origin: Node3D = source if source else self
	var direction := (hurtbox.global_position - origin.global_position).normalized()
	hurtbox.receive_hit(HitData.create(damage, direction * knockback_force, source))
	hit_landed.emit(hurtbox)
#endregion
