extends Node2D

@export var grid_size: int = 32
@export var grid_color: Color = Color(0.4, 0.4, 0.4, 0.5)
@export var grid_width: int = 1280
@export var grid_height: int = 720


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
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


func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / grid_size),
		floori(world_position.y / grid_size)
	)


func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(
		grid_position.x * grid_size,
		grid_position.y * grid_size
	)


func snap_to_grid(world_position: Vector2) -> Vector2:
	var grid_position := world_to_grid(world_position)
	return grid_to_world(grid_position)
