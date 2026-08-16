@tool
extends Node

const BASE_URL := "http://127.0.0.1:8000"

@onready var http_request: HTTPRequest = $"../BackendHTTPRequest"
@onready var map_save_manager: Node = $"../MapSaveManager"
@onready var objects: Node2D = $"../Objects"
@onready var asset_registry: Node = $"../AssetRegistry"

func _ready() -> void:
	if not http_request.request_completed.is_connected(_on_request_completed):
		http_request.request_completed.connect(
			_on_request_completed
		)

func send_map_request(prompt: String) -> void:
	var request_data := {
		"request_id": "req_test_001",
		"prompt": prompt,
		"map": map_save_manager.get_current_map_data(),
		"available_assets": asset_registry.get_all_assets()
	}
		
	print("Current Map Data:")
	print(JSON.stringify(request_data["map"], "\t"))
	
	var body := JSON.stringify(request_data)

	var headers := PackedStringArray([
		"Content-Type: application/json"
	])

	var error := http_request.request(
		BASE_URL + "/api/map/edit",
		headers,
		HTTPClient.METHOD_POST,
		body
	)

	if error != OK:
		print(
			"POST 요청 시작 실패: ",
			error
		)
		return

	print("Map JSON POST 전송")
	print("Prompt: ", prompt)


func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray
) -> void:

	if result != HTTPRequest.RESULT_SUCCESS:
		print(
			"HTTP 요청 실패. result: ",
			result
		)
		return

	if response_code < 200 or response_code >= 300:
		print(
			"FastAPI 오류 응답. code: ",
			response_code
		)

		var error_text := body.get_string_from_utf8()

		if not error_text.is_empty():
			print(
				"오류 내용: ",
				error_text
			)

		return

	var response_text := body.get_string_from_utf8()

	print("HTTP Result: ", result)
	print("Response Code: ", response_code)
	print("Response Body: ", response_text)

	handle_response(response_text)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_P:
				send_map_request("P키 테스트 요청")

func handle_response(response_text: String) -> void:
	var json := JSON.new()

	var error := json.parse(response_text)

	if error != OK:
		print(
			"응답 JSON 파싱 실패: ",
			json.get_error_message()
		)
		return

	var response_data: Dictionary = json.data

	if not response_data.has("operations"):
		print("operations 데이터가 없습니다.")
		return

	for raw_operation in response_data["operations"]:
		var operation: Dictionary = raw_operation

		print(
			"Operation 수신: ",
			operation
		)

		apply_operation(operation)

func apply_operation(operation: Dictionary) -> void:
	var action: String = operation.get(
		"action",
		""
	)

	match action:
		"add":
			apply_add_operation(operation)

		"move":
			apply_move_operation(operation)

		"rotate":
			apply_rotate_operation(operation)

		"delete":
			apply_delete_operation(operation)

		"replace":
			apply_replace_operation(operation)

		"duplicate":
			apply_duplicate_operation(operation)
		
		"lock":
			apply_lock_operation(operation) 

		_:
			print(
				"지원하지 않는 Operation: ",
				action
			)

func apply_add_operation(operation: Dictionary) -> void:
	var asset_id: String = operation.get(
		"asset_id",
		""
	)

	var object_id: String = operation.get(
		"object_id",
		""
	)

	if object_id.is_empty():
		print("object_id가 없습니다.")
		return

	if find_object_by_id(object_id) != null:
		print(
			"이미 존재하는 object_id: ",
			object_id
		)
		return
		
	var asset_data: Dictionary = asset_registry.get_asset(
		asset_id
	)

	if asset_data.is_empty():
		print(
			"등록되지 않은 asset_id: ",
			asset_id
		)
		return

	var scene_path: String = asset_data.get(
		"scene_path",
		""
	)

	if scene_path.is_empty():
		print("scene_path가 없습니다.")
		return

	var packed_scene := load(scene_path) as PackedScene

	if packed_scene == null:
		print(
			"에셋 Scene 로드 실패: ",
			scene_path
		)
		return

	var new_object = packed_scene.instantiate()

	var position_data: Dictionary = operation.get(
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
		asset_data.get("type", "")
	)

	objects.add_child(new_object)

	var direction_index: int = int(
		operation.get(
			"direction_index",
			0
		)
	)

	new_object.direction_index = direction_index
	new_object.apply_direction_texture()

	print(
		"Add Operation 적용 완료: ",
		object_id
	)

func apply_move_operation(operation: Dictionary) -> void:
	var object_id: String = operation.get(
		"object_id",
		""
	)

	if object_id.is_empty():
		print("move: object_id가 없습니다.")
		return

	var target_object := find_object_by_id(
		object_id
	)

	if target_object == null:
		print(
			"move 대상 오브젝트를 찾을 수 없습니다: ",
			object_id
		)
		return

	var position_data: Dictionary = operation.get(
		"position",
		{}
	)

	var new_position := Vector2(
		float(position_data.get("x", target_object.position.x)),
		float(position_data.get("y", target_object.position.y))
	)

	target_object.position = new_position

	print(
		"Move Operation 적용 완료: ",
		object_id,
		" → ",
		new_position
	)
	
func find_object_by_id(object_id: String) -> Node:
	for object in objects.get_children():
		if object.get_meta("object_id", "") == object_id:
			return object

	return null

