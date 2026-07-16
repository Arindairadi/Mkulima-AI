import time

import httpx

from ..config import get_settings

settings = get_settings()

WEATHERAPI_URL = "https://api.weatherapi.com/v1/forecast.json"

# Simple in-memory cache: (rounded_lat, rounded_lon) -> (timestamp, response_json)
_CACHE: dict[tuple[float, float], tuple[float, dict]] = {}
_CACHE_TTL_SECONDS = 600  # 10 minutes


async def fetch_live_forecast(lat: float, lon: float) -> dict:
    """
    Fetches real, live weather data from WeatherAPI.com.

    Uses key-based authentication (WEATHERAPI_KEY) rather than Open-Meteo's
    keyless, IP-rate-limited free API. This matters specifically because
    on shared hosting platforms like Render's free tier, many unrelated
    apps share the same outbound IP address — with a keyless, per-IP-limited
    API, one of those other apps exhausting the shared quota causes 429s
    for everyone on that IP, including on a service's very first request.
    Key-based auth ties the quota to this specific account instead.
    """
    if not settings.weatherapi_key:
        raise RuntimeError("WEATHERAPI_KEY is not configured on the server.")

    cache_key = (round(lat, 2), round(lon, 2))
    now = time.time()

    cached = _CACHE.get(cache_key)
    if cached and (now - cached[0]) < _CACHE_TTL_SECONDS:
        return cached[1]

    params = {
        "key": settings.weatherapi_key,
        "q": f"{lat},{lon}",
        "days": 5,
        "aqi": "no",
        "alerts": "no",
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(WEATHERAPI_URL, params=params)
        response.raise_for_status()
        data = response.json()
        _CACHE[cache_key] = (now, data)
        return data


def determine_alert_level(forecast_days: list[dict]) -> str:
    """
    Simple rule-based alert logic using WeatherAPI's daily_chance_of_rain
    field: flags flood risk on very high rain probability in the next 2
    days, drought risk on a sustained run of near-zero rain chance.
    """
    rain_chances = [day.get("day", {}).get("daily_chance_of_rain", 0) for day in forecast_days]
    if not rain_chances:
        return "none"

    if any(chance >= 85 for chance in rain_chances[:2]):
        return "flood"
    if all(chance <= 10 for chance in rain_chances):
        return "drought"
    return "none"
