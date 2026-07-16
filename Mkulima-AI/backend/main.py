from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import disease, voice, weather, market

settings = get_settings()

app = FastAPI(
    title="Mkulima AI Backend",
    description="Backend API for Mkulima AI — AI-powered smart farming platform.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(disease.router)
app.include_router(voice.router)
app.include_router(weather.router)
app.include_router(market.router)


@app.get("/")
async def root():
    return {"status": "ok", "service": "Mkulima AI backend", "environment": settings.environment}


@app.get("/health")
async def health():
    return {"status": "healthy", "gemini_configured": bool(settings.gemini_api_key)}
