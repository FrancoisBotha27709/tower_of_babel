class_name HurtboxComponent
extends Area3D

signal hurt(hit: HitData)

@export_group("Punch Card")
@export var damage_height : float = 2.2
@export var damage_side_offset : float = 0.35
@export var damage_rise : float = 0.45
@export var damage_duration : float = 0.55
@export var damage_scale : float = 0.8
## Extra size for hits at or above the hit stop threshold.
@export var heavy_scale_multiplier : float = 1.35
## Half width / half height of the card.
@export var card_size : Vector2 = Vector2(0.85, 0.42)
## Number of jagged edge points around the card (even number).
@export var card_points : int = 22
## How deep the jagged notches cut in (0 = smooth ellipse).
@export_range(0.0, 0.5) var card_spike_depth : float = 0.16
@export_range(0.0, 0.4) var card_jitter : float = 0.1
## Italic-style lean of the card.
@export var card_slant : float = 0.3
@export var card_outline_scale : float = 1.14
@export var impact_line_count : int = 8

@export_group("Colors")
@export var card_color : Color = Color(1.0, 0.86, 0.1)
@export var card_heavy_color : Color = Color(1.0, 1.0, 1.0)
@export var card_outline_color : Color = Color(0.05, 0.03, 0.03)
@export var damage_text_color : Color = Color.WHITE
@export var heavy_text_color : Color = Color(1.0, 0.16, 0.1)
@export var damage_outline_color : Color = Color.BLACK

@export_group("Text")
@export var damage_font_size : int = 56
@export var damage_outline_size : int = 14
## Little comic word shown on heavy hits.
@export var punch_words : PackedStringArray = ["POW!", "BAM!", "WHAM!", "SMACK!", "BIFF!"]

@export_group("Hit Stop")
@export var hit_stop_enabled : bool = true
## Hits dealing at least this much damage trigger the impact frame.
@export var hit_stop_damage_threshold : float = 25.0
## Freeze length at the threshold, growing to the max at 3x the threshold.
@export var hit_stop_duration : float = 0.07
@export var hit_stop_max_duration : float = 0.13
## 0.0 = full freeze.
@export_range(0.0, 1.0) var hit_stop_time_scale : float = 0.0
## After the freeze, time eases back to normal over this long, so the
## game doesn't snap back to full speed.
@export var hit_stop_recovery : float = 0.15
## Camera jolt (world units) during the freeze. Uses Camera3D h/v offset.
@export var camera_shake : float = 0.05

@export_group("Impact Frame")
@export var impact_frame_enabled : bool = true
@export var impact_line_color : Color = Color(1.0, 1.0, 1.0)
## Darkening at the screen edges during the freeze.
@export_range(0.0, 1.0) var impact_dim : float = 0.45
## White flash on the first frames of the hit.
@export_range(0.0, 1.0) var impact_flash : float = 0.6

@export_group("Combat")
@export var health : HealthComponent
@export var damage_multiplier : float = 1.0
@export_range(0.0, 1.0) var damage_variation : float = 0.1
# Shared by every popup, built once.
var _outline_material : StandardMaterial3D
var _card_material : StandardMaterial3D
var _heavy_card_material : StandardMaterial3D
var _line_material : StandardMaterial3D

static var _controller : HitStopController
static var _impact_frame : ImpactFrame

#region Lifecycle

func _ready() -> void:
	monitoring = false

	_line_material = create_flat_material(card_outline_color, 8)
	_outline_material = create_flat_material(card_outline_color, 8)
	_card_material = create_flat_material(card_color, 9)
	_heavy_card_material = create_flat_material(card_heavy_color, 9)

#endregion

#region Hits



func receive_hit(hit: HitData) -> void:
	var random_multiplier := randf_range(1.0 - damage_variation, 1.0 + damage_variation)

	hit.damage *= damage_multiplier * random_multiplier

	var heavy := hit_stop_enabled and hit.damage >= hit_stop_damage_threshold

	show_damage_number(hit.damage, heavy)

	if heavy:
		play_impact(hit.damage)

	hurt.emit(hit)
	health.apply_hit(hit)

#endregion

#region Impact

func play_impact(damage: float) -> void:
	var weight := clampf(
		inverse_lerp(hit_stop_damage_threshold, hit_stop_damage_threshold * 3.0, damage),
		0.0,
		1.0
	)
	var freeze := lerpf(hit_stop_duration, hit_stop_max_duration, weight)

	# Everything below lives on the root, not on this node, so a killing
	# blow that frees the enemy can never leave the game frozen.
	if not is_instance_valid(_controller):
		_controller = HitStopController.new()
		get_tree().root.add_child(_controller)

	_controller.trigger(
		freeze,
		hit_stop_time_scale,
		hit_stop_recovery,
		camera_shake * lerpf(0.6, 1.0, weight)
	)

	if impact_frame_enabled:
		spawn_impact_frame(freeze)

