"""Servicio de integración con Gemini (Structured Outputs) y fallback determinista."""

import asyncio
import inspect
import logging
import re

from google import genai
from google.genai import types

from app.config import (
    CHAT_TIMEOUT_SECONDS,
    GEMINI_API_KEY,
    GEMINI_MODEL,
    SCANNER_TIMEOUT_SECONDS,
)
from app.schemas import (
    ChatRequest,
    ChatResponse,
    GuiaIdType,
    IdiomaType,
    PerfilType,
    ScannerResponse,
)
from app.services.knowledge_service import (
    format_context_for_prompt,
    get_guide_by_id,
    get_guide_for_tramite,
    load_glossary,
)

logger = logging.getLogger(__name__)

_EMOJI_PATTERN = re.compile(
    "["
    "\U0001F1E6-\U0001F1FF"
    "\U0001F300-\U0001FAFF"
    "\U00002300-\U000023FF"
    "\U00002600-\U000027BF"
    "\U00002B00-\U00002BFF"
    "\U0000FE00-\U0000FE0F"
    "\U0000200D"
    "]+",
    flags=re.UNICODE,
)

_EMPTY_PLACEHOLDERS = {"", "n/a", "na", "none", "null", "sin dato", "no visible", "ninguno"}

_PROFILE_INSTRUCTIONS: dict[PerfilType, str] = {
    "senior": (
        "Perfil adulto mayor (senior): usa frases muy cortas, cálidas, amables y "
        "pausadas, fáciles de escuchar en lectura en voz alta."
    ),
    "student": (
        "Perfil estudiante (student): usa un tono cercano y explica con sencillez "
        "los términos administrativos como CURP, constancia, folio o ventanilla."
    ),
    "bilingual": (
        "Perfil bilingüe (bilingual): usa redacción muy clara, directa y cotidiana "
        "con oraciones sencillas de comprender."
    ),
    "offline": (
        "Perfil ahorro de datos / sin conexión (offline): entrega un resumen compacto, "
        "concreto y accionable con los pasos esenciales en pocas palabras."
    ),
}

_LANGUAGE_INSTRUCTIONS: dict[IdiomaType, str] = {
    "es": "Idioma español (es): responde únicamente en español claro y cotidiano.",
    "yua": (
        "Idioma maya yucateco (yua): escribe primero una explicación breve y respetuosa "
        "en maya yucateco en la parte superior usando los términos validados del glosario, "
        "y debajo escribe la explicación completa en español sencillo."
    ),
    "nah": (
        "Idioma náhuatl (nah): escribe primero una explicación breve y respetuosa "
        "en náhuatl en la parte superior usando los términos validados del glosario, "
        "y debajo escribe la explicación completa en español sencillo."
    ),
}


def sanitize_plain_text(text: str) -> str:
    """Limpia formato Markdown y emojis para que la lectura TTS y UI sea nítida."""
    if not text:
        return ""

    cleaned = text.replace("\r\n", "\n").replace("\r", "\n")
    # Enlaces Markdown [texto](url) -> texto (url)
    cleaned = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"\1 (\2)", cleaned)
    # Quitar bloques o comillas invertidas y marcadores de énfasis
    cleaned = cleaned.replace("```", "").replace("`", "")
    cleaned = cleaned.replace("**", "").replace("__", "")
    # Quitar encabezados Markdown y símbolos '#'
    cleaned = re.sub(r"(?m)^\s*#{1,6}\s*", "", cleaned)
    cleaned = cleaned.replace("#", "")
    # Quitar viñetas iniciales (- , * , + , • )
    cleaned = re.sub(r"(?m)^\s*[-*•+]\s+", "", cleaned)
    # Quitar asteriscos sueltos usados para énfasis
    cleaned = re.sub(r"(?<!\w)\*|\*(?!\w)", "", cleaned)
    # Quitar emojis y símbolos pictográficos
    cleaned = _EMOJI_PATTERN.sub("", cleaned)

    lines = [re.sub(r"[ \t]+", " ", line).strip() for line in cleaned.split("\n")]
    normalized_lines: list[str] = []
    previous_blank = False
    for line in lines:
        if not line:
            if not previous_blank and normalized_lines:
                normalized_lines.append("")
            previous_blank = True
        else:
            normalized_lines.append(line)
            previous_blank = False

    return "\n".join(normalized_lines).strip()


