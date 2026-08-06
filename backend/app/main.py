from fastapi import FastAPI

app = FastAPI(
    title="Godot AI Map Builder API",
    version="0.1.0",
)


@app.get("/health")
def health_check() -> dict[str, str]:
    return {
        "status": "ok",
        "service": "godot-ai-map-builder-api",
    }