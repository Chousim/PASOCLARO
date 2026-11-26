"""Pruebas para POST /api/assistant/chat (contrato, sanitización, fallback y validación)."""

import asyncio
import os
import re

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas import ChatResponse
from app.services.knowledge_service import load_glossary

client = TestClient(app)

EMOJI_PATTERN = re.compile(r"[\U0001F300-\U0001FAFF\u2600-\u27BF]")


def _patch_dummy_api_key(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr("app.config.GEMINI_API_KEY", "test-dummy-key", raising=False)
    monkeypatch.setattr(
        "app.services.gemini_service.GEMINI_API_KEY", "test-dummy-key", raising=False
    )


@pytest.mark.parametrize("perfil", ["senior", "bilingual", "student", "offline"])
@pytest.mark.parametrize("idioma", ["es", "yua", "nah"])
@pytest.mark.parametrize("tramite", ["salud", "tramites", "educacion", "empleo"])
def test_assistant_chat_contract_matrix(
    monkeypatch: pytest.MonkeyPatch,
    perfil: str,
    idioma: str,
    tramite: str,
):
    _patch_dummy_api_key(monkeypatch)

    def fake_call_gemini_chat(*args, **kwargs) -> ChatResponse:
        return ChatResponse(
            respuesta=(
                f"Orientacion clara para perfil {perfil} en idioma {idioma} "
                f"sobre el tramite {tramite}. Lleva tu CURP y comprobante."
            ),
            etiqueta_oficial="Oficial · Salud",
            pregunta_siguiente="Ya tienes tu CURP impresa?",
            respuestas_rapidas=[
                "Abrir mi lista paso a paso",
                "Escanear un documento",
                "Ver horario oficial",
            ],
        )

    monkeypatch.setattr(
        "app.services.gemini_service._call_gemini_chat", fake_call_gemini_chat
    )

    response = client.post(
        "/api/assistant/chat",
        json={
            "perfil": perfil,
            "idioma": idioma,
            "tramite": tramite,
            "docs_completados": ["Identificación oficial vigente (INE, original y copia)"],
            "mensaje": "Que documentos necesito llevar?",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert set(body.keys()) == {
        "respuesta",
        "etiqueta_oficial",
        "pregunta_siguiente",
        "respuestas_rapidas",
    }
    assert isinstance(body["respuesta"], str) and body["respuesta"].strip()
    assert isinstance(body["etiqueta_oficial"], str) and body["etiqueta_oficial"].strip()
    assert isinstance(body["pregunta_siguiente"], str) and body["pregunta_siguiente"].strip()
    assert isinstance(body["respuestas_rapidas"], list)
    assert 2 <= len(body["respuestas_rapidas"]) <= 3


def test_assistant_chat_plain_text_sanitization(monkeypatch: pytest.MonkeyPatch):
    _patch_dummy_api_key(monkeypatch)

    def fake_dirty_gemini(*args, **kwargs) -> ChatResponse:
        return ChatResponse(
            respuesta="## **Paso 1** 📄\n- Lleva tu `INE` vigente ✅\n* Y tu **CURP** 🏥",
            etiqueta_oficial="**Oficial · Salud** 🏥",
            pregunta_siguiente="# ¿Ya tienes tus copias? 📄",
            respuestas_rapidas=[
                "**Abrir mi lista** ✅",
                "`Escanear documento` 📄",
            ],
        )

    monkeypatch.setattr(
        "app.services.gemini_service._call_gemini_chat", fake_dirty_gemini
    )

    response = client.post(
        "/api/assistant/chat",
        json={
            "perfil": "senior",
            "idioma": "es",
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "Necesito sacar una cita",
        },
    )

    assert response.status_code == 200
    body = response.json()

    all_texts = [
        body["respuesta"],
        body["etiqueta_oficial"],
        body["pregunta_siguiente"],
        *body["respuestas_rapidas"],
    ]
    for text in all_texts:
        assert "**" not in text
        assert "#" not in text
        assert "`" not in text
        assert not EMOJI_PATTERN.search(text)

    assert "Paso 1" in body["respuesta"]
    assert "INE" in body["respuesta"]
    assert "CURP" in body["respuesta"]


@pytest.mark.parametrize(
    "exc",
    [RuntimeError("Error simulado de Gemini"), asyncio.TimeoutError()],
)
def test_assistant_chat_fallback_on_error_or_timeout(
    monkeypatch: pytest.MonkeyPatch, exc: Exception
):
    _patch_dummy_api_key(monkeypatch)

    def failing_call(*args, **kwargs):
        raise exc

    monkeypatch.setattr("app.services.gemini_service._call_gemini_chat", failing_call)

    response = client.post(
        "/api/assistant/chat",
        json={
            "perfil": "senior",
            "idioma": "es",
            "tramite": "salud",
            "docs_completados": ["Identificación oficial vigente (INE, original y copia)"],
            "mensaje": "Que me falta para mi cita?",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["respuesta"].strip()
    assert body["etiqueta_oficial"].strip()
    assert body["pregunta_siguiente"].strip()
    assert 2 <= len(body["respuestas_rapidas"]) <= 3
    # Debe mencionar requisitos faltantes de knowledge_base.json (CURP o comprobante de domicilio)
    respuesta_lower = body["respuesta"].lower()
    assert "curp" in respuesta_lower or "domicilio" in respuesta_lower
    assert "**" not in body["respuesta"]
    assert "#" not in body["respuesta"]
    assert not EMOJI_PATTERN.search(body["respuesta"])


@pytest.mark.parametrize("idioma", ["yua", "nah"])
def test_assistant_chat_fallback_bilingual_for_indigenous_languages(
    monkeypatch: pytest.MonkeyPatch, idioma: str
):
    _patch_dummy_api_key(monkeypatch)

    def failing_call(*args, **kwargs):
        raise asyncio.TimeoutError()

    monkeypatch.setattr("app.services.gemini_service._call_gemini_chat", failing_call)

    response = client.post(
        "/api/assistant/chat",
        json={
            "perfil": "bilingual",
            "idioma": idioma,
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "Ayudame con los requisitos",
        },
    )

    assert response.status_code == 200
    body = response.json()
    respuesta = body["respuesta"]
    assert respuesta.strip()

    glossary = load_glossary()
    indigenous_terms = [entry[idioma] for entry in glossary if entry.get(idioma)]
    # El fallback bilingüe debe incluir términos validados del glosario en yua o nah
    assert any(term.lower() in respuesta.lower() for term in indigenous_terms)


@pytest.mark.parametrize(
    "payload",
    [
        {
            "perfil": "invalido",
            "idioma": "es",
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "Hola",
        },
        {
            "perfil": "senior",
            "idioma": "fr",
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "Hola",
        },
        {
            "perfil": "senior",
            "idioma": "es",
            "tramite": "otro_tramite",
            "docs_completados": [],
            "mensaje": "Hola",
        },
        {
            "perfil": "senior",
            "idioma": "es",
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "   ",
        },
        {
            "perfil": "senior",
            "idioma": "es",
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "",
        },
    ],
)
def test_assistant_chat_validation_errors(payload: dict):
    response = client.post("/api/assistant/chat", json=payload)
    assert response.status_code == 422


@pytest.mark.skipif(
    not os.getenv("RUN_LIVE_GEMINI_TESTS"),
    reason="Set RUN_LIVE_GEMINI_TESTS=1 to test live Gemini API",
)
def test_assistant_chat_live_gemini():
    response = client.post(
        "/api/assistant/chat",
        json={
            "perfil": "senior",
            "idioma": "es",
            "tramite": "salud",
            "docs_completados": [],
            "mensaje": "Que necesito para pedir una cita en el centro de salud?",
        },
    )
    assert response.status_code == 200
    body = response.json()
    assert body["respuesta"].strip()
    assert body["etiqueta_oficial"].strip()
    assert body["pregunta_siguiente"].strip()
    assert 2 <= len(body["respuestas_rapidas"]) <= 3
    assert "**" not in body["respuesta"]
    assert "#" not in body["respuesta"]
    assert not EMOJI_PATTERN.search(body["respuesta"])