def _require_api_key() -> str:
    """Obtiene la API key configurada o lanza error si falta."""
    api_key = GEMINI_API_KEY.strip()
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY no está configurada.")
    return api_key


def _call_gemini_chat(prompt: str, system_instruction: str) -> ChatResponse:
    """Ejecuta una llamada síncrona con Structured Output a Gemini para el chat."""
    api_key = _require_api_key()
    client = genai.Client(api_key=api_key)
    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        response_mime_type="application/json",
        response_schema=ChatResponse,
        temperature=0.2,
    )
    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=prompt,
        config=config,
    )

    parsed = getattr(response, "parsed", None)
    if isinstance(parsed, ChatResponse):
        return parsed
    if isinstance(parsed, dict):
        return ChatResponse.model_validate(parsed)
    if getattr(response, "text", None):
        return ChatResponse.model_validate_json(response.text)
    raise ValueError("Respuesta vacía de Gemini para chat.")


def _call_gemini_scanner(
    image_bytes: bytes,
    mime_type: str,
    prompt: str,
    system_instruction: str,
) -> ScannerResponse:
    """Ejecuta una llamada multimodal síncrona con Structured Output para escáner."""
    api_key = _require_api_key()
    client = genai.Client(api_key=api_key)
    config = types.GenerateContentConfig(
        system_instruction=system_instruction,
        response_mime_type="application/json",
        response_schema=ScannerResponse,
        temperature=0.2,
    )
    image_part = types.Part.from_bytes(data=image_bytes, mime_type=mime_type)
    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=[image_part, prompt],
        config=config,
    )

    parsed = getattr(response, "parsed", None)
    if isinstance(parsed, ScannerResponse):
        return parsed
    if isinstance(parsed, dict):
        return ScannerResponse.model_validate(parsed)
    if getattr(response, "text", None):
        return ScannerResponse.model_validate_json(response.text)
    raise ValueError("Respuesta vacía de Gemini para escáner.")


def _find_missing_requirements(
    requisitos: list[str],
    docs_completados: list[str],
) -> list[str]:
    """Identifica requisitos de la guía que aún no coinciden con docs_completados."""
    if not docs_completados:
        return list(requisitos)

    completed_norm = [doc.strip().lower() for doc in docs_completados if doc and doc.strip()]
    missing: list[str] = []
    for req in requisitos:
        req_lower = req.lower()
        is_done = any(
            done in req_lower or req_lower in done or _shares_key_token(req_lower, done)
            for done in completed_norm
        )
        if not is_done:
            missing.append(req)
    return missing


def _shares_key_token(requirement: str, completed: str) -> bool:
    """Comprueba coincidencias por palabra clave institucional (INE, CURP, domicilio, etc.)."""
    keywords = ("ine", "curp", "domicilio", "constancia", "estudios", "acta", "solicitud")
    return any(word in requirement and word in completed for word in keywords)


def _select_glossary_snippet(idioma: IdiomaType, text_hint: str) -> str:
    """Construye una línea breve con términos validados del glosario en yua o nah."""
    if idioma not in {"yua", "nah"}:
        return ""

    glossary = load_glossary()
    hint_lower = text_hint.lower()
    matched: list[str] = []
    for entry in glossary:
        term_es = str(entry.get("termino_es", ""))
        translated = str(entry.get(idioma, "")).strip()
        if not translated:
            continue
        if any(word in hint_lower for word in term_es.lower().split() if len(word) > 3):
            matched.append(f"{translated} ({term_es})")
        if len(matched) >= 3:
            break

    if not matched:
        for entry in glossary[:3]:
            translated = str(entry.get(idioma, "")).strip()
            term_es = str(entry.get("termino_es", "")).strip()
            if translated:
                matched.append(f"{translated} ({term_es})")

    lang_label = "Maya yucateco" if idioma == "yua" else "Náhuatl"
    if idioma == "yua":
        intro = "Ma'alob k'iin. Ba'ax k'a'abéet tech:"
    else:
        intro = "Cualli tonalli. Tlen monequi:"
    return f"{lang_label}: {intro} " + ", ".join(matched) + "."


