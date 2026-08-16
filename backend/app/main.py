from fastapi import FastAPI

from app.schemas.map_edit import (
    MapEditRequest,
    MapEditResponse,
)
from app.services.llm_service import generate_operations


app = FastAPI()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post(
    "/api/map/edit",
    response_model=MapEditResponse,
)
def edit_map(data: MapEditRequest):
    llm_result = generate_operations(
        prompt=data.prompt,
        map_data=data.map,
        available_assets=data.available_assets,
    )

    return {
        "request_id": data.request_id,
        "status": "success",
        "operations": llm_result.operations,
    }