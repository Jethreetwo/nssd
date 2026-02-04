from __future__ import annotations

from fastapi import FastAPI

from .api import router

app = FastAPI(title="Stack Server")
app.include_router(router)


@app.get("/")
def root() -> dict:
    return {"service": "stack", "status": "ok"}
