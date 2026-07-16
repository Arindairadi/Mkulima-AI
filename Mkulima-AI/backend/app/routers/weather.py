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
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"Weather provider unavailable: {e}")

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

    rain_chances = [d.get("day", {}).get("daily_chance_of_rain", 0) for d in forecast_days[:2]]
    summary = (
        f"Current temp {current.get('temp_c')}°C, humidity {current.get('humidity')}%, "
        f"alert level: {alert_level}. Next 2 days rain chance: {rain_chances}."
    )
    try:
        recommendation = gemini_service.generate_weather_recommendation(summary)
    except Exception:
        recommendation = (
            "Heavy rain expected soon — delay fertilizer application until the soil dries."
            if alert_level == "flood"
            else "Dry conditions expected — consider irrigating if soil moisture is low."
            if alert_level == "drought"
            else "No major weather risks in the next few days."
        )

    return WeatherResponse(
        village=village_name,
        current_temp_c=current.get("temp_c", 0),
        humidity_percent=int(current.get("humidity", 0)),
        wind_kph=current.get("wind_kph", 0),
        alert_level=alert_level,
        ai_recommendation=recommendation,
        forecast=forecast,
    )
