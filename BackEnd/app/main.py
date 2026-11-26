"""Aplicación principal FastAPI para el backend de PasoClaro."""

from pathlib import Path

from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from app.config import ALLOWED_IMAGE_MIME_TYPES, MAX_UPLOAD_BYTES
from app.schemas import (
    ChatRequest,
    ChatResponse,
    GuidesListResponse,
    HealthResponse,
    IdiomaType,
    PerfilType,
    ScannerResponse,
)
from app.services.gemini_service import analyze_document_image, generate_chat_response
from app.services.knowledge_service import get_all_guides, get_guide_by_id, load_glossary

_EXTENSION_TO_MIME: dict[str, str] = {
    ".jpg": "image/jpeg",
    ".jpeg": "image/jpeg",
    ".png": "image/png",
    ".webp": "image/webp",
}

app = FastAPI(
    title="PasoClaro API",
    description="Backend ligero para orientación de trámites, guías bilingües y escáner multimodal.",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def _resolve_valid_image_mime(file: UploadFile) -> str:
    """Valida el tipo MIME o extensión de la imagen subida y normaliza el MIME."""
    raw_mime = (file.content_type or "").lower().split(";")[0].strip()
    suffix = Path(file.filename or "").suffix.lower()

    if raw_mime in ALLOWED_IMAGE_MIME_TYPES:
        return "image/jpeg" if raw_mime == "image/jpg" else raw_mime

    if raw_mime in {"", "application/octet-stream"} and suffix in _EXTENSION_TO_MIME:
        return _EXTENSION_TO_MIME[suffix]

    raise HTTPException(
        status_code=400,
        detail="Formato de imagen no válido. Solo se aceptan archivos JPG, PNG o WebP.",
    )


@app.get("/")
async def root() -> dict[str, str]:
    """Punto de entrada raíz con información básica del servicio."""
    return {
        "service": "pasoclaro-backend",
        "status": "ok",
        "health": "/health",
        "docs": "/docs",
        "guides": "/api/guides",
    }


@app.get("/health", response_model=HealthResponse)
async def health_check() -> HealthResponse:
    """Verifica que el servicio esté activo."""
    return HealthResponse(status="ok", service="pasoclaro-backend")


@app.post("/api/assistant/chat", response_model=ChatResponse)
async def assistant_chat(request: ChatRequest) -> ChatResponse:
    """Procesa una consulta del asistente conversacional."""
    return await generate_chat_response(request)


@app.post("/api/scanner/analyze", response_model=ScannerResponse)
async def scanner_analyze(
    perfil: PerfilType = Form(...),
    idioma: IdiomaType = Form(...),
    file: UploadFile = File(...),
) -> ScannerResponse:
    """Analiza una imagen de documento oficial enviada como multipart/form-data."""
    normalized_mime = _resolve_valid_image_mime(file)

    image_bytes = await file.read(MAX_UPLOAD_BYTES + 1)
    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="El archivo enviado está vacío.",
        )

    if len(image_bytes) > MAX_UPLOAD_BYTES:
        raise HTTPException(
            status_code=400,
            detail="La imagen supera el tamaño máximo permitido de 10 MB.",
        )

    return await analyze_document_image(
        image_bytes=image_bytes,
        mime_type=normalized_mime,
        perfil=perfil,
        idioma=idioma,
    )


@app.get("/api/guides", response_model=GuidesListResponse)
async def list_guides() -> GuidesListResponse:
    """Devuelve todas las guías oficiales y el glosario validado."""
    return GuidesListResponse(
        guides=get_all_guides(),
        glossary=load_glossary(),
    )


@app.get("/api/guides/{guide_id}")
async def get_guide(guide_id: str) -> dict:
    """Devuelve el detalle de una guía por su identificador."""
    guide = get_guide_by_id(guide_id)
    if guide is None:
        raise HTTPException(status_code=404, detail="Guía no encontrada.")
    return guide
