import time

import httpx

from ..config import get_settings

settings = get_settings()

WEATHERAPI_URL = "https://api.weatherapi.com/v1/forecast.json"
NOMINATIM_URL = "https://nominatim.openstreetmap.org/reverse"

# Simple in-memory cache: (rounded_lat, rounded_lon) -> (timestamp, response_json)
_WEATHER_CACHE: dict[tuple[float, float], tuple[float, dict]] = {}
_GEOCODE_CACHE: dict[tuple[float, float], tuple[float, dict]] = {}
_CACHE_TTL_SECONDS = 600  # 10 minutes

# Free-tier cap: WeatherAPI.com's free plan only returns up to 3 forecast
# days regardless of what's requested — requesting more doesn't error, it
# just silently truncates. Requesting exactly 3 makes that explicit rather
# than quietly asking for 5 and getting back fewer.
FREE_TIER_MAX_FORECAST_DAYS = 3


async def fetch_live_forecast(lat: float, lon: float) -> dict:
    """
    Fetches real, live weather data from WeatherAPI.com.

    Uses key-based authentication (WEATHERAPI_KEY) rather than Open-Meteo's
    keyless, IP-rate-limited free API — ties the quota to this account
    instead of a shared outbound IP (see README for the incident that
    motivated this).
    """
    if not settings.weatherapi_key:
        raise RuntimeError("WEATHERAPI_KEY is not configured on the server.")

    cache_key = (round(lat, 2), round(lon, 2))
    now = time.time()

    cached = _WEATHER_CACHE.get(cache_key)
    if cached and (now - cached[0]) < _CACHE_TTL_SECONDS:
        return cached[1]

    params = {
        "key": settings.weatherapi_key,
        "q": f"{lat},{lon}",
        "days": FREE_TIER_MAX_FORECAST_DAYS,
        "aqi": "no",
        "alerts": "no",
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(WEATHERAPI_URL, params=params)
        response.raise_for_status()
        data = response.json()
        _WEATHER_CACHE[cache_key] = (now, data)
        return data


async def reverse_geocode(lat: float, lon: float) -> dict:
    """
    Real reverse geocoding via OpenStreetMap's free Nominatim service —
    genuinely resolves coordinates to Uganda's local administrative names
    (village/town, county/subcounty, state_district) where OpenStreetMap's
    community-contributed map data covers that area. Coverage varies by
    region — dense in cities, patchier in some rural areas — so callers
    should treat any of these fields as "may be missing" and fall back to
    WeatherAPI's own city-level location name.

    Free, no API key, but requires a descriptive User-Agent per Nominatim's
    usage policy, and is rate-limited to ~1 request/second — fine for our
    per-user-action call pattern, and results are cached for 10 minutes.
    """
    cache_key = (round(lat, 4), round(lon, 4))
    now = time.time()

    cached = _GEOCODE_CACHE.get(cache_key)
    if cached and (now - cached[0]) < _CACHE_TTL_SECONDS:
        return cached[1]

    params = {
        "format": "jsonv2",
        "lat": lat,
        "lon": lon,
        "zoom": 14,  # roughly village/suburb level of detail
        "addressdetails": 1,
    }
    headers = {"User-Agent": "MkulimaAI-FarmingApp/1.0 (contact: app-support@example.com)"}

    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            response = await client.get(NOMINATIM_URL, params=params, headers=headers)
            response.raise_for_status()
            data = response.json()
            address = data.get("address", {})
            result = {
                "village": address.get("village") or address.get("town") or address.get("hamlet"),
                "subcounty": address.get("county") or address.get("municipality"),
                "district": address.get("state_district") or address.get("state"),
            }
            _GEOCODE_CACHE[cache_key] = (now, result)
            return result
    except Exception:
        return {"village": None, "subcounty": None, "district": None}


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