def _build_chat_prompts(req: ChatRequest) -> tuple[str, str]:
    """Genera las instrucciones de sistema y el prompt contextualizado para el chat."""
    context_text = format_context_for_prompt(req.tramite, req.idioma)
    completed_text = (
        ", ".join(req.docs_completados) if req.docs_completados else "Ninguno reportado todavía"
    )

    system_instruction = (
        "Eres el asistente de PasoClaro para orientar sobre trámites públicos en México.\n"
        "Reglas obligatorias:\n"
        "1. Responde únicamente en texto plano sin emojis y sin formato Markdown (no uses **, __, #, backticks ni viñetas).\n"
        "2. No inventes requisitos, teléfonos, direcciones ni URLs; apóyate estrictamente en el contexto oficial proporcionado.\n"
        f"3. {_PROFILE_INSTRUCTIONS[req.perfil]}\n"
        f"4. {_LANGUAGE_INSTRUCTIONS[req.idioma]}\n"
        "5. Incluye en respuestas_rapidas entre 2 y 3 opciones muy cortas para que la persona elija; "
        "cuando sea útil, incluye una opción con la palabra 'lista' (por ejemplo 'Abrir mi lista paso a paso') "
        "y otra con la palabra 'escanear' (por ejemplo 'Escanear un documento').\n"
        "6. Formula una pregunta_siguiente concreta y amable para ayudar a verificar qué documento falta."
    )

    prompt = (
        f"Contexto oficial y glosario:\n{context_text}\n\n"
        f"Perfil del usuario: {req.perfil}\n"
        f"Idioma solicitado: {req.idioma}\n"
        f"Trámite seleccionado: {req.tramite}\n"
        f"Documentos que el usuario ya completó: {completed_text}\n"
        f"Mensaje del usuario: {req.mensaje}"
    )
    return prompt, system_instruction


def _build_scanner_prompts(perfil: PerfilType, idioma: IdiomaType) -> tuple[str, str]:
    """Genera el prompt y las instrucciones del sistema para el escáner multimodal."""
    salud_context = format_context_for_prompt("salud", idioma)
    tramites_context = format_context_for_prompt("tramites", idioma)

    system_instruction = (
        "Eres el escáner accesible de PasoClaro para explicar documentos públicos en México.\n"
        "Reglas obligatorias:\n"
        "1. Usa texto plano únicamente: sin emojis y sin Markdown (sin **, __, #, backticks ni viñetas).\n"
        "2. No inventes requisitos, teléfonos ni páginas oficiales; usa solo la información de la imagen y el contexto oficial.\n"
        "3. Clasifica guia_id estrictamente como 'salud_cita_clinica' (si el documento es médico, de clínica o salud) "
        "o 'beca_apoyo_social' (si es de beca, escuela, apoyo social o trámite administrativo).\n"
        "4. Si no se distingue una fecha límite en la imagen, devuelve exactamente '[por verificar]' en fecha_limite. "
        "Si no se distingue un folio o número de registro, devuelve exactamente '[sin folio]' en folio.\n"
        f"5. {_PROFILE_INSTRUCTIONS[perfil]}\n"
        f"6. {_LANGUAGE_INSTRUCTIONS[idioma]}"
    )

    prompt = (
        "Analiza la imagen del documento adjunto y explica de forma clara qué documento es, "
        "qué fecha límite o folio tiene y qué requisito podría faltar.\n\n"
        f"Referencia Salud:\n{salud_context}\n\n"
        f"Referencia Trámites y Apoyos:\n{tramites_context}"
    )
    return prompt, system_instruction


def _normalize_chat_response(raw: ChatResponse, tramite: str) -> ChatResponse:
    """Sanitiza todos los textos del chat y garantiza 2 a 3 respuestas rápidas."""
    guide = get_guide_for_tramite(tramite)
    default_etiqueta = str(guide.get("etiqueta_oficial") or "Oficial · PasoClaro")

    respuesta = sanitize_plain_text(raw.respuesta) or (
        f"Guía oficial para {guide.get('titulo', 'tu trámite')}."
    )
    etiqueta = sanitize_plain_text(raw.etiqueta_oficial) or sanitize_plain_text(default_etiqueta)
    pregunta = sanitize_plain_text(raw.pregunta_siguiente) or (
        "Quieres revisar que documentos ya tienes listos?"
    )

    quick_replies = [
        sanitize_plain_text(item)
        for item in raw.respuestas_rapidas
        if sanitize_plain_text(item)
    ]
    defaults = [
        "Abrir mi lista paso a paso",
        "Escanear un documento",
        "Ver contacto oficial",
    ]
    for fallback_reply in defaults:
        if len(quick_replies) >= 2:
            break
        if fallback_reply not in quick_replies:
            quick_replies.append(fallback_reply)

    return ChatResponse(
        respuesta=respuesta,
        etiqueta_oficial=etiqueta,
        pregunta_siguiente=pregunta,
        respuestas_rapidas=quick_replies[:3],
    )


