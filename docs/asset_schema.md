# Asset Metadata Schema

## 목적

Godot AI Map Builder에서 사용되는 실제 Godot 에셋을 일관된 형식으로 관리하기 위한 메타데이터 규격이다.

에셋 메타데이터는 다음 목적으로 사용한다.

- Godot에서 실제 PackedScene을 찾는다.
- FastAPI와 AI가 에셋의 종류와 특징을 이해한다.
- 자연어 요청에 적합한 에셋을 검색한다.
- 에셋 RAG 검색에 활용한다.
- 배치 시 크기와 기준점을 확인한다.
- 충돌 및 맵 품질 검사에 활용한다.
- 에셋의 라이선스와 출처를 관리한다.

AI는 실제 `.tscn` 경로를 임의로 생성하지 않는다.

AI 또는 백엔드는 `asset_id`를 사용하고,
Godot 플러그인이 `asset_id`에 연결된 실제 PackedScene을 찾아 사용한다.

## 기본 원칙

- 모든 에셋은 고유한 `asset_id`를 가진다.
- 에셋 종류는 `type`으로 구분한다.
- 실제 Godot PackedScene 경로는 `scene_path`로 관리한다.
- 자연어 검색을 위해 `tags`를 저장한다.
- 기본 크기와 배치 기준점을 저장한다.
- 충돌 검사에 사용할 크기를 별도로 저장할 수 있다.
- 에셋의 라이선스와 출처를 기록한다.

## Asset 구조

```json
{
  "asset_id": "chair_wood_001",
  "name": "Wood Chair",
  "type": "chair",
  "scene_path": "res://assets/furniture/chair_wood_001.tscn",
  "tags": [
    "wood",
    "small",
    "kitchen",
    "dining"
  ],
  "size": {
    "width": 32,
    "height": 32
  },
  "origin": {
    "x": 16,
    "y": 16
  },
  "default_rotation": 0,
  "collision_size": {
    "width": 28,
    "height": 28
  },
  "license": {
    "name": "CC0",
    "source": "example_asset_pack"
  }
}
```

## Asset 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| asset_id | string | O | 실제 에셋을 식별하는 고유 ID |
| name | string | O | 사람이 확인하기 위한 에셋 이름 |
| type | string | O | chair, table, cabinet 등의 에셋 종류 |
| scene_path | string | O | 실제 Godot PackedScene의 경로 |
| tags | array | O | 검색 및 RAG에 사용할 에셋 특징 |
| size | object | O | 에셋의 기본 크기 |
| origin | object | O | 에셋 배치 기준점 |
| default_rotation | number | O | 에셋의 기본 회전 방향 |
| collision_size | object | O | 충돌 검사에 사용할 영역 크기 |
| license | object | O | 라이선스 및 원본 출처 정보 |

## asset_id 규칙

`asset_id`는 에셋 하나를 식별하기 위한 고유 ID이다.

예:

```text
chair_wood_001
chair_modern_001
table_wood_001
cabinet_kitchen_001
sink_modern_001
```

같은 에셋을 맵에 여러 번 배치하더라도 `asset_id`는 동일하다.

예:

```text
첫 번째 의자
object_id = obj_001
asset_id = chair_wood_001

두 번째 의자
object_id = obj_002
asset_id = chair_wood_001
```

`object_id`는 맵에 배치된 개별 오브젝트를 나타내고,
`asset_id`는 해당 오브젝트가 사용하는 원본 에셋을 나타낸다.

## type 규칙

`type`은 에셋의 기본 종류를 나타낸다.

예:

```text
table
chair
cabinet
shelf
sink
refrigerator
bed
sofa
door
box
```

이 값은 에셋 검색 및 AI 요청 분석에 사용한다.

예를 들어 사용자가 "의자를 추가해줘"라고 요청하면
`type`이 `chair`인 에셋을 우선 검색할 수 있다.

## scene_path 규칙

