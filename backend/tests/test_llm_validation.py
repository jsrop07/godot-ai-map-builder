from app.services.llm_service import validate_operations


class FakeOperation:
    action = "teleport"
    object_id = "obj_ai_test_table"


class FakeResult:
    operations = [FakeOperation()]


def test_disallowed_action():
    map_data = {
        "objects": [
            {
                "object_id": "obj_ai_test_table"
            }
        ]
    }

    is_valid, message = validate_operations(
        result=FakeResult(),
        map_data=map_data,
    )

    print("검증 결과:", is_valid)
    print("검증 메시지:", message)

    assert is_valid is False
    assert "허용되지 않은 action" in message

from app.schemas.map_edit import (
    AddOperation,
    MoveOperation,
    RotateOperation,
    ReplaceOperation,
    DeleteOperation,
    Position,
)


def test_sample_operations():
    add_operation = AddOperation(
        action="add",
        object_id="obj_new_table",
        asset_id="table_001",
        position=Position(
            x=320,
            y=320,
        ),
        direction_index=0,
    )

    move_operation = MoveOperation(
        action="move",
        object_id="obj_ai_test_table",
        position=Position(
            x=500,
            y=320,
        ),
    )

    rotate_operation = RotateOperation(
        action="rotate",
        object_id="obj_ai_test_table",
        direction_index=1,
    )

    replace_operation = ReplaceOperation(
        action="replace",
        object_id="obj_ai_test_table",
        asset_id="chair_001",
    )

    delete_operation = DeleteOperation(
        action="delete",
        object_id="obj_ai_test_table",
    )

    assert add_operation.action == "add"
    assert move_operation.action == "move"
    assert rotate_operation.action == "rotate"
    assert replace_operation.action == "replace"
    assert delete_operation.action == "delete"