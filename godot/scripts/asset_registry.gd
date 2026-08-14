extends Node

const REGISTRY_PATH := "res://data/asset_registry.json"

var assets_by_id: Dictionary = {}
var assets_by_type: Dictionary = {}


func _ready() -> void:
	load_registry()


func load_registry() -> void:
	if not FileAccess.file_exists(REGISTRY_PATH):
		push_error(
			"Asset Registry 파일이 없습니다: " + REGISTRY_PATH
		)
		return

	var file := FileAccess.open(
		REGISTRY_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("Asset Registry 파일을 열 수 없습니다.")
		return

	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)

	if error != OK:
		push_error(
			"Asset Registry JSON 파싱 실패: "
			+ json.get_error_message()
		)
		return

	var data: Dictionary = json.data

	if not data.has("assets"):
		push_error("Asset Registry에 assets 배열이 없습니다.")
		return

	assets_by_id.clear()
	assets_by_type.clear()

	for asset_data in data["assets"]:
		var asset_id: String = asset_data.get(
			"asset_id",
			""
		)

		var asset_type: String = asset_data.get(
			"type",
			""
		)

		if asset_id.is_empty():
			continue

		assets_by_id[asset_id] = asset_data

		if not assets_by_type.has(asset_type):
			assets_by_type[asset_type] = []

		assets_by_type[asset_type].append(
			asset_data
		)

	print(
		"Asset Registry Loaded: ",
		assets_by_id.size(),
		" assets"
	)


func get_asset(asset_id: String) -> Dictionary:
	return assets_by_id.get(
		asset_id,
		{}
	)


func get_assets_by_type(
	asset_type: String
) -> Array:
	return assets_by_type.get(
		asset_type,
		[]
	)
