# Map JSON Schema

## 목적

Godot AI Map Builder에서 현재 맵의 상태를 Godot, FastAPI, AI 시스템 사이에서 동일한 형식으로 전달하기 위한 JSON 규격이다.

AI는 Godot의 `.tscn` 파일을 직접 생성하거나 수정하지 않는다.

Godot 플러그인이 현재 씬을 Map JSON으로 변환하여 백엔드로 전송하고,
백엔드는 이 데이터를 기반으로 맵을 분석한 후 제한된 작업 명령을 반환한다.

## 기본 원칙

- 모든 오브젝트는 고유한 `object_id`를 가진다.
- 실제 에셋은 `asset_id`로 식별한다.
- 좌표는 Godot 2D 월드 좌표를 사용한다.
- 그리드 기반 배치를 위해 `grid_size`를 저장한다.
- 회전 값의 단위는 degree로 통일한다.
- AI가 직접 Godot 씬 파일을 생성하지 않는다.

## Map 구조

```json
{
  "schema_version": "1.0",
  "map_id": "map_001",
  "name": "test_map",
  "map_size": {
    "width": 1280,
    "height": 720
  },
  "grid_size": 32,
  "objects": []
}
```

## Map 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| schema_version | string | O | Map JSON 규격 버전 |
| map_id | string | O | 맵 고유 ID |
| name | string | O | 맵 이름 |
| map_size | object | O | 맵 전체 크기 |
| grid_size | integer | O | 한 그리드 셀의 픽셀 크기 |
| objects | array | O | 현재 맵에 존재하는 오브젝트 목록 |

`map_size`와 `grid_size`의 값은 예시이며,
실제 맵 생성 시 프로젝트 설정 또는 사용자 입력에 따라 달라질 수 있다.

## Object 구조

```json
{
  "object_id": "obj_001",
  "asset_id": "furniture_table_001",
  "type": "table",
  "position": {
    "x": 320,
    "y": 224
  },
  "rotation": 0,
  "scale": {
    "x": 1.0,
    "y": 1.0
  },
  "size": {
    "width": 96,
    "height": 64
  },
  "locked": false
}
```

## Object 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| object_id | string | O | 맵 안에서 사용하는 오브젝트 고유 ID |
| asset_id | string | O | Asset Registry에서 실제 Godot 에셋을 찾기 위한 ID |
| type | string | O | table, chair, cabinet 등의 오브젝트 종류 |
| position | object | O | Godot 2D 월드 좌표 |
| rotation | number | O | 회전 각도(degree) |
| scale | object | O | 오브젝트 X/Y 배율 |
| size | object | O | 오브젝트가 차지하는 기본 크기 |
| locked | boolean | O | AI가 해당 오브젝트를 수정할 수 있는지 여부 |

## 좌표 규칙

`position`은 Godot 2D 월드 좌표를 사용한다.

```json
{
  "position": {
    "x": 320,
    "y": 224
  }
}
```

기본 규칙:

- X 좌표는 오른쪽으로 갈수록 증가한다.
- Y 좌표는 아래쪽으로 갈수록 증가한다.
- 좌표 단위는 pixel이다.
- 오브젝트는 `grid_size`를 기준으로 스냅할 수 있다.

예를 들어 `grid_size`가 32인 경우:

- X = 320 → 그리드 X = 10
- Y = 224 → 그리드 Y = 7

## 회전 규칙

`rotation`은 degree 단위로 저장한다.

기본 지원 값:

- 0
- 90
- 180
- 270

예:

```json
{
  "rotation": 90
}
```

Godot에서 필요한 경우 degree 값을 radian으로 변환하여 사용한다.

## locked 규칙

`locked`는 사용자가 특정 오브젝트를 AI 수정 대상에서 제외할 때 사용한다.

```json
{
  "locked": true
}
```

- `false`: AI가 이동, 삭제, 교체 등의 작업을 수행할 수 있다.
- `true`: AI가 해당 오브젝트를 이동, 삭제, 교체하지 않는다.

## 전체 예제

```json
{
  "schema_version": "1.0",
  "map_id": "map_001",
  "name": "sample_kitchen",
  "map_size": {
    "width": 1280,
    "height": 720
  },
  "grid_size": 32,
  "objects": [
    {
      "object_id": "obj_001",
      "asset_id": "table_placeholder_001",
      "type": "table",
      "position": {
        "x": 320,
        "y": 224
      },
      "rotation": 0,
      "scale": {
        "x": 1.0,
        "y": 1.0
      },
      "size": {
        "width": 96,
        "height": 64
      },
      "locked": false
    },
    {
      "object_id": "obj_002",
      "asset_id": "chair_placeholder_001",
      "type": "chair",
      "position": {
        "x": 448,
        "y": 224
      },
      "rotation": 90,
      "scale": {
        "x": 1.0,
        "y": 1.0
      },
      "size": {
        "width": 32,
        "height": 32
      },
      "locked": false
    }
  ]
}
```

## 검증 규칙

Map JSON을 처리하기 전에 다음 조건을 검증한다.

- `schema_version`은 반드시 존재해야 한다.
- `map_id`는 빈 문자열일 수 없다.
- `map_size.width`와 `map_size.height`는 0보다 커야 한다.
- `grid_size`는 0보다 큰 정수여야 한다.
- `objects`는 배열이어야 한다.
- 모든 `object_id`는 맵 안에서 중복될 수 없다.
- 모든 오브젝트는 유효한 `asset_id`를 가져야 한다.
- `position.x`와 `position.y`는 숫자여야 한다.
- `rotation`은 degree 단위를 사용한다.
- 기본 회전 값은 0, 90, 180, 270 중 하나를 사용한다.
- `scale.x`와 `scale.y`는 0보다 커야 한다.
- `size.width`와 `size.height`는 0보다 커야 한다.
- `locked`는 boolean 값이어야 한다.