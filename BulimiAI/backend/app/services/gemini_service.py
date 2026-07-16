import json
import re

from google import genai
from google.genai import types

from ..config import get_settings

settings = get_settings()

_client: genai.Client | None = None


def _get_client() -> genai.Client:
    global _client
    if _client is None:
        if not settings.gemini_api_key:
            raise RuntimeError(
                "GEMINI_API_KEY is not configured on the server. "
                "Set it as an environment variable before starting the API."
            )
        _client = genai.Client(api_key=settings.gemini_api_key)
    return _client


DISEASE_SYSTEM_PROMPT = """You are an expert agricultural plant pathologist helping smallholder \
farmers in Uganda diagnose crop diseases from a photo.

You will be given a photo of a {crop} plant/leaf. Respond with ONLY a JSON object \
(no markdown fences, no extra prose) matching exactly this shape:

{{
  "disease_name": string,
  "confidence": number between 0 and 1,
  "cause": string (1-2 sentences, plain language),
  "treatments": array of short actionable strings (empty array if healthy),
  "prevention_tips": array of short actionable strings,
  "is_healthy": boolean
}}

If the plant looks healthy, set is_healthy to true, disease_name to "Healthy", and \
treatments to an empty array. Keep all text concise and in plain, non-technical \
language suitable for a farmer with limited formal education. Do not include any \
text outside the JSON object."""


VOICE_SYSTEM_PROMPT = """You are Mkulima AI's farming assistant, \
helping smallholder farmers in Uganda with practical agricultural advice.

The farmer's preferred language is: {language}. Reply in that language where \
possible (English, Luganda, Runyankole, Lusoga, Luo, or Ateso); if you are not \
confident producing fluent text in that language, reply in clear, simple English \
instead rather than guessing.

Keep answers short (2-4 sentences), practical, and specific to smallholder farming \
in East Africa. Avoid jargon. If the question is about a medical/human-health \
emergency or is unrelated to farming, gently redirect the farmer to appropriate \
help instead of guessing."""


def _extract_json(text: str) -> dict:
    """Gemini sometimes wraps JSON in markdown fences despite instructions not to."""
    cleaned = text.strip()
    cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    return json.loads(cleaned)


def analyze_crop_image(image_bytes: bytes, mime_type: str, crop_name: str) -> dict:
    """Sends a crop photo to Gemini and returns a structured diagnosis dict."""
    client = _get_client()
    prompt = DISEASE_SYSTEM_PROMPT.format(crop=crop_name)

    response = client.models.generate_content(
        model=settings.gemini_model,
        contents=[
            prompt,
            types.Part.from_bytes(data=image_bytes, mime_type=mime_type),
        ],
        config=types.GenerateContentConfig(
            temperature=0.2,  # low temperature: we want consistent, careful diagnoses
            max_output_tokens=500,
        ),
    )

    result = _extract_json(response.text)
    result.setdefault("crop_name", crop_name)
    return result


def ask_voice_assistant(text: str, language_label: str) -> str:
    """Sends a farmer's question to Gemini and returns a plain-text reply."""
    client = _get_client()
    system_instruction = VOICE_SYSTEM_PROMPT.format(language=language_label)

    response = client.models.generate_content(
        model=settings.gemini_model,
        contents=text,
        config=types.GenerateContentConfig(
            system_instruction=system_instruction,
            temperature=0.4,
            max_output_tokens=300,
        ),
    )
    return response.text.strip()


def generate_weather_recommendation(weather_summary: str) -> str:
    """Turns a raw weather summary into a short farmer-facing recommendation."""
    client = _get_client()
    response = client.models.generate_content(
        model=settings.gemini_model,
        contents=(
            "Given this weather forecast for a smallholder farm in Uganda, write ONE short "
            "(1-2 sentence) practical recommendation about planting, irrigation, or fertilizer "
            "timing. Be specific and actionable, plain language, no jargon.\n\n"
            f"Forecast: {weather_summary}"
        ),
        config=types.GenerateContentConfig(temperature=0.3, max_output_tokens=120),
    )
    return response.text.strip()
