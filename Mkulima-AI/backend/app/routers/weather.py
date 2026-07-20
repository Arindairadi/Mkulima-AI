from fastapi import APIRouter, HTTPException, Query

from ..models.schemas import WeatherResponse, DailyForecastResponse
from ..services import weather_service, gemini_service

router = APIRouter(prefix="/api/v1/weather", tags=["weather"])


@router.get("", response_model=WeatherResponse)
async def get_weather(
    lat: float = Query(..., description="Latitude of the farm/village"),
    lon: float = Query(..., description="Longitude of the farm/village"),
    village_name: str = Query("Your area", description="Fallback display name if geocoding is unavailable"),
):
    try:
        data = await weather_service.fetch_live_forecast(lat, lon)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Weather provider unavailable: {e}")

    location = data.get("location", {})
    geocoded = await weather_service.reverse_geocode(lat, lon)

    resolved_village = geocoded.get("village") or location.get("name") or village_name
    resolved_district = geocoded.get("district") or location.get("region")
    resolved_subcounty = geocoded.get("subcounty")

    current = data.get("current", {})
    forecast_days = data.get("forecast", {}).get("forecastday", [])

    alert_level = weather_service.determine_alert_level(forecast_days)

    forecast = []
    for day_entry in forecast_days:
        day = day_entry.get("day", {})
        forecast.append(
            DailyForecastResponse(
                date=day_entry.get("date", ""),
                temp_high_c=day.get("maxtemp_c", 0),
                temp_low_c=day.get("mintemp_c", 0),
                rain_chance_percent=int(day.get("daily_chance_of_rain", 0)),
                condition=day.get("condition", {}).get("text", "Unknown"),
            )
        )

    today_condition = forecast[0].condition if forecast else "Unknown"
    rain_chances = [d.get("day", {}).get("daily_chance_of_rain", 0) for d in forecast_days[:2]]
    summary = (
        f"Current: {current.get('temp_c')}°C, {current.get('humidity')}% humidity, "
        f"condition '{today_condition}'. Alert level: {alert_level}. "
        f"Rain chance next 2 days: {rain_chances}."
    )
    try:
        recommendation = gemini_service.generate_weather_recommendation(summary)
    except Exception as e:
        print(f"WARNING: Gemini weather recommendation failed, using fallback: {e}")
        recommendation = _rule_based_fallback(alert_level, today_condition, current.get("temp_c", 25))

    return WeatherResponse(
        village=resolved_village,
        subcounty=resolved_subcounty,
        district=resolved_district,
        region=location.get("region"),
        current_temp_c=current.get("temp_c", 0),
        humidity_percent=int(current.get("humidity", 0)),
        wind_kph=current.get("wind_kph", 0),
        alert_level=alert_level,
        ai_recommendation=recommendation,
        forecast_days_available=len(forecast),
        forecast=forecast,
    )


def _rule_based_fallback(alert_level: str, condition: str, temp_c: float) -> str:
    condition_lower = condition.lower()

    if alert_level == "flood":
        return "Heavy rain expected soon — delay fertilizer application until the soil dries, and check drainage channels are clear."
    if alert_level == "drought":
        return "Dry conditions expected over the next few days — prioritize irrigation for young or shallow-rooted crops."
    if "rain" in condition_lower or "storm" in condition_lower or "drizzle" in condition_lower:
        return "Rain is likely today — a good day to skip irrigation, but avoid walking heavy equipment on wet soil to prevent compaction."
    if "sunny" in condition_lower or "clear" in condition_lower:
        if temp_c and temp_c >= 30:
            return "Hot, sunny conditions expected — water in the early morning or evening to reduce evaporation loss."
        return "Clear, dry conditions today — a good window for spraying or harvesting without rain interference."
    if "cloud" in condition_lower or "overcast" in condition_lower:
        return "Overcast conditions today — moderate evaporation, so check soil moisture before deciding whether to irrigate."
    return "No major weather risks in the next few days — continue normal farm activities."
