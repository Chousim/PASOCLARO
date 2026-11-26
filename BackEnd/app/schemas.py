"""Esquemas Pydantic v2 para los contratos de entrada y salida de la API."""

from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator

PerfilType = Literal["senior", "bilingual", "student", "offline"]
IdiomaType = Literal["es", "yua", "nah"]
TramiteType = Literal["salud", "tramites", "educacion", "empleo"]
GuiaIdType = Literal["salud_cita_clinica", "beca_apoyo_social"]


class HealthResponse(BaseModel):
    """Respuesta del endpoint de estado del servicio."""

    status: str
    service: str


class ChatRequest(BaseModel):
    """Solicitud para el asistente conversacional guiado."""

    perfil: PerfilType
    idioma: IdiomaType
    tramite: TramiteType
    docs_completados: list[str] = Field(default_factory=list)
    mensaje: str = Field(..., min_length=1)

    @field_validator("mensaje")
    @classmethod
    def strip_and_validate_mensaje(cls, value: str) -> str:
        """Elimina espacios externos y rechaza mensajes en blanco."""
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("El mensaje no puede estar vacío.")
        return cleaned


class ChatResponse(BaseModel):
    """Respuesta estructurada del asistente conversacional."""

    respuesta: str
    etiqueta_oficial: str
    pregunta_siguiente: str
    respuestas_rapidas: list[str]


class ScannerResponse(BaseModel):
    """Respuesta estructurada del escáner multimodal de documentos."""

    tipo_documento: str
    titulo_corto: str
    explicacion: str
    fecha_limite: str
    folio: str
    alerta_faltante: str | None = None
    guia_id: GuiaIdType


class GuidesListResponse(BaseModel):
    """Listado completo de guías oficiales y glosario intercultural."""

    guides: list[dict[str, Any]]
    glossary: list[dict[str, Any]]