def _normalize_scanner_response(raw: ScannerResponse) -> ScannerResponse:
    """Sanitiza textos y normaliza valores vacíos de fecha_limite y folio."""
    tipo_documento = sanitize_plain_text(raw.tipo_documento) or "Documento oficial"
    titulo_corto = sanitize_plain_text(raw.titulo_corto) or "Documento revisado"
    explicacion = sanitize_plain_text(raw.explicacion) or (
        "Revisa los requisitos del trámite oficial antes de acudir a tu cita."
    )

    fecha_clean = sanitize_plain_text(raw.fecha_limite)
    if fecha_clean.lower() in _EMPTY_PLACEHOLDERS:
        fecha_clean = "[por verificar]"

    folio_clean = sanitize_plain_text(raw.folio)
    if folio_clean.lower() in _EMPTY_PLACEHOLDERS:
        folio_clean = "[sin folio]"

    alerta: str | None = None
    if raw.alerta_faltante is not None:
        alerta_clean = sanitize_plain_text(raw.alerta_faltante)
        alerta = alerta_clean if alerta_clean else None

    guia_id: GuiaIdType = (
        raw.guia_id
        if raw.guia_id in ("salud_cita_clinica", "beca_apoyo_social")
        else "salud_cita_clinica"
    )

    return ScannerResponse(
        tipo_documento=tipo_documento,
        titulo_corto=titulo_corto,
        explicacion=explicacion,
        fecha_limite=fecha_clean,
        folio=folio_clean,
        alerta_faltante=alerta,
        guia_id=guia_id,
    )


def _build_chat_fallback(req: ChatRequest) -> ChatResponse:
    """Construye una respuesta determinista segura usando knowledge_base y glossary."""
    guide = get_guide_for_tramite(req.tramite)
    titulo = str(guide.get("titulo", "Trámite oficial"))
    etiqueta = str(guide.get("etiqueta_oficial", "Oficial · PasoClaro"))
    requisitos = [str(item) for item in guide.get("requisitos", [])]
    pasos = [str(item) for item in guide.get("pasos", [])]
    canal = guide.get("canal_oficial", {}) or {}

    missing = _find_missing_requirements(requisitos, req.docs_completados)
    if missing:
        pendientes_text = "; ".join(missing)
        detalle_req = f"Para {titulo}, te falta preparar: {pendientes_text}."
        pregunta = f"Ya cuentas con {missing[0]}?"
    else:
        detalle_req = (
            f"Ya tienes completos los documentos principales para {titulo}."
        )
        pregunta = "Deseas abrir tu lista paso a paso para acudir a tu atencion?"

    paso_inicial = f" Primer paso: {pasos[0]}." if pasos else ""
    institucion = canal.get("institucion", "Oficina de atención oficial")
    telefono = canal.get("telefono", "")
    url = canal.get("url", "")
    nota = canal.get("nota", "Trámite gratuito sin intermediarios.")

    contacto_partes = [f"Canal oficial: {institucion}"]
    if telefono:
        contacto_partes.append(f"teléfono {telefono}")
    if url:
        contacto_partes.append(f"sitio {url}")
    contacto_text = ", ".join(contacto_partes) + f". {nota}"

    if req.perfil == "senior":
        cuerpo_es = (
            f"Con gusto te ayudo. {detalle_req} "
            f"Ve con calma.{paso_inicial} {contacto_text}"
        )
    elif req.perfil == "student":
        cuerpo_es = (
            f"{detalle_req} Recuerda que estos documentos son personales y gratuitos.{paso_inicial} "
            f"{contacto_text}"
        )
    elif req.perfil == "offline":
        cuerpo_es = f"{detalle_req}{paso_inicial} {contacto_text}"
    else:
        cuerpo_es = f"{detalle_req}{paso_inicial} {contacto_text}"

    if req.idioma in {"yua", "nah"}:
        bilingual_top = _select_glossary_snippet(req.idioma, " ".join(requisitos))
        respuesta_final = f"{bilingual_top}\n\nEspañol: {cuerpo_es}"
    else:
        respuesta_final = cuerpo_es

    return _normalize_chat_response(
        ChatResponse(
            respuesta=respuesta_final,
            etiqueta_oficial=etiqueta,
            pregunta_siguiente=pregunta,
            respuestas_rapidas=[
                "Abrir mi lista paso a paso",
                "Escanear un documento",
                "Ver telefono oficial",
            ],
        ),
        tramite=req.tramite,
    )


