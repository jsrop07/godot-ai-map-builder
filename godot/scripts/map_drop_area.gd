extends Control

@onready var placement_manager: Node = $"../../PlacementManager"


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and data.has("asset_type")
	)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var asset_type: String = data["asset_type"]

	placement_manager.place_from_palette(
		asset_type,
		at_position
	)
