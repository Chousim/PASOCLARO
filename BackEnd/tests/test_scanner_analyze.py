"""Pruebas para POST /api/scanner/analyze (subida multipart, normalización, fallback y errores)."""

import asyncio
import io

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from app.main import app
from app.schemas import ScannerResponse

client = TestClient(app)


def _patch_dummy_api_key(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("app.config.GEMINI_API_KEY", "test-dummy-key", raising=False)
    monkeypatch.setattr(
        "app.services.gemini_service.GEMINI_API_KEY", "test-dummy-key", raising=False
    )


def _make_image_bytes(image_format: str) -> bytes:
    buffer = io.BytesIO()
    img = Image.new("RGB", (16, 16), color="white")
    img.save(buffer, format=image_format)
    return buffer.getvalue()


@pytest.mark.parametrize(
    ("filename", "image_format", "mime_type", "expected_guia"),
    [
        ("cita.png", "PNG", "image/png", "salud_cita_clinica"),
        ("beca.jpg", "JPEG", "image/jpeg", "beca_apoyo_social"),
    ],
)
def test_scanner_analyze_valid_images(
    monkeypatch: pytest.MonkeyPatch,
    filename: str,
    image_format: str,
    mime_type: str,
    expected_guia: str,
):
    _patch_dummy_api_key(monkeypatch)

    def fake_call_scanner(*args, **kwargs) -> ScannerResponse:
        return ScannerResponse(
            tipo_documento="Cita medica" if expected_guia == "salud_cita_clinica" else "Constancia de estudios",
            titulo_corto="Hoja de cita en centro de salud" if expected_guia == "salud_cita_clinica" else "Constancia escolar",
            explicacion="Documento oficial con datos de atencion. Llevalo en original y copia.",
            fecha_limite="15 de diciembre de 2026",
            folio="FOLIO-12345",
            alerta_faltante="Recuerda llevar tu CURP impresa.",
            guia_id=expected_guia,
        )

    monkeypatch.setattr(
        "app.services.gemini_service._call_gemini_scanner", fake_call_scanner
    )

    image_bytes = _make_image_bytes(image_format)
    response = client.post(
        "/api/scanner/analyze",
        data={"perfil": "senior", "idioma": "es"},
        files={"file": (filename, image_bytes, mime_type)},
    )

    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {
        "tipo_documento",
        "titulo_corto",
        "explicacion",
        "fecha_limite",
        "folio",
        "alerta_faltante",
        "guia_id",
    }
    assert body["tipo_documento"].strip()
    assert body["titulo_corto"].strip()
    assert body["explicacion"].strip()
    assert body["fecha_limite"] == "15 de diciembre de 2026"
    assert body["folio"] == "FOLIO-12345"
    assert body["guia_id"] in {"salud_cita_clinica", "beca_apoyo_social"}
    assert body["guia_id"] == expected_guia


def test_scanner_analyze_normalizes_empty_fecha_and_folio(
    monkeypatch: pytest.MonkeyPatch,
):
    _patch_dummy_api_key(monkeypatch)

    def fake_call_scanner_empty_fields(*args, **kwargs) -> ScannerResponse:
        return ScannerResponse(
            tipo_documento="Comprobante",
            titulo_corto="Recibo de domicilio",
            explicacion="Comprobante valido para el tramite.",
            fecha_limite="",
            folio="   ",
            alerta_faltante=None,
            guia_id="salud_cita_clinica",
        )

    monkeypatch.setattr(
        "app.services.gemini_service._call_gemini_scanner",
        fake_call_scanner_empty_fields,
    )

    png_bytes = _make_image_bytes("PNG")
    response = client.post(
        "/api/scanner/analyze",
        data={"perfil": "student", "idioma": "es"},
        files={"file": ("recibo.png", png_bytes, "image/png")},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["fecha_limite"] == "[por verificar]"
    assert body["folio"] == "[sin folio]"


@pytest.mark.parametrize(
    "exc",
    [RuntimeError("Error de red"), asyncio.TimeoutError()],
)
def test_scanner_analyze_fallback_on_error_or_timeout(
    monkeypatch: pytest.MonkeyPatch, exc: Exception
):
    _patch_dummy_api_key(monkeypatch)

    def failing_scanner(*args, **kwargs):
        raise exc

    monkeypatch.setattr(
        "app.services.gemini_service._call_gemini_scanner", failing_scanner
    )

    png_bytes = _make_image_bytes("PNG")
    response = client.post(
        "/api/scanner/analyze",
        data={"perfil": "bilingual", "idioma": "yua"},
        files={"file": ("doc.png", png_bytes, "image/png")},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["tipo_documento"].strip()
    assert body["titulo_corto"].strip()
    assert body["explicacion"].strip()
    assert body["fecha_limite"].strip()
    assert body["folio"].strip()
    assert body["guia_id"] in {"salud_cita_clinica", "beca_apoyo_social"}


def test_scanner_analyze_rejects_empty_file():
    response = client.post(
        "/api/scanner/analyze",
        data={"perfil": "senior", "idioma": "es"},
        files={"file": ("vacio.png", b"", "image/png")},
    )
    assert response.status_code in {400, 422}


def test_scanner_analyze_rejects_non_image_mime():
    response = client.post(
        "/api/scanner/analyze",
        data={"perfil": "senior", "idioma": "es"},
        files={"file": ("notas.txt", b"contenido de texto plano", "text/plain")},
    )
    assert response.status_code in {400, 422}


def test_scanner_analyze_rejects_oversized_payload():
    oversized_bytes = b"0" * (10 * 1024 * 1024 + 1024)
    response = client.post(
        "/api/scanner/analyze",
        data={"perfil": "senior", "idioma": "es"},
        files={"file": ("grande.png", oversized_bytes, "image/png")},
    )
    assert response.status_code in {400, 422}
