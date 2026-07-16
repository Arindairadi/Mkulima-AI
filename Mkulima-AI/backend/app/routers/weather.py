from fastapi import APIRouter, HTTPException, Query

from ..models.schemas import WeatherResponse, DailyForecastResponse
from ..services import weather_service, gemini_service

router = APIRouter(prefix="/api/v1/weather", tags=["weather"])


@router.get("", response_model=WeatherResponse)
async def get_weather(
    lat: float = Query(..., description="Latitude of the farm/village"),
    lon: float = Query(..., description="Longitude of the farm/village"),
    village_name: str = Query("Your area", description="Display name for the location"),
):
    try:
        data = await weather_service.fetch_live_forecast(lat, lon)
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Weather provider unavailable: {e}")

    current = data.get("current", {})
    daily = data.get("daily", {})

    alert_level = weather_service.determine_alert_level(daily)

    forecast = []
    dates = daily.get("time", [])
    highs = daily.get("temperature_2m_max", [])
    lows = daily.get("temperature_2m_min", [])
    rain_chances = daily.get("precipitation_probability_max", [])
    codes = daily.get("weather_code", [])

    for i in range(len(dates)):
        forecast.append(
            DailyForecastResponse(
                date=dates[i],
                temp_high_c=highs[i] if i < len(highs) else 0,
                temp_low_c=lows[i] if i < len(lows) else 0,
                rain_chance_percent=int(rain_chances[i]) if i < len(rain_chances) else 0,
                condition=weather_service.weather_code_to_condition(codes[i]) if i < len(codes) else "Unknown",
            )
        )

    # Build a short natural-language summary and ask Gemini for a farmer-facing tip.
    summary = (
        f"Current temp {current.get('temperature_2m')}°C, humidity "
        f"{current.get('relative_humidity_2m')}%, alert level: {alert_level}. "
        f"Next 2 days rain chance: {rain_chances[:2]}."
    )
    try:
        recommendation = gemini_service.generate_weather_recommendation(summary)
    except Exception:
        # Don't fail the whole weather request just because the AI tip failed —
        # fall back to a simple rule-based message so the farmer still gets
        # something useful.
        recommendation = (
            "Heavy rain expected soon — delay fertilizer application until the soil dries."
            if alert_level == "flood"
            else "Dry conditions expected — consider irrigating if soil moisture is low."
            if alert_level == "drought"
            else "No major weather risks in the next few days."
        )

    return WeatherResponse(
        village=village_name,
        current_temp_c=current.get("temperature_2m", 0),
        humidity_percent=int(current.get("relative_humidity_2m", 0)),
        wind_kph=current.get("wind_speed_10m", 0),
        alert_level=alert_level,
        ai_recommendation=recommendation,
        forecast=forecast,
    )
