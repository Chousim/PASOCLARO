"""Configuración del backend de PasoClaro."""

from pathlib import Path
import os

from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"

load_dotenv(dotenv_path=ENV_FILE)

GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "").strip()
GEMINI_MODEL: str = (
    os.getenv("GEMINI_MODEL", "gemini-3.5-flash-lite").strip() or "gemini-3.5-flash-lite"
)
GEMINI_FALLBACK_MODELS: tuple[str, ...] = (
    "gemini-3.5-flash-lite",
    "gemini-3.1-flash-lite",
)
DEPRECATED_GEMINI_MODELS: set[str] = {"gemini-2.5-flash"}

CHAT_TIMEOUT_SECONDS: float = 9.0
SCANNER_TIMEOUT_SECONDS: float = 16.0
MAX_UPLOAD_BYTES: int = 10 * 1024 * 1024
ALLOWED_IMAGE_MIME_TYPES: set[str] = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
}
