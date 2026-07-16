from fastapi import APIRouter, UploadFile, File, Form, HTTPException

from ..models.schemas import DiseaseResultResponse
from ..services import gemini_service

router = APIRouter(prefix="/api/v1/disease-detection", tags=["disease-detection"])

SUPPORTED_CROPS = {"Maize", "Beans", "Coffee", "Bananas", "Cassava", "Tomatoes"}


@router.post("/analyze", response_model=DiseaseResultResponse)
async def analyze_disease(
    crop_name: str = Form(...),
    image: UploadFile = File(...),
):
    if crop_name not in SUPPORTED_CROPS:
        raise HTTPException(status_code=400, detail=f"Unsupported crop: {crop_name}")

    if image.content_type not in {"image/jpeg", "image/png", "image/webp"}:
        raise HTTPException(status_code=400, detail="Image must be JPEG, PNG, or WEBP")

    image_bytes = await image.read()
    if len(image_bytes) > 8 * 1024 * 1024:
        raise HTTPException(status_code=400, detail="Image too large (max 8MB)")

    try:
        result = gemini_service.analyze_crop_image(
            image_bytes=image_bytes,
            mime_type=image.content_type,
            crop_name=crop_name,
        )
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI analysis failed: {e}")

    return DiseaseResultResponse(
        crop_name=result.get("crop_name", crop_name),
        disease_name=result.get("disease_name", "Unknown"),
        confidence=float(result.get("confidence", 0.5)),
        cause=result.get("cause", ""),
        treatments=result.get("treatments", []),
        prevention_tips=result.get("prevention_tips", []),
        is_healthy=bool(result.get("is_healthy", False)),
    )
