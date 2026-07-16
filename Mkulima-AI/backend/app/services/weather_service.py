import asyncio
import time
from datetime import datetime, timedelta

import httpx

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"

# Simple in-memory cache: (rounded_lat, rounded_lon) -> (timestamp, response_json)
# Coordinates are rounded to ~1km precision so nearby requests (e.g. a farmer
# opening the app twice from roughly the same spot) hit the cache instead of
# Open-Meteo again. This also directly reduces how often we can trip the
# shared-IP rate limit described below.
_CACHE: dict[tuple[float, float], tuple[float, dict]] = {}
_CACHE_TTL_SECONDS = 600  # 10 minutes — weather doesn't change fast enough to need fresher data than this


async def fetch_live_forecast(lat: float, lon: float) -> dict:
    """
    Fetches real, live weather data from Open-Meteo (https://open-meteo.com) —
    a free, no-API-key-required weather service. This is genuine live data,
    not simulated.

    Includes a short-lived cache and automatic retry-with-backoff on 429s,
    since Open-Meteo enforces its rate limit per IP address — and on shared
    hosting platforms (like Render's free tier), other unrelated apps on the
    same outbound IP can exhaust that shared quota, causing 429s even on your
    very first request. This does not fully eliminate that risk (it's outside
    our control), but caching plus a couple of retries handles it in most cases.
    """
    cache_key = (round(lat, 2), round(lon, 2))
    now = time.time()

    cached = _CACHE.get(cache_key)
    if cached and (now - cached[0]) < _CACHE_TTL_SECONDS:
        return cached[1]

    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,relative_humidity_2m,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code",
        "timezone": "auto",
        "forecast_days": 5,
    }

    last_error = None
    async with httpx.AsyncClient(timeout=10.0) as client:
        for attempt in range(3):
            response = await client.get(OPEN_METEO_URL, params=params)

            if response.status_code == 429:
                last_error = httpx.HTTPStatusError(
                    "429 Too Many Requests", request=response.request, response=response
                )
                if attempt < 2:
                    await asyncio.sleep(1.5 * (attempt + 1))  # 1.5s, then 3s
                    continue
                raise last_error

            response.raise_for_status()
            data = response.json()
            _CACHE[cache_key] = (now, data)
            return data

    raise last_error


def weather_code_to_condition(code: int) -> str:
    """Maps Open-Meteo's WMO weather codes to short human-readable labels."""
    mapping = {
        0: "Clear sky",
        1: "Mainly clear",
        2: "Partly cloudy",
        3: "Overcast",
        45: "Fog",
        48: "Fog",
        51: "Light drizzle",
        53: "Drizzle",
        55: "Heavy drizzle",
        61: "Light rain",
        63: "Rain",
        65: "Heavy rain",
        71: "Light snow",
        80: "Rain showers",
        81: "Rain showers",
        82: "Violent rain showers",
        95: "Thunderstorm",
        96: "Thunderstorm with hail",
        99: "Thunderstorm with hail",
    }
    return mapping.get(code, "Variable conditions")


def determine_alert_level(daily: dict) -> str:
    """
    Simple rule-based alert logic: flags flood risk on very high rain
    probability, drought risk on a sustained run of near-zero rain chance.
    """
    rain_chances = daily.get("precipitation_probability_max", [])
    if not rain_chances:
        return "none"

    if any(chance >= 85 for chance in rain_chances[:2]):
        return "flood"
    if all(chance <= 10 for chance in rain_chances):
        return "drought"
    return "none"
