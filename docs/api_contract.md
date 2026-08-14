# Godot ↔ FastAPI API Contract

## 1. 목적

Godot EditorPlugin과 FastAPI 백엔드 사이에서
맵 정보와 AI 작업 명령을 주고받기 위한 API 규격을 정의한다.

AI는 Godot의 `.tscn` 파일을 직접 생성하거나 수정하지 않는다.

Godot은 현재 맵을 JSON으로 변환하여 FastAPI에 전달하고,
FastAPI는 제한된 Operation JSON을 반환한다.

Godot은 반환된 Operation을 검증한 뒤 실제 Scene에 적용한다.


## 2. Base URL

개발 환경:

```text
http://127.0.0.1:8000
```


## 3. Health Check

### Request

```http
GET /health
```

### Response

```json
{
  "status": "ok"
}
```


## 4. AI Map Edit

### Endpoint

```http
POST /api/map/edit
```

### Request

```json
{
  "request_id": "req_001",

  "prompt": "테이블 옆에 의자 하나 추가해줘",

  "map": {
    "schema_version": "1.0",
    "map_id": "test_map",

    "map_size": {
      "width": 1152,
      "height": 640
    },

    "grid_size": 32,

    "objects": [
      {
        "object_id": "obj_001",
        "asset_id": "table_001",
        "type": "table",

        "position": {
          "x": 368,
          "y": 160
        },

        "rotation": 0,
        "direction_index": 0,
        "locked": false,
        "flipped": false
      }
    ]
  }
}
```


## 5. Response

FastAPI는 `.tscn`을 반환하지 않고
Godot이 수행할 Operation 목록을 반환한다.

```json
{
  "request_id": "req_001",
  "status": "success",

  "operations": [
    {
      "action": "add",
      "object_id": "obj_002",
      "asset_id": "chair_001",

      "position": {
        "x": 480,
        "y": 160
      },

      "direction_index": 0
    }
  ]
}
```


## 6. Operation 종류

지원할 Operation은 다음과 같다.

### add

새 오브젝트를 추가한다.

```json
{
  "action": "add",
  "object_id": "obj_002",
  "asset_id": "chair_001",
  "position": {
    "x": 480,
    "y": 160
  },
  "direction_index": 0
}
```

### move

기존 오브젝트를 이동한다.

```json
{
  "action": "move",
  "object_id": "obj_001",
  "position": {
    "x": 512,
    "y": 256
  }
}
```

### rotate

기존 오브젝트의 방향을 변경한다.

```json
{
  "action": "rotate",
  "object_id": "obj_001",
  "direction_index": 1
}
```

### replace

기존 오브젝트의 Asset을 교체한다.

```json
{
  "action": "replace",
  "object_id": "obj_001",
  "asset_id": "table_002"
}
```

### delete

기존 오브젝트를 삭제한다.

```json
{
  "action": "delete",
  "object_id": "obj_001"
}
```

### duplicate

기존 오브젝트를 복제한다.

```json
{
  "action": "duplicate",
  "object_id": "obj_001",
  "new_object_id": "obj_003",

  "position": {
    "x": 512,
    "y": 160
  }
}
```

### lock

오브젝트의 잠금 상태를 변경한다.

```json
{
  "action": "lock",
  "object_id": "obj_001",
  "locked": true
}
```


## 7. 기본 규칙

- AI는 `.tscn` 텍스트를 직접 생성하거나 수정하지 않는다.
- AI는 등록된 `asset_id`만 사용한다.
- 모든 오브젝트는 고유한 `object_id`를 가져야 한다.
- 좌표는 Godot 2D 월드 좌표를 사용한다.
- 좌표 단위는 pixel이다.
- 기본 Grid Size는 32px이다.
- 방향은 `direction_index` 0~3을 사용한다.
- 잠긴 오브젝트는 AI가 수정하지 않는다.
- Godot은 Operation 적용 전에 유효성을 검사한다.
- 맵 경계 밖의 Operation은 거부한다.
- 다른 가구와 겹치는 Operation은 검증 단계에서 거부하거나 수정한다.


## 8. 처리 흐름

```text
Godot
↓
현재 Scene → Map JSON 직렬화
↓
POST /api/map/edit
↓
FastAPI
↓
LLM / LangGraph
↓
Operation JSON 생성
↓
Godot
↓
Operation 검증
↓
실제 Scene 수정
```