`scene_path`는 실제 Godot PackedScene 파일의 위치이다.

예:

```text
res://assets/furniture/chair_wood_001.tscn
```

백엔드나 AI가 해당 경로를 직접 생성하지 않는다.

백엔드가 다음과 같이 `asset_id`를 선택하면:

```json
{
  "asset_id": "chair_wood_001"
}
```

Godot의 Asset Registry가 다음처럼 실제 경로를 찾는다.

```text
chair_wood_001
→ res://assets/furniture/chair_wood_001.tscn
```

그 후 Godot이 해당 PackedScene을 실제 씬에 인스턴스화한다.

## tags 규칙

`tags`는 에셋의 특징을 표현하는 키워드 목록이다.

예:

```json
{
  "tags": [
    "wood",
    "small",
    "kitchen",
    "dining"
  ]
}
```

나중에 사용자가 다음과 같이 요청할 수 있다.

```text
작은 나무 의자를 배치해줘.
```

이 경우 검색 시스템은 다음 특징을 사용할 수 있다.

```text
type = chair
tags = wood, small
```

이 정보는 추후 SQL 검색과 pgvector 기반 에셋 RAG에서 활용한다.

## size 규칙

`size`는 에셋의 기본 공간 크기이다.

예:

```json
{
  "size": {
    "width": 96,
    "height": 64
  }
}
```

예를 들어 `grid_size`가 32라면:

```text
width 96 = 가로 3칸
height 64 = 세로 2칸
```

정도의 공간을 차지한다.

이 값은 배치 가능 공간 확인 및 맵 경계 검사 등에 사용할 수 있다.

## origin 규칙

`origin`은 에셋을 배치할 때 사용하는 기준점이다.

예:

```json
{
  "origin": {
    "x": 16,
    "y": 16
  }
}
```

에셋마다 기준점이 다르면 동일한 좌표에 배치해도 실제 위치가 달라질 수 있기 때문에
에셋별 기준점을 관리한다.

기본적으로 가능한 한 에셋 중심점을 기준으로 통일한다.

## default_rotation 규칙

`default_rotation`은 에셋의 기본 방향이다.

예:

```json
{
  "default_rotation": 0
}
```

회전 값은 Map JSON과 동일하게 degree 단위를 사용한다.

기본 회전 값:

- 0
- 90
- 180
- 270

## collision_size 규칙

`collision_size`는 실제 충돌 검사에서 사용할 크기이다.

예:

```json
{
  "collision_size": {
    "width": 28,
    "height": 28
  }
}
```

이미지 전체 크기와 실제 가구가 차지하는 공간은 다를 수 있다.

예:

```text
이미지 크기 = 32 x 32
실제 충돌 영역 = 28 x 28
```

따라서 에셋 이미지 자체의 크기와 충돌 검사 크기를 별도로 관리한다.

이 값은 추후 다음 검증에 활용한다.

- 다른 가구와 겹치는지 검사
- 맵 경계를 벗어나는지 검사
- 문 앞을 막는지 검사
- 이동 통로를 막는지 검사

## license 규칙

모든 외부 에셋은 라이선스 및 출처를 기록한다.

예:

```json
{
  "license": {
    "name": "CC0",
    "source": "example_asset_pack"
  }
}
```

실제 에셋을 등록할 때는 해당 에셋의 정확한 라이선스와 출처를 입력한다.

## 전체 예제

```json
{
  "asset_id": "table_wood_001",
  "name": "Wood Dining Table",
  "type": "table",
  "scene_path": "res://assets/furniture/table_wood_001.tscn",
  "tags": [
    "wood",
    "medium",
    "kitchen",
    "dining"
  ],
  "size": {
    "width": 96,
    "height": 64
  },
  "origin": {
    "x": 48,
    "y": 32
  },
  "default_rotation": 0,
  "collision_size": {
    "width": 88,
    "height": 56
  },
  "license": {
    "name": "CC0",
    "source": "example_asset_pack"
  }
}
```