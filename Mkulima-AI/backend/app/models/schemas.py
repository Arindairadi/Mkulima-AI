from pydantic import BaseModel, Field
from typing import Optional


# ---- Disease detection ----

class DiseaseResultResponse(BaseModel):
    crop_name: str
    disease_name: str
    confidence: float = Field(ge=0, le=1)
    cause: str
    treatments: list[str]
    prevention_tips: list[str]
    is_healthy: bool = False


# ---- Voice assistant ----

class VoiceAskRequest(BaseModel):
    text: str
    language_code: str = "en-UG"  # matches AppConstants.supportedLanguages in the Flutter app


class VoiceAskResponse(BaseModel):
    reply: str


# ---- Weather ----

class DailyForecastResponse(BaseModel):
    date: str  # ISO date
    temp_high_c: float
    temp_low_c: float
    rain_chance_percent: int
    condition: str


class WeatherResponse(BaseModel):
    village: str
    current_temp_c: float
    humidity_percent: int
    wind_kph: float
    alert_level: str  # "none" | "drought" | "flood"
    ai_recommendation: str
    forecast: list[DailyForecastResponse]


# ---- Market (simulated — see README for why) ----

class MarketPriceResponse(BaseModel):
    crop_name: str
    market_name: str
    price_per_kg_ugx: float
    change_percent: float
    trend_7_day: list[float]
