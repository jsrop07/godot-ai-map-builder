extends Node2D

@export var grid_size: int = 32
@export var grid_color: Color = Color(0.4, 0.4, 0.4, 0.5)
@export var grid_width: int = 1152
@export var grid_height: int = 640

var snap_marker_position: Vector2 = Vector2.ZERO
var show_snap_marker: bool = false

func _ready():
	queue_redraw()


func _draw():
	for x in range(0, grid_width + 1, grid_size):
		draw_line(
			Vector2(x, 0),
			Vector2(x, grid_height),
			grid_color,
			1.0
		)

	for y in range(0, grid_height + 1, grid_size):
		draw_line(
			Vector2(0, y),
			Vector2(grid_width, y),
			grid_color,
			1.0
		)

	if show_snap_marker:
		draw_circle(
			snap_marker_position,
			6.0,
			Color(1.0, 0.2, 0.2, 1.0)
		)


func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		roundi(world_position.x / grid_size),
		roundi(world_position.y / grid_size)
	)


func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(
		grid_position.x * grid_size,
		grid_position.y * grid_size
	)


func snap_to_grid(world_position: Vector2) -> Vector2:
	var grid_position = world_to_grid(world_position)
	return grid_to_world(grid_position)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position := get_global_mouse_position()

			if not is_inside_map(mouse_position):
				print("맵 밖 좌표: ", mouse_position)
				return

			snap_marker_position = snap_to_grid(mouse_position)
			show_snap_marker = true
			queue_redraw()

			print(
				"Clicked: ",
				mouse_position,
				" / Snapped: ",
				snap_marker_position
			)

func is_inside_map(world_position: Vector2) -> bool:
	return (
		world_position.x >= 0
		and world_position.y >= 0
		and world_position.x <= grid_width
		and world_position.y <= grid_height
	)

func snap_object_to_grid(
	world_position: Vector2,
	object_size: Vector2
) -> Vector2:
	var half_size: Vector2 = object_size / 2.0

	# 현재 마우스 위치 기준으로 오브젝트의 왼쪽 위 좌표 계산
	var top_left: Vector2 = world_position - half_size

	# 왼쪽 위 모서리를 가장 가까운 그리드 선에 맞춤
	top_left.x = round(top_left.x / grid_size) * grid_size
	top_left.y = round(top_left.y / grid_size) * grid_size

	# 오브젝트 전체가 맵 안쪽에 있도록 제한
	top_left.x = clamp(
		top_left.x,
		0.0,
		float(grid_width) - object_size.x
	)

	top_left.y = clamp(
		top_left.y,
		0.0,
		float(grid_height) - object_size.y
	)

	# Node2D 위치는 중심점이므로 다시 중심 좌표로 변환
	return top_left + half_size
