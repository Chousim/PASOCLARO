# PasoClaro BackEnd

API REST en FastAPI para **PasoClaro**, conectada con **Google Gemini** (`google-genai`) y una base de conocimiento verificada de trámites públicos en México (español, maya yucateco `yua` y náhuatl `nah`).

## Requisitos

- **Python 3.11+**
- **pip** actualizado
- Llave de API de Google AI Studio (`GEMINI_API_KEY`)

## Instalación y entorno virtual (`.venv`)

Ubícate dentro de la carpeta `BackEnd/`:

```bash
cd BackEnd
```

### Windows (PowerShell)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

### Linux / macOS

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## Configuración de `.env`

Crea tu archivo `.env` local a partir de `.env.example` (nunca subas `.env` al repositorio):

```bash
# Windows PowerShell
Copy-Item .env.example .env

# Linux / macOS
cp .env.example .env
```

Edita `BackEnd/.env` con tu clave real:

```env
GEMINI_API_KEY=tu_api_key_de_google_ai_studio
GEMINI_MODEL=gemini-2.5-flash
```

## Arranque en desarrollo local

Con el entorno `.venv` activado y dentro de `BackEnd/`:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Acceso desde clientes y documentación interactiva

- **Swagger UI (`/docs`)**: `http://localhost:8000/docs`
- **Emulador Android**: usa `http://10.0.2.2:8000` (el emulador mapea `10.0.2.2` al `localhost` de tu computadora).
- **Celular físico (misma red Wi-Fi)**: usa la IP local de tu equipo, por ejemplo `http://192.168.1.50:8000` (asegúrate de permitir el puerto `8000` en el firewall).

## Ejemplos con `curl`

### 1. Verificar estado del servicio (`GET /health`)

```bash
curl -s http://localhost:8000/health
```

### 2. Consultar guías oficiales y glosario (`GET /api/guides`)

```bash
curl -s http://localhost:8000/api/guides
```

Para consultar una guía específica:

```bash
curl -s http://localhost:8000/api/guides/salud_cita_clinica
```

### 3. Asistente de trámites (`POST /api/assistant/chat`)

```bash
curl -s -X POST http://localhost:8000/api/assistant/chat \
  -H "Content-Type: application/json" \
  -d '{
    "perfil": "senior",
    "idioma": "es",
    "tramite": "salud",
    "docs_completados": ["Identificación oficial vigente (INE, original y copia)"],
    "mensaje": "¿Qué documentos me faltan para sacar cita en el centro de salud?"
  }'
```

Valores admitidos:
- `perfil`: `senior`, `bilingual`, `student`, `offline`
- `idioma`: `es`, `yua`, `nah`
- `tramite`: `salud`, `tramites`, `educacion`, `empleo`

### 4. Escáner de documentos (`POST /api/scanner/analyze`)

```bash
curl -s -X POST http://localhost:8000/api/scanner/analyze \
  -F "perfil=senior" \
  -F "idioma=es" \
  -F "file=@ruta/a/tu/documento.jpg;type=image/jpeg"
```

Formatos permitidos: `image/jpeg`, `image/png`, `image/webp` (tamaño máximo: 10 MB).

## Pruebas automatizadas (`pytest`)

Ejecuta toda la suite unitaria e integración (sin llamadas externas a Gemini):

```bash
pytest -v
```

### Prueba opcional en vivo contra Gemini

Si deseas validar la integración real con tu `GEMINI_API_KEY` configurada en `.env`:

```powershell
# Windows PowerShell
$env:RUN_LIVE_GEMINI_TESTS="1"
pytest -v
```

```bash
# Linux / macOS
RUN_LIVE_GEMINI_TESTS=1 pytest -v
```

## Despliegue en Render (`Procfile`)

El proyecto incluye `BackEnd/Procfile` listo para Render:

```text
web: uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}
```

Al crear el Web Service en Render:
1. Configura **Root Directory** en `BackEnd`.
2. **Build Command**: `pip install -r requirements.txt`
3. **Start Command**: déjalo tomar el comando de `Procfile` o usa `uvicorn app.main:app --host 0.0.0.0 --port $PORT`.
4. Agrega en **Environment Variables**: `GEMINI_API_KEY` y `GEMINI_MODEL=gemini-2.5-flash`.
