from fastapi import APIRouter, HTTPException

from ..models.schemas import VoiceAskRequest, VoiceAskResponse
from ..services import gemini_service

router = APIRouter(prefix="/api/v1/voice-assistant", tags=["voice-assistant"])

_LANGUAGE_LABELS = {
    "en-UG": "English",
    "lg-UG": "Luganda",
    "nyn-UG": "Runyankole",
    "xog-UG": "Lusoga",
    "luo-UG": "Luo",
    "teo-UG": "Ateso",
}


@router.post("/ask", response_model=VoiceAskResponse)
async def ask(request: VoiceAskRequest):
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="text must not be empty")

    language_label = _LANGUAGE_LABELS.get(request.language_code, "English")

    try:
        reply = gemini_service.ask_voice_assistant(request.text, language_label)
    except RuntimeError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=502, detail=f"AI response failed: {e}")

    return VoiceAskResponse(reply=reply)
