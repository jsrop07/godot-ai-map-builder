from typing import Any, Literal, Union

from pydantic import BaseModel, Field

class MapEditRequest(BaseModel):
    request_id: str = Field(default="")
    prompt: str = Field(min_length=1)
    map: dict[str, Any]
    available_assets: list[dict[str, Any]] = []

class Position(BaseModel):
    x: float
    y: float


class AddOperation(BaseModel):
    action: Literal["add"]
    object_id: str
    asset_id: str
    position: Position
    direction_index: int = 0


class MoveOperation(BaseModel):
    action: Literal["move"]
    object_id: str
    position: Position


class RotateOperation(BaseModel):
    action: Literal["rotate"]
    object_id: str
    direction_index: int


class ReplaceOperation(BaseModel):
    action: Literal["replace"]
    object_id: str
    asset_id: str


class DeleteOperation(BaseModel):
    action: Literal["delete"]
    object_id: str


MapOperation = Union[
    AddOperation,
    MoveOperation,
    RotateOperation,
    ReplaceOperation,
    DeleteOperation,
]


class LLMOperationResponse(BaseModel):
    operations: list[MapOperation]


class MapEditResponse(BaseModel):
    request_id: str
    status: Literal["success", "error"]
    operations: list[MapOperation]