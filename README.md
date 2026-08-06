# Godot AI Map Builder

AI를 이용해 Godot 2D 맵을 생성하고 편집하는 Godot EditorPlugin 프로젝트입니다.

## 프로젝트 목표

Godot 에디터 안에서 Placeholder 또는 실제 에셋을 대략 배치한 뒤,
자연어 명령을 통해 맵을 생성하거나 수정할 수 있도록 합니다.

예시:

- 이 공간을 작은 부엌으로 만들어줘
- 선택한 영역을 창고처럼 구성해줘
- 테이블을 오른쪽 벽으로 이동해줘
- 이 가구들을 실제 에셋으로 교체해줘

## 핵심 구조

- Godot EditorPlugin
- Python FastAPI 백엔드
- LLM Structured Output
- LangGraph 워크플로
- PostgreSQL 및 pgvector
- 에셋 RAG와 스타일 RAG
- 이미지와 맵 JSON을 이용한 멀티모달 편집
- 규칙 기반 배치 검증 및 자동 보정

## AI 작업 방식

AI는 Godot `.tscn` 파일을 직접 생성하지 않습니다.

AI는 다음과 같은 제한된 작업 명령을 JSON으로 반환합니다.

- add
- move
- rotate
- replace
- delete
- duplicate
- lock

Godot 플러그인이 명령을 검증한 뒤 실제 PackedScene을 씬에 적용합니다.

## 폴더 구조

- `godot`: Godot 프로젝트와 EditorPlugin
- `backend`: FastAPI와 AI 처리 서버
- `docs`: 요구사항 및 설계 문서
- `data`: 샘플 맵과 에셋 메타데이터
- `scripts`: 데이터 처리 및 초기화 스크립트
- `tests`: 통합 테스트