import os
from functools import lru_cache


class Settings:
    """
    Central settings, all sourced from environment variables.

    NEVER hardcode API keys here. Set GEMINI_API_KEY in a local `.env` file
    (which is gitignored) for local dev, or as an encrypted environment
    variable in your deployment platform (Render, Railway, Codemagic, etc.)
    in production.
    """

    def __init__(self) -> None:
        self.gemini_api_key: str = os.environ.get("GEMINI_API_KEY", "")
        # gemini-2.0-flash was shut down June 1, 2026 — do not use it.
        # gemini-2.5-flash is the current stable, cost-effective multimodal
        # model (handles both text and image input, which we need for both
        # the voice assistant and disease-detection endpoints).
        self.gemini_model: str = os.environ.get("GEMINI_MODEL", "gemini-2.5-flash")
        self.allowed_origins: list[str] = os.environ.get("ALLOWED_ORIGINS", "*").split(",")
        self.environment: str = os.environ.get("ENVIRONMENT", "dev")

        if not self.gemini_api_key:
            # Fail loudly rather than silently returning broken AI responses.
            print(
                "WARNING: GEMINI_API_KEY is not set. Disease detection and "
                "voice assistant endpoints will return an error until it is configured."
            )


@lru_cache
def get_settings() -> Settings:
    return Settings()
