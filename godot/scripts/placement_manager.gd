extends Node2D

@onready var asset_registry: Node = $"../AssetRegistry"
@onready var grid_manager: Node2D = $"../GridManager"
@onready var objects: Node2D = $"../Objects"


func place_from_palette(
	asset_type: String,
	drop_position: Vector2
) -> void:

	var selected_scene: PackedScene = get_scene_by_type(asset_type)

	if selected_scene == null:
		print("Unknown asset type: ", asset_type)
		return

	var object_size: Vector2 = get_size_by_type(asset_type)

	var snapped_position: Vector2 = grid_manager.snap_object_to_grid(
		drop_position,
		object_size
	)

	var new_rect := Rect2(
		snapped_position - object_size / 2.0,
		object_size
	)

	if is_outside_map(new_rect):
		print("배치 실패: 맵 밖입니다.")
		return

	if is_overlapping(new_rect):
		print("배치 실패: 다른 가구와 겹칩니다.")
		return

	var new_object := selected_scene.instantiate()
	
	var object_id: String = generate_object_id()

	new_object.set_meta(
		"object_id",
		object_id
	)

	new_object.position = snapped_position

	var asset_list: Array = asset_registry.get_assets_by_type(
		asset_type
	)

	if asset_list.is_empty():
		print("등록된 Asset이 없습니다: ", asset_type)
		return

	var asset_data: Dictionary = asset_list[0]
	var asset_id: String = asset_data.get(
		"asset_id",
		""
	)
	
	new_object.set_meta("object_id", object_id)
	new_object.set_meta("asset_type", asset_type)
	new_object.set_meta("asset_id", asset_id)

	objects.add_child(new_object)

	print(
		asset_type,
		" placed at ",
		snapped_position
	)

func get_scene_by_type(asset_type: String) -> PackedScene:
	var asset_list: Array = asset_registry.get_assets_by_type(
		asset_type
	)

	if asset_list.is_empty():
		return null

	var asset_data: Dictionary = asset_list[0]

	var scene_path: String = asset_data.get(
		"scene_path",
		""
	)

	if scene_path.is_empty():
		return null

	return load(scene_path) as PackedScene

func get_size_by_type(asset_type: String) -> Vector2:
	var asset_list: Array = asset_registry.get_assets_by_type(
		asset_type
	)

	if asset_list.is_empty():
		return Vector2.ZERO

	var asset_data: Dictionary = asset_list[0]

	var size_data: Dictionary = asset_data.get(
		"size",
		{}
	)

	return Vector2(
		float(size_data.get("width", 0)),
		float(size_data.get("height", 0))
	)


func is_outside_map(new_rect: Rect2) -> bool:
	var map_rect := Rect2(
		Vector2.ZERO,
		Vector2(
			grid_manager.grid_width,
			grid_manager.grid_height
		)
	)

	return not map_rect.encloses(new_rect)


func is_overlapping(new_rect: Rect2) -> bool:
	for existing_object in objects.get_children():

		if not existing_object.has_meta("asset_type"):
			continue

		var existing_type: String = existing_object.get_meta(
			"asset_type"
		)

		var existing_size: Vector2 = get_size_by_type(
			existing_type
		)

		var existing_rect := Rect2(
			existing_object.position - existing_size / 2.0,
			existing_size
		)

		if new_rect.intersects(existing_rect):
			return true

	return false

func generate_object_id() -> String:
	return "obj_" + str(Time.get_ticks_usec())
