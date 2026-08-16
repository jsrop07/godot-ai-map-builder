import json
import os
from dotenv import load_dotenv
from openai import OpenAI

from app.schemas.map_edit import LLMOperationResponse


load_dotenv()

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY")
)
ALLOWED_ACTIONS = {
    "add",
    "move",
    "rotate",
    "replace",
    "delete",
}


def validate_operations(
    result: LLMOperationResponse,
    map_data: dict,
) -> tuple[bool, str]:

    objects = map_data.get("objects", [])

    valid_object_ids = {
        obj.get("object_id", "")
        for obj in objects
        if obj.get("object_id")
    }

    for operation in result.operations:
        action = operation.action

        if action not in ALLOWED_ACTIONS:
            return (
                False,
                f"허용되지 않은 action입니다: {action}",
            )

        if action in {
            "move",
            "rotate",
            "replace",
            "delete",
        }:
            if operation.object_id not in valid_object_ids:
                return (
                    False,
                    f"존재하지 않는 object_id입니다: {operation.object_id}",
                )

        if action == "rotate":
            if operation.direction_index < 0 or operation.direction_index > 3:
                return (
                    False,
                    "direction_index는 0~3이어야 합니다.",
                )

        if action == "add":
            if operation.object_id in valid_object_ids:
                return (
                    False,
                    f"이미 존재하는 object_id입니다: {operation.object_id}",
                )

    return True, ""

def call_llm(
    prompt: str,
    map_data: dict,
    available_assets: list[dict],
    retry_reason: str | None = None,
) -> LLMOperationResponse:
    
    assets_json = json.dumps(
        available_assets,
        ensure_ascii=False,
        indent=2,
    )

    map_json = json.dumps(
        map_data,
        ensure_ascii=False,
        indent=2,
    )

    retry_text = ""

    if retry_reason:
        retry_text = (
            "\n\n이전 응답에 다음 문제가 있었습니다.\n"
            f"{retry_reason}\n"
            "위 문제를 수정해서 다시 작업 명령을 생성하세요."
        )

    response = client.responses.parse(
        model="gpt-4o-mini",
        input=[
            {
                "role": "system",
                "content": (
                    "너는 Godot 2D 맵 편집을 위한 자연어 요청을 "
                    "구조화된 맵 작업 명령으로 변환하는 역할이다.\n\n"

                    "중요 규칙:\n"
                    "1. object_id는 반드시 Current Map에 실제로 존재하는 "
                    "object_id 값을 그대로 사용해야 한다.\n"
                    "2. asset_id, 오브젝트 종류, 이름 등을 object_id 대신 사용하거나 "
                    "임의의 object_id를 만들어서는 안 된다.\n"
                    "3. Current Map에 요청 대상 오브젝트가 존재하지 않으면 "
                    "추측하거나 임의로 생성하지 말고 operations를 비워야 한다.\n"
                    "4. move 작업의 position은 이동량이 아니라 "
                    "이동 후의 최종 절대 좌표여야 한다.\n"
                    "5. 사용자가 이동 거리를 지정하면 그 값을 사용한다.\n"
                    "6. 사용자가 이동 거리를 지정하지 않으면 32픽셀 이동한다.\n"
                    "7. 오른쪽 이동은 현재 x 좌표에 이동 거리를 더한다.\n"
                    "8. 왼쪽 이동은 현재 x 좌표에서 이동 거리를 뺀다.\n"
                    "9. 아래쪽 이동은 현재 y 좌표에 이동 거리를 더한다.\n"
                    "10. 위쪽 이동은 현재 y 좌표에서 이동 거리를 뺀다.\n"
                    "11. 이동하지 않는 축의 좌표는 현재 값을 그대로 유지한다.\n"
                    "12. 사용자의 요청을 수행하는 데 필요한 작업만 생성한다.\n"
                    "13. add 작업을 생성할 때 object_id는 Current Map에 존재하지 않는 새로운 고유 ID여야 한다.\n"
                    "14. add 작업에서는 기존 오브젝트의 object_id를 재사용해서는 안 된다.\n"
                    "15. 새 object_id는 obj_ai_generated_ 접두사를 사용해서 생성한다.\n"
                    "16. 예를 들어 Current Map에 obj_ai_generated_1이 존재하면 다음 새 오브젝트는 obj_ai_generated_2처럼 기존에 없는 ID를 사용한다.\n"
                    "17. add 작업을 만들기 전에 Current Map의 모든 object_id를 확인하고, 새 object_id가 기존 ID와 중복되지 않는지 반드시 확인한다.\n"
                    "18. 여러 오브젝트가 대상이면 각 오브젝트마다 필요한 operation을 각각 생성한다.\n"
                    "19. 사용자의 요청 일부만 처리하고 나머지를 생략해서는 안 된다.\n"
                    "20. 위치 표현인 중앙, 왼쪽 끝, 오른쪽 끝, 위쪽 끝, 아래쪽 끝은 Current Map의 map_size와 대상 오브젝트의 현재 위치를 기준으로 계산한다.\n"
                    "21. '왼쪽 끝'이나 '좌측 끝'으로 이동할 때는 오브젝트 중심을 x=0에 두지 말고 맵 안쪽에 완전히 들어오도록 적절한 최소 x 좌표를 사용한다.\n"
                    "22. '오른쪽 끝', '위쪽 끝', '아래쪽 끝'도 오브젝트가 맵 밖으로 나가지 않도록 계산한다.\n"
                    "23. add 또는 replace 작업의 asset_id는 반드시 '사용 가능한 에셋' 목록에 실제로 존재하는 asset_id만 사용해야 한다.\n"
                    "24. '사용 가능한 에셋' 목록에 없는 asset_id를 임의로 만들어서는 안 된다.\n"
                    "25. 사용자가 에셋 종류만 말한 경우 type이 일치하는 실제 에셋 중 하나를 선택한다.\n"
                ),
            },
            {
                "role": "user",
                "content": (
                    f"사용자 요청:\n{prompt}\n\n"
                    f"Current Map:\n{map_json}\n\n"
                    f"사용 가능한 에셋:\n{assets_json}"
                    f"{retry_text}"
                ),
            },
        ],
        text_format=LLMOperationResponse,
    )

    return response.output_parsed
    
def generate_operations(
    prompt: str,
    map_data: dict,
    available_assets: list[dict],
) -> LLMOperationResponse:

    max_attempts = 2
    retry_reason: str | None = None

    for attempt in range(max_attempts):
        result = call_llm(
            prompt=prompt,
            map_data=map_data,
            available_assets=available_assets,
            retry_reason=retry_reason,
        )
            
        is_valid, error_message = validate_operations(
            result=result,
            map_data=map_data,
        )

        if is_valid:
            print(
                f"LLM Operation 검증 성공 "
                f"(시도 {attempt + 1}/{max_attempts})"
            )

            return result

        print(
            f"LLM Operation 검증 실패 "
            f"(시도 {attempt + 1}/{max_attempts}): "
            f"{error_message}"
        )

        retry_reason = error_message

    print("LLM Operation 재시도 횟수 초과")

    return LLMOperationResponse(
        operations=[]
    )