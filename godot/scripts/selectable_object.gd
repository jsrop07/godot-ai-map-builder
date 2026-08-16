@tool
extends Node2D

@export var texture_se: Texture2D
@export var texture_sw: Texture2D
@export var texture_nw: Texture2D
@export var texture_ne: Texture2D

var visual: CanvasItem

@onready var click_area: Area2D = $ClickArea
var grid_manager: Node2D

var is_selected: bool = false
var original_modulate: Color

var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

var direction_index: int = 0
var is_locked: bool = false
var is_flipped: bool = false

const OFFSET_MOVE_SPEED := 30.0

const GRID_SIZE := 32

func _ready() -> void:
	var parent_node := get_parent()

	if parent_node != null:
		var scene_root := parent_node.get_parent()

		if scene_root != null:
			grid_manager = scene_root.get_node_or_null("GridManager")

	visual = get_node_or_null("Polygon2D") as CanvasItem

	if visual == null:
		visual = get_node_or_null("Sprite2D") as CanvasItem

	if visual == null:
		push_error(
			"Polygon2D 또는 Sprite2D가 없습니다: " + name
		)
		return

	original_modulate = visual.modulate

	add_to_group("selectable_objects")

	if click_area != null:
		if not click_area.input_event.is_connected(
			_on_click_area_input_event
		):
			click_area.input_event.connect(
				_on_click_area_input_event
			)


func _process(delta: float) -> void:
	if is_locked:
		is_dragging = false
		return

	if is_dragging:
		if grid_manager == null:
			return

		var mouse_position: Vector2 = get_global_mouse_position()
		var object_size: Vector2 = get_occupied_size()

		var target_position: Vector2 = grid_manager.snap_object_to_grid(
			mouse_position + drag_offset,
			object_size
		)

		if not is_overlapping_at(target_position):
			position = target_position

	if not is_selected:
		return
	
	if is_selected and visual is Sprite2D:
		var offset_direction := Vector2.ZERO

		if Input.is_key_pressed(KEY_U):
			offset_direction.y -= 1

		if Input.is_key_pressed(KEY_J):
			offset_direction.y += 1

		if Input.is_key_pressed(KEY_H):
			offset_direction.x -= 1

		if Input.is_key_pressed(KEY_K):
			offset_direction.x += 1

		if offset_direction != Vector2.ZERO:
			visual.position += (
				offset_direction.normalized()
				* OFFSET_MOVE_SPEED
				* delta
			)

			print("Sprite Offset: ", visual.position)

	if Input.is_action_just_pressed("ui_left"):
		position.x -= GRID_SIZE

	if Input.is_action_just_pressed("ui_right"):
		position.x += GRID_SIZE

	if Input.is_action_just_pressed("ui_up"):
		position.y -= GRID_SIZE

	if Input.is_action_just_pressed("ui_down"):
		position.y += GRID_SIZE

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed and is_dragging:
				is_dragging = false

	if event is InputEventKey:
		if event.pressed and not event.echo:

			if is_selected and event.keycode == KEY_L:
				toggle_lock()
				return

			if is_selected and is_locked:
				return

			if is_selected and event.keycode == KEY_R:
				rotate_direction()

			if is_selected and event.keycode == KEY_DELETE:
				queue_free()

			if is_selected and event.ctrl_pressed and event.keycode == KEY_D:
				duplicate_object()
			
			if is_selected and event.keycode == KEY_F:
				toggle_flip()

func _on_click_area_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				select_object()

				is_dragging = true

				drag_offset = (
					global_position
					- get_global_mouse_position()
				)


func select_object() -> void:
	for object in get_tree().get_nodes_in_group(
		"selectable_objects"
	):
		object.set_selected(false)

	set_selected(true)

	print("Selected: ", name)


func set_selected(value: bool) -> void:
	is_selected = value

	if visual == null:
		return

	if is_selected:
		visual.modulate = Color(
			1.0,
			0.85,
			0.2,
			1.0
		)
	else:
		visual.modulate = original_modulate

func toggle_lock() -> void:
	is_locked = not is_locked

	if visual == null:
		return

	if is_locked:
		visual.modulate = Color(
			0.65,
			0.65,
			0.65,
			1.0
		)
		print("Locked: ", name)
	else:
		visual.modulate = original_modulate
		print("Unlocked: ", name)

func get_object_size() -> Vector2:
	var asset_type: String = get_meta("asset_type", "")

	match asset_type:
		"table":
			return Vector2(96, 64)
		"chair":
			return Vector2(32, 32)
		"cabinet":
			return Vector2(64, 32)
		"bed":
			return Vector2(64, 96)
		"sofa":
			return Vector2(96, 64)
		"shelf":
			return Vector2(96, 32)
		"refrigerator":
			return Vector2(32, 64)

	return Vector2.ZERO

func get_occupied_size() -> Vector2:
	var object_size: Vector2 = get_object_size()

	var normalized_rotation := int(round(rotation_degrees)) % 360
	if normalized_rotation < 0:
		normalized_rotation += 360

	if normalized_rotation == 90 or normalized_rotation == 270:
		return Vector2(
			object_size.y,
			object_size.x
		)

	return object_size

func duplicate_object() -> void:
	var parent_node := get_parent()

	if parent_node == null:
		return

	var object_size: Vector2 = get_object_size()

	# 선택/드래그 상태를 복제하지 않도록 먼저 초기화
	is_dragging = false
	set_selected(false)

	var duplicated_object = duplicate()

	if duplicated_object == null:
		set_selected(true)
		return

	# 가구 폭만큼 오른쪽에 배치
	var target_position := position + Vector2(
		object_size.x,
		0
	)

	# 그리드 + 맵 경계 적용
	target_position = grid_manager.snap_object_to_grid(
		target_position,
		object_size
	)

	duplicated_object.position = target_position

	parent_node.add_child(duplicated_object)

	duplicated_object.set_meta(
		"object_id",
		"obj_" + str(Time.get_ticks_usec())
	)

	# 복제본 상태 초기화
	duplicated_object.is_dragging = false
	duplicated_object.set_selected(true)

	print(
		"Duplicated: ",
		name,
		" → ",
		target_position
	)

func is_overlapping_at(
	target_position: Vector2
) -> bool:
	var object_size: Vector2 = get_occupied_size()

	var target_rect := Rect2(
		target_position - object_size / 2.0,
		object_size
	)

	for other_object in get_parent().get_children():
		if other_object == self:
			continue

		if not other_object.has_method("get_occupied_size"):
			continue

		var other_size: Vector2 = other_object.get_occupied_size()

		var other_rect := Rect2(
			other_object.position - other_size / 2.0,
			other_size
		)

		if target_rect.intersects(other_rect):
			return true

	return false

func toggle_flip() -> void:
	is_flipped = not is_flipped

	if visual == null:
		return

	visual.scale.x = -abs(visual.scale.x) if is_flipped else abs(visual.scale.x)

	print("Flipped: ", is_flipped)

func adjust_sprite_offset(offset: Vector2) -> void:
	if visual == null:
		return

	if visual is Sprite2D:
		visual.position += offset

		print(
			"Sprite Offset: ",
			visual.position
		)

func rotate_direction() -> void:
	if not visual is Sprite2D:
		return

	direction_index = (direction_index + 1) % 4

	apply_direction_texture()

	print("Direction: ", direction_index)

func apply_direction_texture() -> void:
	if not visual is Sprite2D:
		return

	match direction_index:
		0:
			visual.texture = texture_se
		1:
			visual.texture = texture_sw
		2:
			visual.texture = texture_nw
		3:
			visual.texture = texture_ne
