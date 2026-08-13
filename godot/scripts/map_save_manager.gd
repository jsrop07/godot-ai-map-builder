extends Node

@onready var objects: Node2D = $"../Objects"

const SAVE_PATH := "user://map_save.json"

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

func save_map() -> void:
	var object_list: Array = []

	for object in objects.get_children():
		if not object.has_meta("asset_type"):
			continue

		var asset_type: String = object.get_meta(
			"asset_type",
			""
		)

		object_list.append({
			"asset_id": asset_type,
			"type": asset_type,

			"position": {
				"x": object.position.x,
				"y": object.position.y
			},

			"rotation": object.rotation_degrees,

			"locked": object.is_locked,
			"flipped": object.is_flipped
		})

	var map_data := {
		"schema_version": "1.0",
		"map_id": "test_map",
		"name": "Test Map",

		"map_size": {
			"width": 1152,
			"height": 640
		},

		"grid_size": 32,

		"objects": object_list
	}

	var json_text := JSON.stringify(
		map_data,
		"\t"
	)

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		print("맵 저장 실패")
		return

	file.store_string(json_text)
	file.close()

	print("맵 저장 완료: ", ProjectSettings.globalize_path(SAVE_PATH))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:

			if event.ctrl_pressed and event.keycode == KEY_S:
				save_map()

			if event.ctrl_pressed and event.keycode == KEY_L:
				load_map()

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

func load_map() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("저장 파일이 없습니다.")
		return

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		print("맵 불러오기 실패")
		return

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()

	var error := json.parse(json_text)

	if error != OK:
		print("JSON 파싱 실패: ", json.get_error_message())
		return

	var map_data: Dictionary = json.data

	if not map_data.has("objects"):
		print("objects 데이터가 없습니다.")
		return

	for object in objects.get_children():
		object.queue_free()

	for object_data in map_data["objects"]:
		var asset_type: String = object_data.get(
			"type",
			""
		)

		var selected_scene: PackedScene = get_scene_by_type(
			asset_type
		)

		if selected_scene == null:
			print("알 수 없는 asset type: ", asset_type)
			continue

		var new_object := selected_scene.instantiate()

		var position_data: Dictionary = object_data["position"]

		new_object.position = Vector2(
			float(position_data["x"]),
			float(position_data["y"])
		)

		new_object.rotation_degrees = float(
			object_data.get("rotation", 0)
		)

		new_object.set_meta(
			"asset_type",
			asset_type
		)

		objects.add_child(new_object)


		var flipped: bool = object_data.get(
			"flipped",
			false
		)

		new_object.is_flipped = flipped

		if flipped:
			new_object.visual.scale.x = -abs(
				new_object.visual.scale.x
			)


		var locked: bool = object_data.get(
			"locked",
			false
		)

		if locked:
			new_object.is_locked = true
			new_object.visual.modulate = Color(
				0.65,
				0.65,
				0.65,
				1.0
			)
	print("맵 불러오기 완료")