func spawn_impact_frame(freeze: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

	var focus := global_position + Vector3.UP * damage_height * 0.5
	var center := Vector2(0.5, 0.5)
	if not camera.is_position_behind(focus):
		center = camera.unproject_position(focus) / get_viewport().get_visible_rect().size

	if is_instance_valid(_impact_frame):
		_impact_frame.queue_free()

	_impact_frame = ImpactFrame.new()
	_impact_frame.center = center
	_impact_frame.hold = freeze
	_impact_frame.fade = maxf(hit_stop_recovery * 0.6, 0.05)
	_impact_frame.line_color = impact_line_color
	_impact_frame.dim = impact_dim
	_impact_frame.flash = impact_flash
	get_tree().root.add_child(_impact_frame)

#endregion

#region Punch Card

func show_damage_number(amount: float, heavy: bool = false) -> void:
	var side := -1.0 if randi() % 2 == 0 else 1.0

	var popup := DamagePopup.new()
	popup.name = "DamagePopup"
	popup.top_level = true
	popup.anchor = global_position + Vector3.UP * damage_height
	popup.side = side
	popup.side_offset = damage_side_offset
	popup.rise = damage_rise
	popup.duration = damage_duration
	popup.peak_scale = damage_scale * (heavy_scale_multiplier if heavy else 1.0)
	popup.base_roll = deg_to_rad(-9.0 * side + randf_range(-5.0, 5.0))

	# Impact lines first so they sit behind everything.
	var lines := MeshInstance3D.new()
	lines.name = "ImpactLines"
	lines.mesh = create_impact_lines_mesh()
	lines.material_override = _line_material
	popup.add_child(lines)
	popup.lines = lines

	var card_mesh := create_card_mesh()

	var outline := MeshInstance3D.new()
	outline.name = "CardOutline"
	outline.mesh = card_mesh
	outline.material_override = _outline_material
	outline.scale = Vector3(card_outline_scale, card_outline_scale * 1.1, 1.0)
	popup.add_child(outline)

	var card := MeshInstance3D.new()
	card.name = "Card"
	card.mesh = card_mesh
	card.material_override = _heavy_card_material if heavy else _card_material
	card.position.z = 0.01
	popup.add_child(card)

	var label := Label3D.new()
	label.name = "Label"
	label.text = str(snappedf(amount, 0.1)) + "!"
	label.position = Vector3(card_slant * 0.0, 0.0, 0.04)
	label.font_size = damage_font_size
	label.outline_size = damage_outline_size
	label.modulate = heavy_text_color if heavy else damage_text_color
	label.outline_modulate = damage_outline_color
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED # popup faces the camera itself
	label.no_depth_test = true
	label.render_priority = 12
	label.outline_render_priority = 11
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_child(label)

	if heavy and punch_words.size() > 0:
		var word := Label3D.new()
		word.name = "Word"
		word.text = punch_words[randi() % punch_words.size()]
		word.position = Vector3(-card_size.x * 0.45, card_size.y * 1.15, 0.05)
		word.rotation.z = deg_to_rad(12.0)
		word.font_size = int(damage_font_size * 0.6)
		word.outline_size = int(damage_outline_size * 0.8)
		word.modulate = Color(1.0, 0.86, 0.1)
		word.outline_modulate = damage_outline_color
		word.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		word.no_depth_test = true
		word.render_priority = 14
		word.outline_render_priority = 13
		word.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		word.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		popup.add_child(word)

	# Parent to the scene (not this node) so the number survives if the
	# enemy is freed by the killing blow.
	var scene := get_tree().current_scene
	if scene == null:
		scene = get_tree().root
	scene.add_child(popup)

#endregion

#region Creation

## A wide, slanted, jagged-edged badge, not a round star, so it reads as a
## comic "hit" panel rather than an explosion.
func create_card_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	var points := maxi(card_points, 6)
	var rim : Array[Vector3] = []

	for point_index in points:
		var angle := TAU * float(point_index) / float(points)
		var factor := 1.0 + randf_range(0.0, card_jitter) if point_index % 2 == 0 \
			else 1.0 - card_spike_depth - randf_range(0.0, card_jitter)

		var x := cos(angle) * card_size.x * factor
		var y := sin(angle) * card_size.y * factor
		rim.append(Vector3(x + y * card_slant, y, 0.0))

	vertices.append(Vector3.ZERO)
	normals.append(Vector3.BACK)

	for point in rim:
		vertices.append(point)
		normals.append(Vector3.BACK)

	for point_index in points:
		indices.append(0)
		indices.append(1 + point_index)
		indices.append(1 + (point_index + 1) % points)

	return build_mesh(vertices, normals, indices)

## Thin black comic "hit" dashes shooting out from around the card.
func create_impact_lines_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	var count := maxi(impact_line_count, 1)
	var offset := randf() * TAU

	for line_index in count:
		var angle := offset + TAU * float(line_index) / float(count) + randf_range(-0.2, 0.2)
		var direction := Vector2(cos(angle), sin(angle))
		var normal := Vector2(-direction.y, direction.x)

		var start_k := 1.2
		var end_k := start_k + randf_range(0.25, 0.5)
		var half_width := randf_range(0.03, 0.055)

		var start := Vector2(direction.x * card_size.x, direction.y * card_size.y) * start_k
		var tip := Vector2(direction.x * card_size.x, direction.y * card_size.y) * end_k
		var base_a := start + normal * half_width
		var base_b := start - normal * half_width

		var vertex_start := vertices.size()
		for p in [base_a, base_b, tip]:
			vertices.append(Vector3(p.x + p.y * card_slant, p.y, 0.0))
			normals.append(Vector3.BACK)

		indices.append(vertex_start)
		indices.append(vertex_start + 1)
		indices.append(vertex_start + 2)

	return build_mesh(vertices, normals, indices)

func build_mesh(vertices: PackedVector3Array, normals: PackedVector3Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	return mesh

func create_flat_material(color: Color, priority: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	material.render_priority = priority

	return material

#endregion

#region Popup

## Self-contained punch card. Runs on real time (not game time) so it still
## slams in during the freeze, and faces the camera every frame.
class DamagePopup extends Node3D:
	var anchor : Vector3
	var side : float = 1.0
	var side_offset : float = 0.35
	var rise : float = 0.45
	var duration : float = 0.55
	var peak_scale : float = 0.8
	var base_roll : float = 0.0
	var lines : Node3D

	var _born_usec : int = 0

	const START_SCALE := 1.9   # card starts huge and slams down
	const SLAM_TIME := 0.09    # seconds for the slam
	const SHAKE_TIME := 0.28   # seconds of shake after landing
	const EXIT_START := 0.78   # fraction of lifetime when it snaps away

	func _ready() -> void:
		_born_usec = Time.get_ticks_usec()
		_update(0.0)

	func _process(_delta: float) -> void:
		var t := float(Time.get_ticks_usec() - _born_usec) / 1000000.0 / duration

		if t >= 1.0:
			queue_free()
			return

		_update(t)

	func _update(t: float) -> void:
		var camera := get_viewport().get_camera_3d()
		if camera == null:
			return

		var elapsed := t * duration

		# Slam: big -> normal, fast, no bounce.
		var slam := clampf(elapsed / SLAM_TIME, 0.0, 1.0)
		var slam_ease := 1.0 - pow(1.0 - slam, 3.0)
		var s := lerpf(START_SCALE, 1.0, slam_ease)

		# Quick snap away at the end.
		if t > EXIT_START:
			var k := (t - EXIT_START) / (1.0 - EXIT_START)
			s *= 1.0 - k * k

		s = maxf(s * peak_scale, 0.001)

		# Landing shake that dies out.
		var shake := maxf(1.0 - elapsed / SHAKE_TIME, 0.0)
		var jitter_x := sin(elapsed * 130.0) * 0.05 * shake
		var jitter_y := cos(elapsed * 110.0) * 0.04 * shake
		var roll := base_roll + sin(elapsed * 95.0) * 0.1 * shake

		var move := 1.0 - pow(1.0 - t, 3.0)
		var cam_basis := camera.global_basis

		# Offsets are in camera space so side/rise read correctly on screen.
		global_position = anchor \
			+ cam_basis.x * (side_offset * side + jitter_x) \
			+ cam_basis.y * (rise * move + jitter_y)

		global_basis = (cam_basis * Basis(Vector3.BACK, roll)).scaled(Vector3.ONE * s)

		if lines != null:
			var line_k := 1.0 - pow(1.0 - clampf(elapsed / 0.12, 0.0, 1.0), 3.0)
			lines.scale = Vector3.ONE * lerpf(0.55, 1.0, line_k)
			lines.visible = t < 0.55

#endregion

#region Hit Stop Controller

## Owns Engine.time_scale. Lives on the scene root and runs on real time:
## hold the freeze, then ease back to the original speed instead of snapping.
class HitStopController extends Node:
	var _active := false
	var _saved_scale := 1.0
	var _freeze_scale := 0.0
	var _freeze_end_usec := 0
	var _recovery_sec := 0.15
	var _shake := 0.0

	var _camera : Camera3D
	var _camera_h := 0.0
	var _camera_v := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		set_process(false)

	func trigger(freeze: float, freeze_scale: float, recovery: float, shake: float) -> void:
		if not _active:
			_active = true
			_saved_scale = Engine.time_scale

			_camera = get_viewport().get_camera_3d()
			if _camera != null:
				_camera_h = _camera.h_offset
				_camera_v = _camera.v_offset

		_freeze_scale = freeze_scale
		_recovery_sec = maxf(recovery, 0.001)
		_shake = maxf(_shake, shake)

		# Overlapping hits extend the freeze instead of stacking.
		var end := Time.get_ticks_usec() + int(freeze * 1000000.0)
		_freeze_end_usec = maxi(_freeze_end_usec, end)

		Engine.time_scale = freeze_scale
		set_process(true)

	func _process(_delta: float) -> void:
		var now := Time.get_ticks_usec()
		var shake_k := 1.0

		if now < _freeze_end_usec:
			Engine.time_scale = _freeze_scale
		else:
			var r := float(now - _freeze_end_usec) / 1000000.0 / _recovery_sec
			if r >= 1.0:
				_finish()
				return

			# Ease-in so it stays slow a moment, then accelerates out.
			Engine.time_scale = lerpf(_freeze_scale, _saved_scale, r * r)
			shake_k = 1.0 - r

		if _camera != null and is_instance_valid(_camera):
			_camera.h_offset = _camera_h + randf_range(-1.0, 1.0) * _shake * shake_k
			_camera.v_offset = _camera_v + randf_range(-1.0, 1.0) * _shake * shake_k

	func _finish() -> void:
		Engine.time_scale = _saved_scale

		if _camera != null and is_instance_valid(_camera):
			_camera.h_offset = _camera_h
			_camera.v_offset = _camera_v

		_active = false
		_freeze_end_usec = 0
		_shake = 0.0
		set_process(false)

	func _exit_tree() -> void:
		if _active:
			_finish()

#endregion

#region Impact Frame

## Full-screen manga-style impact frame: white flash, dark edges and radial
## speed lines centered on the enemy, held for the length of the freeze.
class ImpactFrame extends CanvasLayer:
	var center := Vector2(0.5, 0.5)
	var hold := 0.08
	var fade := 0.08
	var line_color := Color.WHITE
	var dim := 0.45
	var flash := 0.6

	var _material : ShaderMaterial
	var _born_usec := 0

	const SHADER_CODE := """
shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform vec4 line_color : source_color = vec4(1.0);
uniform float strength = 1.0;
uniform float flash = 0.0;
uniform float dim = 0.4;
uniform float seed = 0.0;
uniform float line_count = 70.0;

float hash(float n) {
	return fract(sin(n * 127.1 + seed) * 43758.5453);
}

void fragment() {
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = UV - center;
	p.x *= aspect;
	float r = length(p);

	float a = (atan(p.y, p.x) / TAU + 0.5) * line_count;
	float id = floor(a);
	float h = hash(id);
	float f = abs(fract(a) - 0.5) * 2.0;

	float inner = 0.2 + h * 0.25;
	float taper = smoothstep(inner, inner + 0.5, r);
	float width = taper * (0.25 + h * 0.6);

	float s = step(f, width) * step(0.25, h);
	s *= smoothstep(inner, inner + 0.04, r) * strength;

	float vignette = smoothstep(0.15, 0.8, r) * dim * strength;

	vec4 c = vec4(0.0, 0.0, 0.0, vignette);
	c = mix(c, vec4(line_color.rgb, 1.0), s);
	c = mix(c, vec4(1.0), flash);
	COLOR = c;
}
"""

	func _ready() -> void:
		layer = 100
		process_mode = Node.PROCESS_MODE_ALWAYS
		_born_usec = Time.get_ticks_usec()

		var shader := Shader.new()
		shader.code = SHADER_CODE

		_material = ShaderMaterial.new()
		_material.shader = shader
		_material.set_shader_parameter("center", center)
		_material.set_shader_parameter("line_color", line_color)
		_material.set_shader_parameter("dim", dim)
		_material.set_shader_parameter("seed", randf() * 100.0)

		var rect := ColorRect.new()
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.material = _material
		add_child(rect)

		_update(0.0)

	func _process(_delta: float) -> void:
		var t := float(Time.get_ticks_usec() - _born_usec) / 1000000.0

		if t >= hold + fade:
			queue_free()
			return

		_update(t)

	func _update(t: float) -> void:
		var strength := 1.0
		if t > hold:
			strength = 1.0 - (t - hold) / fade

		var flash_now := flash * clampf(1.0 - t / 0.05, 0.0, 1.0)

		_material.set_shader_parameter("strength", strength)
		_material.set_shader_parameter("flash", flash_now)

#endregion