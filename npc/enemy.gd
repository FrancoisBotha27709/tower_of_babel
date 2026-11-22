
class_name Enemy
extends CharacterBody3D

signal attack_started
signal attack_ended

const JUMP_HEIGHT_FACTOR := 2.0

@export var death: DeathComponent
@export var attack_hitbox: HitboxComponent
@export var steering: EnemySteering
@export var target_group := &"player"
@export var move_speed := 7.0
@export var acceleration := 40.0
@export var turn_speed := 10.0
@export var gravity := 30.0
@export var jump_margin := 0.5
@export var attack_range := 2.0
@export var attack_windup := 0.4
@export var attack_cooldown := 1.0

var target: Node3D
var active := true
var attacking := false
var windup_remaining := 0.0
var cooldown_remaining := 0.0

#region Lifecycle
func _ready() -> void:
	target = get_tree().get_first_node_in_group(target_group)
	death.dying.connect(deactivate)
	death.death_finished.connect(queue_free)
	steering.jump_requested.connect(jump)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	if not global_position.is_finite() or not velocity.is_finite():
		push_error("Enemy has an invalid position or velocity: " + str(get_path()))
		velocity = Vector3.ZERO
		return

	var offset := target.global_position - global_position
	if not offset.is_finite():
		return

	offset.y = 0.0

	var in_range := offset.length() <= attack_range
	var move_direction := Vector3.ZERO if not active or attacking or in_range else steering.steer(target, delta)

	if not move_direction.is_finite():
		push_error("Enemy steering returned an invalid direction: " + str(get_path()))
		move_direction = Vector3.ZERO

	var horizontal := Vector3(velocity.x, 0.0, velocity.z).move_toward(move_direction * move_speed, acceleration * delta)

	velocity = Vector3(horizontal.x, velocity.y - gravity * delta, horizontal.z)

	if active:
		if offset.length_squared() > 0.001:
			rotation.y = lerp_angle(rotation.y, atan2(-offset.x, -offset.z), 1.0 - exp(-turn_speed * delta))

		update_attack(delta, in_range)

	move_and_slide()
#endregion

#region Movement
func deactivate() -> void:
	active = false
	attacking = false

func jump(height: float) -> void:
	if is_on_floor() and height + jump_margin >= 0.0:
		velocity.y = sqrt(JUMP_HEIGHT_FACTOR * gravity * (height + jump_margin))
#endregion

#region Attack
func update_attack(delta: float, in_range: bool) -> void:
	cooldown_remaining = maxf(cooldown_remaining - delta, 0.0)

	if attacking:
		windup_remaining -= delta
		if windup_remaining <= 0.0:
			attack_hitbox.pulse()
			attacking = false
			cooldown_remaining = attack_cooldown
			attack_ended.emit()

	elif in_range and cooldown_remaining <= 0.0:
		attacking = true
		windup_remaining = attack_windup
		attack_started.emit()
#endregion