func apply_rotate_operation(operation: Dictionary) -> void:
	var object_id: String = operation.get(
		"object_id",
		""
	)

	if object_id.is_empty():
		print("rotate: object_id가 없습니다.")
		return

	var target_object := find_object_by_id(
		object_id
	)

	if target_object == null:
		print(
			"rotate 대상 오브젝트를 찾을 수 없습니다: ",
			object_id
		)
		return

	var direction_index: int = int(
		operation.get(
			"direction_index",
			target_object.direction_index
		)
	)

	if direction_index < 0 or direction_index > 3:
		print(
			"잘못된 direction_index: ",
			direction_index
		)
		return

	target_object.direction_index = direction_index
	target_object.apply_direction_texture()

	print(
		"Rotate Operation 적용 완료: ",
		object_id,
		" → direction ",
		direction_index
	)

func apply_delete_operation(operation: Dictionary) -> void:
	var object_id: String = operation.get(
		"object_id",
		""
	)

	if object_id.is_empty():
		print("delete: object_id가 없습니다.")
		return

	var target_object := find_object_by_id(
		object_id
	)

	if target_object == null:
		print(
			"delete 대상 오브젝트를 찾을 수 없습니다: ",
			object_id
		)
		return

	target_object.queue_free()

	print(
		"Delete Operation 적용 완료: ",
		object_id
	)

func apply_replace_operation(operation: Dictionary) -> void:
	var object_id: String = operation.get(
		"object_id",
		""
	)

	var new_asset_id: String = operation.get(
		"asset_id",
		""
	)

	if object_id.is_empty():
		print("replace: object_id가 없습니다.")
		return

	if new_asset_id.is_empty():
		print("replace: asset_id가 없습니다.")
		return

	var old_object := find_object_by_id(
		object_id
	)

	if old_object == null:
		print(
			"replace 대상 오브젝트를 찾을 수 없습니다: ",
			object_id
		)
		return

	var asset_data: Dictionary = asset_registry.get_asset(
		new_asset_id
	)

	if asset_data.is_empty():
		print(
			"등록되지 않은 asset_id: ",
			new_asset_id
		)
		return

	var scene_path: String = asset_data.get(
		"scene_path",
		""
	)

	if scene_path.is_empty():
		print("replace: scene_path가 없습니다.")
		return

	var packed_scene := load(scene_path) as PackedScene

	if packed_scene == null:
		print("replace: Scene 로드 실패")
		return

	# 기존 상태 저장
	var old_position: Vector2 = old_object.position
	var old_direction: int = old_object.direction_index
	var old_locked: bool = old_object.is_locked
	var old_flipped: bool = old_object.is_flipped

	# 새 에셋 생성
	var new_object = packed_scene.instantiate()

	new_object.position = old_position

	new_object.set_meta(
		"object_id",
		object_id
	)

	new_object.set_meta(
		"asset_id",
		new_asset_id
	)

	new_object.set_meta(
		"asset_type",
		asset_data.get("type", "")
	)

	objects.add_child(new_object)

	# 방향 유지
	new_object.direction_index = old_direction
	new_object.apply_direction_texture()

	# 반전 유지
	if old_flipped:
		new_object.is_flipped = true
		new_object.visual.scale.x = -abs(
			new_object.visual.scale.x
		)

	# 잠금 유지
	if old_locked:
		new_object.is_locked = true
		new_object.visual.modulate = Color(
			0.65,
			0.65,
			0.65,
			1.0
		)

	old_object.queue_free()

	print(
		"Replace Operation 적용 완료: ",
		object_id,
		" → ",
		new_asset_id
	)

func apply_duplicate_operation(operation: Dictionary) -> void:
	var object_id: String = operation.get(
		"object_id",
		""
	)

	var new_object_id: String = operation.get(
		"new_object_id",
		""
	)

	if object_id.is_empty():
		print("duplicate: object_id가 없습니다.")
		return

	if new_object_id.is_empty():
		print("duplicate: new_object_id가 없습니다.")
		return

	if find_object_by_id(new_object_id) != null:
		print(
			"이미 존재하는 new_object_id: ",
			new_object_id
		)
		return

	var source_object := find_object_by_id(
		object_id
	)

	if source_object == null:
		print(
			"duplicate 대상 오브젝트를 찾을 수 없습니다: ",
			object_id
		)
		return

	var duplicated_object := source_object.duplicate()

	if duplicated_object == null:
		print("오브젝트 복제 실패")
		return

	var position_data: Dictionary = operation.get(
		"position",
		{}
	)

	duplicated_object.position = Vector2(
		float(
			position_data.get(
				"x",
				source_object.position.x + 32
			)
		),
		float(
			position_data.get(
				"y",
				source_object.position.y
			)
		)
	)

	duplicated_object.set_meta(
		"object_id",
		new_object_id
	)

	objects.add_child(duplicated_object)

	print(
		"Duplicate Operation 적용 완료: ",
		object_id,
		" → ",
		new_object_id
	)

func apply_lock_operation(operation: Dictionary) -> void:
	var object_id: String = operation.get(
		"object_id",
		""
	)

	if object_id.is_empty():
		print("lock: object_id가 없습니다.")
		return

	var target_object := find_object_by_id(
		object_id
	)

	if target_object == null:
		print(
			"lock 대상 오브젝트를 찾을 수 없습니다: ",
			object_id
		)
		return

	var locked: bool = operation.get(
		"locked",
		true
	)

	target_object.is_locked = locked

	if target_object.visual != null:
		if locked:
			target_object.visual.modulate = Color(
				0.65,
				0.65,
				0.65,
				1.0
			)
		else:
			target_object.visual.modulate = target_object.original_modulate

	print(
		"Lock Operation 적용 완료: ",
		object_id,
		" → ",
		locked
	)
