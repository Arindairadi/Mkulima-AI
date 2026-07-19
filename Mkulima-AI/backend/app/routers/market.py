import math
import random

from fastapi import APIRouter, Query

from ..models.schemas import MarketPriceResponse

router = APIRouter(prefix="/api/v1/market", tags=["market"])

# NOTE: Crop PRICES below are simulated — no free, reliable live public API
# exists for Ugandan crop market prices at the time this was built (see
# README for how to swap in a real source later). The market LOCATIONS and
# DISTANCE CALCULATION, however, are real: each market has real-world
# coordinates, and if the farmer's device location is passed in, distance
# to each market is computed with the haversine formula — genuinely useful
# for "which market should I actually travel to" even while prices remain
# a placeholder.
_MARKETS = {
    "Kampala": {"lat": 0.3476, "lon": 32.5825},
    "Kiryandongo (local)": {"lat": 1.6667, "lon": 32.0},
    "Mbarara": {"lat": -0.6072, "lon": 30.6545},
}

_CROPS = ["Beans", "Maize", "Coffee", "Bananas (bunch)", "Cassava", "Tomatoes"]
_BASE_PRICES = {
    "Beans": 3800.0,
    "Maize": 1500.0,
    "Coffee": 9200.0,
    "Bananas (bunch)": 25000.0,
    "Cassava": 900.0,
    "Tomatoes": 2200.0,
}


def _haversine_km(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Great-circle distance between two lat/lon points, in kilometers."""
    r = 6371.0  # Earth's radius in km
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


@router.get("/prices", response_model=list[MarketPriceResponse])
async def get_prices(
    lat: float | None = Query(None, description="Farmer's device latitude, for real distance-to-market"),
    lon: float | None = Query(None, description="Farmer's device longitude, for real distance-to-market"),
):
    rnd = random.Random()

    # Real distance calculation if the farmer's location was provided.
    distances: dict[str, float] = {}
    nearest_market: str | None = None
    if lat is not None and lon is not None:
        for market_name, coords in _MARKETS.items():
            distances[market_name] = round(_haversine_km(lat, lon, coords["lat"], coords["lon"]), 1)
        nearest_market = min(distances, key=distances.get)

    result = []
    for crop in _CROPS:
        base = _BASE_PRICES[crop]
        for market_name in _MARKETS:
            variance = (rnd.random() - 0.4) * 0.25
            price = base * (1 + variance)
            change = (rnd.random() - 0.5) * 20
            result.append(
                MarketPriceResponse(
                    crop_name=crop,
                    market_name=market_name,
                    price_per_kg_ugx=round(price, 2),
                    change_percent=round(change, 2),
                    trend_7_day=[round(price * (1 + (rnd.random() - 0.5) * 0.1), 2) for _ in range(7)],
                    distance_km=distances.get(market_name),
                    is_nearest=(market_name == nearest_market),
                )
            )
    return result
