# Asset Standard

## 1. Grid Standard

Godot AI Map Builder에서 사용하는 기본 그리드 단위는 다음과 같다.

- Grid Size: 32 x 32 px
- 모든 배치 가능 오브젝트는 32px 그리드를 기준으로 배치한다.
- 오브젝트의 논리적 점유 크기는 32px의 배수로 정의한다.
- 실제 Sprite 이미지 크기와 논리적 점유 크기는 서로 다를 수 있다.

### 현재 기본 가구 점유 크기

| Type | Size | Grid Cells |
|---|---:|---:|
| Table | 96 x 64 | 3 x 2 |
| Chair | 32 x 32 | 1 x 1 |
| Cabinet | 64 x 32 | 2 x 1 |
| Bed | 64 x 96 | 2 x 3 |
| Sofa | 96 x 32 | 3 x 1 |
| Shelf | 96 x 32 | 3 x 1 |
| Refrigerator | 32 x 64 | 1 x 2 |

## 2. Origin Standard

- 모든 배치 가능 오브젝트의 루트 Node2D 원점은 논리적 점유 영역의 중심으로 사용한다.
- CollisionShape2D는 루트 Node2D의 원점과 동일한 중심을 사용한다.
- 실제 Sprite2D 이미지는 시각적 정렬을 위해 Position Offset을 사용할 수 있다.
- Sprite2D의 Offset 조정은 논리적 배치 좌표나 충돌 영역에 영향을 주지 않는다.
- 에셋 배치 좌표는 항상 루트 Node2D의 위치를 기준으로 저장한다.