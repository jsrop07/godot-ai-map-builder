@tool
extends EditorPlugin

var dock: Control


func _enter_tree() -> void:
	var dock_script = preload("res://addons/ai_map_builder/ai_chat_dock.gd")

	dock = dock_script.new()
	dock.name = "AI Map Builder"

	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

	dock.prompt_submitted.connect(_on_prompt_submitted)

	call_deferred("_add_test_object_to_editor")


func _exit_tree() -> void:
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()


func _on_prompt_submitted(prompt: String) -> void:
	print("AI 요청:")
	print(prompt)

	var edited_scene_root := get_editor_interface().get_edited_scene_root()

	if edited_scene_root == null:
		dock.set_request_failed("현재 열려 있는 씬이 없습니다.")
		return

	var backend_client := edited_scene_root.get_node_or_null("BackendClient")

	if backend_client == null:
		dock.set_request_failed("BackendClient를 찾을 수 없습니다.")
		return

	if not backend_client.has_method("send_map_request"):
		dock.set_request_failed("send_map_request 함수를 찾을 수 없습니다.")
		return

	backend_client.send_map_request(prompt)

	dock.set_request_finished("요청 전송 완료")

func _add_test_object_to_editor() -> void:
	var edited_scene_root := get_editor_interface().get_edited_scene_root()

	if edited_scene_root == null:
		print("편집 중인 씬이 없습니다.")
		return

	var objects := edited_scene_root.get_node_or_null("Objects")
	var asset_registry := edited_scene_root.get_node_or_null("AssetRegistry")

	if objects == null:
		print("Objects 노드를 찾을 수 없습니다.")
		return

	if asset_registry == null:
		print("AssetRegistry를 찾을 수 없습니다.")
		return
	
	for object in objects.get_children():
		if object.get_meta("object_id", "") == "obj_ai_test_table":
			print("테스트 Table이 이미 존재합니다.")
			return

	var asset_list: Array = asset_registry.get_assets_by_type("table")

	if asset_list.is_empty():
		print("등록된 table 에셋이 없습니다.")
		return

	var asset_data: Dictionary = asset_list[0]

	var scene_path: String = asset_data.get(
		"scene_path",
		""
	)

	var asset_id: String = asset_data.get(
		"asset_id",
		""
	)

	var packed_scene := load(scene_path) as PackedScene

	if packed_scene == null:
		print("Table Scene 로드 실패")
		return

	var new_object := packed_scene.instantiate()

	new_object.name = "AITestTable"
	new_object.position = Vector2(320, 320)

	new_object.set_meta(
		"object_id",
		"obj_ai_test_table"
	)

	new_object.set_meta(
		"asset_id",
		asset_id
	)

	new_object.set_meta(
		"asset_type",
		"table"
	)

	objects.add_child(new_object)

	# 에디터 씬의 실제 노드로 저장되게 만드는 핵심
	new_object.owner = edited_scene_root

	print("에디터 테스트 Table 생성 완료")