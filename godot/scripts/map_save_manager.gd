@tool
extends Node

@onready var objects: Node2D = $"../Objects"
@onready var asset_registry: Node = $"../AssetRegistry"

const SAVE_PATH := "user://map_save.json"


func save_map() -> void:
	var object_list: Array = []

	for object in objects.get_children():
		if not object.has_meta("asset_type"):
			continue

		var asset_type: String = object.get_meta(
			"asset_type",
			""
		)

		var asset_id: String = object.get_meta(
			"asset_id",
			""
		)

		var object_id: String = object.get_meta(
			"object_id",
			""
		)

		var direction_index: int = 0
		var locked: bool = false
		var flipped: bool = false

		var raw_direction = object.get("direction_index")
		var raw_locked = object.get("is_locked")
		var raw_flipped = object.get("is_flipped")

		if raw_direction != null:
			direction_index = int(raw_direction)

		if raw_locked != null:
			locked = bool(raw_locked)

		if raw_flipped != null:
			flipped = bool(raw_flipped)

		object_list.append({
			"object_id": object_id,
			"asset_id": asset_id,
			"type": asset_type,

			"position": {
				"x": object.position.x,
				"y": object.position.y
			},

			"rotation": direction_index * 90,
			"direction_index": direction_index,
			"locked": locked,
			"flipped": flipped
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

	print(
		"맵 저장 완료: ",
		ProjectSettings.globalize_path(SAVE_PATH)
	)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:

			# JSON 저장
			if (
				event.ctrl_pressed
				and not event.shift_pressed
				and event.keycode == KEY_S
			):
				save_map()

			# TSCN 저장
			if (
				event.ctrl_pressed
				and event.shift_pressed
				and event.keycode == KEY_S
			):
				save_map_as_tscn()

			# JSON 불러오기
			if event.ctrl_pressed and event.keycode == KEY_L:
				load_map()
			if (
				event.ctrl_pressed
				and event.shift_pressed
				and event.keycode == KEY_L
			):
				load_map_from_tscn()


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

	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		print(
			"JSON 파싱 실패: ",
			json.get_error_message()
		)
		return

	var map_data: Dictionary = json.data

	if not map_data.has("objects"):
		print("objects 데이터가 없습니다.")
		return

	# 현재 맵의 기존 가구 제거
	for object in objects.get_children():
		object.queue_free()

	for raw_object_data in map_data["objects"]:
		var object_data: Dictionary = raw_object_data

		var asset_id: String = object_data.get(
			"asset_id",
			""
		)

		var asset_type: String = object_data.get(
			"type",
			""
		)

		var selected_scene: PackedScene = get_scene_by_asset_id(
			asset_id
		)
		
		var object_id: String = object_data.get(
			"object_id",
			""
		)

		if selected_scene == null:
			print(
				"등록되지 않은 asset_id: ",
				asset_id
			)
			continue

		var new_object = selected_scene.instantiate()

		var position_data: Dictionary = object_data.get(
			"position",
			{}
		)

		new_object.position = Vector2(
			float(position_data.get("x", 0)),
			float(position_data.get("y", 0))
		)

		new_object.set_meta(
			"object_id",
			object_id
		)

		new_object.set_meta(
			"asset_id",
			asset_id
		)

		new_object.set_meta(
			"asset_type",
			asset_type
		)

		objects.add_child(new_object)

		# 방향 복원
		var saved_direction: int = int(
			object_data.get(
				"direction_index",
				0
			)
		)

		new_object.direction_index = saved_direction
		new_object.apply_direction_texture()

		# 좌우 반전 복원
		var flipped: bool = object_data.get(
			"flipped",
			false
		)

		new_object.is_flipped = flipped

		if flipped:
			new_object.visual.scale.x = -abs(
				new_object.visual.scale.x
			)

		# 잠금 복원
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


func get_scene_by_asset_id(
	asset_id: String
) -> PackedScene:

	var asset_data: Dictionary = asset_registry.get_asset(
		asset_id
	)

	if asset_data.is_empty():
		return null

	var scene_path: String = asset_data.get(
		"scene_path",
		""
	)

	if scene_path.is_empty():
		return null

	return load(scene_path) as PackedScene

func save_map_as_tscn() -> void:
	var generated_root := Node2D.new()
	generated_root.name = "GeneratedMap"

	for object in objects.get_children():
		var copied_object := object.duplicate()

		if copied_object == null:
			continue

		generated_root.add_child(copied_object)

		copied_object.owner = generated_root
		set_owner_recursive(
			copied_object,
			generated_root
		)

	var packed_scene := PackedScene.new()

	var pack_error := packed_scene.pack(
		generated_root
	)

	if pack_error != OK:
		print(
			"TS CN 생성 실패: ",
			pack_error
		)

		generated_root.free()
		return

	var directory_path := "user://generated_maps"

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			directory_path
		)
	)

	var save_path := (
		directory_path
		+ "/test_map.tscn"
	)

	var save_error := ResourceSaver.save(
		packed_scene,
		save_path
	)

	if save_error != OK:
		print(
			"TS CN 저장 실패: ",
			save_error
		)

		generated_root.free()
		return

	print(
		"TS CN 저장 완료: ",
		ProjectSettings.globalize_path(
			save_path
		)
	)

	generated_root.free()


func set_owner_recursive(
	node: Node,
	scene_owner: Node
) -> void:
	for child in node.get_children():
		child.owner = scene_owner

		set_owner_recursive(
			child,
			scene_owner
		)

func load_map_from_tscn() -> void:
	var save_path := "user://generated_maps/test_map.tscn"

	if not ResourceLoader.exists(save_path):
		print("TSCN 저장 파일이 없습니다.")
		return

	var packed_scene := load(save_path) as PackedScene

	if packed_scene == null:
		print("TSCN 불러오기 실패")
		return

	for object in objects.get_children():
		object.queue_free()

	var loaded_root := packed_scene.instantiate()

	for child in loaded_root.get_children():
		loaded_root.remove_child(child)
		objects.add_child(child)

	loaded_root.free()

	print("TSCN 불러오기 완료")

func get_current_map_data() -> Dictionary:
	var object_list: Array = []

	print("=== 현재 맵 오브젝트 확인 ===")
	print("Objects 자식 수: ", objects.get_child_count())

	for object in objects.get_children():
		print(
			"오브젝트: ",
			object.name,
			" / asset_type 있음: ",
			object.has_meta("asset_type"),
			" / asset_type: ",
			object.get_meta("asset_type", ""),
			" / asset_id: ",
			object.get_meta("asset_id", ""),
			" / object_id: ",
			object.get_meta("object_id", "")
		)

		if not object.has_meta("asset_type"):
			continue

		var asset_type: String = object.get_meta(
			"asset_type",
			""
		)

		var asset_id: String = object.get_meta(
			"asset_id",
			""
		)

		var object_id: String = object.get_meta(
			"object_id",
			""
		)
		var direction_index: int = 0
		var locked: bool = false
		var flipped: bool = false

		var raw_direction = object.get("direction_index")
		var raw_locked = object.get("is_locked")
		var raw_flipped = object.get("is_flipped")

		if raw_direction != null:
			direction_index = int(raw_direction)

		if raw_locked != null:
			locked = bool(raw_locked)

		if raw_flipped != null:
			flipped = bool(raw_flipped)
		object_list.append({
			"object_id": object_id,
			"asset_id": asset_id,
			"type": asset_type,

			"position": {
				"x": object.position.x,
				"y": object.position.y
			},

			"rotation": direction_index * 90,
			"direction_index": direction_index,
			"locked": locked,
			"flipped": flipped
		})

	return {
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
