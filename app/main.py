from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import fighters

app = FastAPI(
    title="UFC Stats API",
    version="0.1.0",
    description="Read-only API over UFC stats stored in Supabase.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["GET"],
    allow_headers=["*"],
)

app.include_router(fighters.router)


@app.get("/health", tags=["meta"])
def health():
    return {"status": "ok"}