def _build_scanner_fallback(perfil: PerfilType, idioma: IdiomaType) -> ScannerResponse:
    """Construye una respuesta segura de respaldo para el escáner."""
    guide = get_guide_by_id("salud_cita_clinica") or get_guide_for_tramite("salud")
    requisitos = [str(item) for item in guide.get("requisitos", [])]
    canal = guide.get("canal_oficial", {}) or {}
    institucion = canal.get("institucion", "Centro de Salud Urbano")
    telefono = canal.get("telefono", "")

    if perfil == "senior":
        cuerpo_es = (
            "No pudimos leer la imagen completa en este momento. "
            "Revisa en tu hoja la fecha y el folio. "
            f"Ten a la mano tu identificación oficial, CURP y comprobante de domicilio. "
            f"Atención en {institucion}" + (f" al {telefono}." if telefono else ".")
        )
    elif perfil == "offline":
        cuerpo_es = (
            "Lectura automática no disponible. Verifica fecha límite, folio y lleva "
            "identificación oficial, CURP y comprobante de domicilio."
        )
    else:
        cuerpo_es = (
            "No se pudo completar la lectura automática de la foto. "
            "Verifica manualmente la fecha límite y el folio en el documento, y confirma "
            "que cuentas con identificación oficial, CURP y comprobante de domicilio. "
            f"Consulta gratuita en {institucion}" + (f" ({telefono})." if telefono else ".")
        )

    if idioma in {"yua", "nah"}:
        bilingual_top = _select_glossary_snippet(idioma, " ".join(requisitos))
        explicacion = f"{bilingual_top}\n\nEspañol: {cuerpo_es}"
    else:
        explicacion = cuerpo_es

    return _normalize_scanner_response(
        ScannerResponse(
            tipo_documento="Documento público",
            titulo_corto="Documento por verificar",
            explicacion=explicacion,
            fecha_limite="[por verificar]",
            folio="[sin folio]",
            alerta_faltante=(
                "Verifica si cuentas con identificación oficial vigente, CURP impresa "
                "y comprobante de domicilio."
            ),
            guia_id="salud_cita_clinica",
        )
    )


async def generate_chat_response(req: ChatRequest) -> ChatResponse:
    """Genera la respuesta del asistente con Gemini y fallback seguro ante fallos."""
    prompt, system_instruction = _build_chat_prompts(req)
    try:
        if inspect.iscoroutinefunction(_call_gemini_chat):
            raw_result = await asyncio.wait_for(
                _call_gemini_chat(prompt, system_instruction),
                timeout=CHAT_TIMEOUT_SECONDS,
            )
        else:
            raw_result = await asyncio.wait_for(
                asyncio.to_thread(_call_gemini_chat, prompt, system_instruction),
                timeout=CHAT_TIMEOUT_SECONDS,
            )
        return _normalize_chat_response(raw_result, tramite=req.tramite)
    except Exception as exc:
        logger.warning("Fallback en asistente de chat por error o timeout: %s", exc)
        return _build_chat_fallback(req)


async def analyze_document_image(
    image_bytes: bytes,
    mime_type: str,
    perfil: PerfilType,
    idioma: IdiomaType,
) -> ScannerResponse:
    """Analiza la fotografía de un documento con Gemini y fallback seguro ante fallos."""
    prompt, system_instruction = _build_scanner_prompts(perfil=perfil, idioma=idioma)
    try:
        if inspect.iscoroutinefunction(_call_gemini_scanner):
            raw_result = await asyncio.wait_for(
                _call_gemini_scanner(image_bytes, mime_type, prompt, system_instruction),
                timeout=SCANNER_TIMEOUT_SECONDS,
            )
        else:
            raw_result = await asyncio.wait_for(
                asyncio.to_thread(
                    _call_gemini_scanner,
                    image_bytes,
                    mime_type,
                    prompt,
                    system_instruction,
                ),
                timeout=SCANNER_TIMEOUT_SECONDS,
            )
        return _normalize_scanner_response(raw_result)
    except Exception as exc:
        logger.warning("Fallback en escáner multimodal por error o timeout: %s", exc)
        return _build_scanner_fallback(perfil=perfil, idioma=idioma)
