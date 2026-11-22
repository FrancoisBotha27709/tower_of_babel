class_name HitFlash
extends Node

@export var health: HealthComponent
@export var mesh: GeometryInstance3D
@export var flash_transparency := 0.7
@export var flash_duration := 0.12

var flash_tween: Tween

#region Lifecycle
# Listens for damage on the shared health.
func _ready() -> void:
	health.damaged.connect(flash)

# Dims the mesh briefly then fades it back.
func flash(_hit: HitData) -> void:
	if flash_tween:
		flash_tween.kill()
	mesh.transparency = flash_transparency
	flash_tween = create_tween()
	flash_tween.tween_property(mesh, "transparency", 0.0, flash_duration)
#endregion
