import random

from fastapi import APIRouter

from ..models.schemas import MarketPriceResponse

router = APIRouter(prefix="/api/v1/market", tags=["market"])

# NOTE: There is no reliable free, live public API for Ugandan crop market
# prices at the time this was built. This endpoint returns realistic
# simulated data so the app's architecture is ready to plug in a real
# source later — e.g. a partnership with Uganda's Ministry of Agriculture,
# UBOS, FEWS NET, or a crowd-sourced buyer/seller price-reporting feature
# built into the app itself (farmers submit prices they see locally).
# When such a source exists, replace the body of get_prices() below —
# the response shape (MarketPriceResponse) should not need to change.

_CROPS = ["Beans", "Maize", "Coffee", "Bananas (bunch)", "Cassava", "Tomatoes"]
_MARKETS = ["Kampala", "Kiryandongo (local)", "Mbarara"]
_BASE_PRICES = {
    "Beans": 3800.0,
    "Maize": 1500.0,
    "Coffee": 9200.0,
    "Bananas (bunch)": 25000.0,
    "Cassava": 900.0,
    "Tomatoes": 2200.0,
}


@router.get("/prices", response_model=list[MarketPriceResponse])
async def get_prices():
    rnd = random.Random()  # fresh randomness each call, unlike a fixed seed
    result = []
    for crop in _CROPS:
        base = _BASE_PRICES[crop]
        for market in _MARKETS:
            variance = (rnd.random() - 0.4) * 0.25
            price = base * (1 + variance)
            change = (rnd.random() - 0.5) * 20
            result.append(
                MarketPriceResponse(
                    crop_name=crop,
                    market_name=market,
                    price_per_kg_ugx=round(price, 2),
                    change_percent=round(change, 2),
                    trend_7_day=[round(price * (1 + (rnd.random() - 0.5) * 0.1), 2) for _ in range(7)],
                )
            )
    return result
