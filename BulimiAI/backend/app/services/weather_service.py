from datetime import datetime, timedelta

import httpx

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"


async def fetch_live_forecast(lat: float, lon: float) -> dict:
    """
    Fetches real, live weather data from Open-Meteo (https://open-meteo.com) —
    a free, no-API-key-required weather service. This is genuine live data,
    not simulated.
    """
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,relative_humidity_2m,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code",
        "timezone": "auto",
        "forecast_days": 5,
    }

    async with httpx.AsyncClient(timeout=10.0) as client:
        response = await client.get(OPEN_METEO_URL, params=params)
        response.raise_for_status()
        return response.json()


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
