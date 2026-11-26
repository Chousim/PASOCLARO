"""Knowledge base and bilingual glossary service for PasoClaro."""

from __future__ import annotations

import json
from functools import lru_cache
from pathlib import Path
from typing import Any

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
KNOWLEDGE_BASE_PATH = DATA_DIR / "knowledge_base.json"
GLOSSARY_PATH = DATA_DIR / "glossary.json"

DEFAULT_GUIDE_ID = "salud_cita_clinica"
TRAMITE_TO_GUIDE_ID: dict[str, str] = {
    "salud": "salud_cita_clinica",
    "tramites": "beca_apoyo_social",
    "educacion": "educacion_beca_escolar",
    "empleo": "empleo_servicio_nacional",
}


@lru_cache(maxsize=1)
def load_knowledge_base() -> list[dict[str, Any]]:
    """Load verified public procedure guides from static JSON storage."""
    with KNOWLEDGE_BASE_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)
    if not isinstance(data, list):
        raise ValueError("knowledge_base.json must contain a list of guide objects.")
    return data


@lru_cache(maxsize=1)
def load_glossary() -> list[dict[str, Any]]:
    """Load validated institutional glossary entries from static JSON storage."""
    with GLOSSARY_PATH.open("r", encoding="utf-8") as file:
        data = json.load(file)
    if not isinstance(data, list):
        raise ValueError("glossary.json must contain a list of glossary objects.")
    return data


def get_all_guides() -> list[dict[str, Any]]:
    """Return all verified procedure guides."""
    return list(load_knowledge_base())


def get_guide_by_id(guide_id: str) -> dict[str, Any] | None:
    """Return a single verified procedure guide matching guide_id, or None."""
    normalized_id = (guide_id or "").strip()
    if not normalized_id:
        return None
    for guide in load_knowledge_base():
        if guide.get("id") == normalized_id:
            return guide
    return None


def get_guide_for_tramite(tramite: str) -> dict[str, Any]:
    """Return the primary verified guide for a tramite category, defaulting to salud_cita_clinica."""
    normalized_tramite = (tramite or "").strip().lower()
    target_id = TRAMITE_TO_GUIDE_ID.get(normalized_tramite, DEFAULT_GUIDE_ID)
    guide = get_guide_by_id(target_id)
    if guide is not None:
        return guide

    fallback = get_guide_by_id(DEFAULT_GUIDE_ID)
    if fallback is not None:
        return fallback

    guides = load_knowledge_base()
    if not guides:
        raise ValueError("knowledge_base.json contains no guides.")
    return guides[0]


def format_context_for_prompt(tramite: str, idioma: str) -> str:
    """Format verified guide requirements, official channel, and glossary into plain-text prompt context."""
    guide = get_guide_for_tramite(tramite)
    glossary = load_glossary()
    lang = (idioma or "es").strip().lower()

    lines: list[str] = [
        f"Guía oficial verificada: {guide.get('titulo', '')}",
        f"Etiqueta oficial: {guide.get('etiqueta_oficial', '')}",
        f"ID de guía: {guide.get('id', '')}",
        f"Categoría de trámite: {guide.get('tramite', '')}",
        "",
        "Requisitos oficiales verificados:",
    ]

    for index, req in enumerate(guide.get("requisitos", []), start=1):
        lines.append(f"{index}. {req}")

    lines.append("")
    lines.append("Pasos recomendados verificados:")
    for index, step in enumerate(guide.get("pasos", []), start=1):
        lines.append(f"{index}. {step}")

    canal = guide.get("canal_oficial", {})
    lines.extend(
        [
            "",
            "Canal oficial verificable:",
            f"Institución: {canal.get('institucion', '')}",
            f"Horario: {canal.get('horario', '')}",
            f"Teléfono: {canal.get('telefono', '')}",
            f"Sitio web: {canal.get('url', '')}",
            f"Nota: {canal.get('nota', '')}",
            "",
            "Glosario institucional validado:",
        ]
    )

    if lang == "yua":
        lines.append(
            "Idioma objetivo: Maya yucateco (yua) arriba usando los términos validados y español sencillo abajo."
        )
        for item in glossary:
            lines.append(
                f"Término: {item.get('termino_es', '')} | Maya yucateco (yua): {item.get('yua', '')} | Explicación: {item.get('explicacion_sencilla', '')}"
            )
    elif lang == "nah":
        lines.append(
            "Idioma objetivo: Náhuatl (nah) arriba usando los términos validados y español sencillo abajo."
        )
        for item in glossary:
            lines.append(
                f"Término: {item.get('termino_es', '')} | Náhuatl (nah): {item.get('nah', '')} | Explicación: {item.get('explicacion_sencilla', '')}"
            )
    else:
        lines.append("Idioma objetivo: Español sencillo (es).")
        for item in glossary:
            lines.append(
                f"Término: {item.get('termino_es', '')} | Explicación: {item.get('explicacion_sencilla', '')}"
            )

    return "\n".join(lines)
