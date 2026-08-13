extends Node2D

const TABLE_SCENE := preload(
	"res://assets/scenes/table_asset.tscn"
)

const CHAIR_SCENE := preload(
	"res://assets/scenes/chair_asset.tscn"
)

const CABINET_SCENE := preload(
	"res://assets/scenes/cabinet_asset.tscn"
)

const BED_SCENE := preload(
	"res://assets/scenes/bed_asset.tscn"
)

const SOFA_SCENE := preload(
	"res://assets/scenes/sofa_asset.tscn"
)

const SHELF_SCENE := preload(
	"res://assets/scenes/shelf_asset.tscn"
)

const REFRIGERATOR_SCENE := preload(
	"res://assets/scenes/refrigerator_asset.tscn"
)

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

	new_object.position = snapped_position
	new_object.set_meta("asset_type", asset_type)

	objects.add_child(new_object)

	print(
		asset_type,
		" placed at ",
		snapped_position
	)


func get_scene_by_type(asset_type: String) -> PackedScene:
	match asset_type:
		"table":
			return TABLE_SCENE
		"chair":
			return CHAIR_SCENE
		"cabinet":
			return CABINET_SCENE
		"bed":
			return BED_SCENE
		"sofa":
			return SOFA_SCENE
		"shelf":
			return SHELF_SCENE
		"refrigerator":
			return REFRIGERATOR_SCENE

	return null


func get_size_by_type(asset_type: String) -> Vector2:
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
