# Guía de Integración Frontend (Flutter) — PasoClaro API

Documento de referencia para conectar la app **Flutter** con el backend FastAPI de **PasoClaro** (`BackEnd/`).

---

## 1. Autenticación y seguridad

- **Sin autenticación de usuario:** el backend **no** requiere tokens, API keys de cliente, cookies ni inicio de sesión en ninguno de sus endpoints.
- **CORS habilitado:** acepta solicitudes desde cualquier origen (`allow_origins=["*"]`, `allow_methods=["*"]`, `allow_headers=["*"]`).
- **Seguridad de `GEMINI_API_KEY`:** la llave de Google Gemini reside **únicamente** en `BackEnd/.env` (en desarrollo) o en las variables de entorno del servidor (Render). **Nunca** guardes, envíes ni compiles `GEMINI_API_KEY` dentro del proyecto Flutter.

---

## 2. `API_BASE_URL` por entorno

Configura una constante o variable de entorno (`--dart-define=API_BASE_URL=...`) sin barra diagonal `/` al final:

| Entorno de ejecución | `API_BASE_URL` | Notas |
| --- | --- | --- |
| **Emulador Android** | `http://10.0.2.2:8000` | `10.0.2.2` apunta al `localhost` de tu PC anfitriona. |
| **Flutter Web / Desktop / iOS Simulator** | `http://localhost:8000` | Conexión local directa. |
| **Celular físico (misma red Wi-Fi)** | `http://<IP_LOCAL>:8000` | Ejemplo: `http://192.168.1.50:8000`. Arranca uvicorn en `0.0.0.0:8000` y permite el puerto en el firewall. |
| **Producción (Render)** | `https://<servicio>.onrender.com` | Usa HTTPS en producción. |

> **Nota Android:** si pruebas con `http://` (tráfico claro en desarrollo local), asegúrate de permitir cleartext traffic en `AndroidManifest.xml` (`android:usesCleartextTraffic="true"` en debug).

---

## 3. Timeouts recomendados y resiliencia

Configura en Flutter timeouts ligeramente mayores a los límites internos del backend para dar margen al fallback determinista:

| Operación | Timeout en backend | Timeout recomendado en Flutter |
| --- | --- | --- |
| `GET /health`, `GET /api/guides`, `GET /api/guides/{guide_id}` | Inmediato (lectura local) | **5 s** (`Duration(seconds: 5)`) |
| `POST /api/assistant/chat` | `9.0 s` (`CHAT_TIMEOUT_SECONDS`) | **12 s** (`Duration(seconds: 12)`) |
| `POST /api/scanner/analyze` | `16.0 s` (`SCANNER_TIMEOUT_SECONDS`) | **20 s** (`Duration(seconds: 20)`) |

### Resiliencia automática del backend

- Si Gemini falla, excede su timeout interno o falta `GEMINI_API_KEY`, los endpoints `/api/assistant/chat` y `/api/scanner/analyze` **no devuelven error 500**: responden con **HTTP 200** usando un **fallback determinista** construido a partir de `knowledge_base.json` y `glossary.json`.
- En Flutter solo debes manejar excepciones de conectividad/timeout del cliente HTTP (`SocketException`, `TimeoutException`) y errores explícitos de entrada inválida (`400`, `404`, `422`).

---

## 4. Valores permitidos (Enums y catálogos)

Usa exactamente estos valores en minúsculas:

### `perfil` (`PerfilType`)
- `"senior"` — Adulto mayor (frases muy cortas, cálidas y pausadas para TTS).
- `"bilingual"` — Usuario bilingüe (redacción clara, directa y cotidiana).
- `"student"` — Estudiante (tono cercano y explicación simple de términos administrativos).
- `"offline"` — Ahorro de datos / resumen compacto y accionable.

### `idioma` (`IdiomaType`)
- `"es"` — Español.
- `"yua"` — Maya yucateco + español.
- `"nah"` — Náhuatl + español.

### `tramite` (`TramiteType`)
- `"salud"` — Mapea a la guía `"salud_cita_clinica"`.
- `"tramites"` — Mapea a la guía `"beca_apoyo_social"`.
- `"educacion"` — Mapea a la guía `"educacion_beca_escolar"`.
- `"empleo"` — Mapea a la guía `"empleo_servicio_nacional"`.

### `guia_id` devuelto por el escáner (`GuiaIdType`)
- `"salud_cita_clinica"`
- `"beca_apoyo_social"`

### IDs completos de guías disponibles en `/api/guides`
1. `"salud_cita_clinica"` — *Cita en Clínica Pública (Centro de Salud)* (`Oficial · Salud`)
2. `"beca_apoyo_social"` — *Solicitud de Beca o Apoyo* (`Oficial · Trámites`)
3. `"educacion_beca_escolar"` — *Orientación sobre Becas y Trámites Escolares* (`Oficial · Becas`)
4. `"empleo_servicio_nacional"` — *Búsqueda de Empleo y Bolsa de Trabajo Oficial* (`Oficial · Empleo`)

---

## 5. Contrato completo de endpoints

### 5.1 `GET /health`

Verifica que el servidor está activo.

- **Response `200 OK`:**
```json
{
  "status": "ok",
  "service": "pasoclaro-backend"
}
```

---

### 5.2 `POST /api/assistant/chat`

Asistente conversacional guiado según perfil, idioma, trámite y documentos completados.

- **Headers:** `Content-Type: application/json`
- **Request Body:**
```json
{
  "perfil": "senior",
  "idioma": "es",
  "tramite": "salud",
  "docs_completados": [
    "Identificación oficial vigente (INE, original y copia)"
  ],
  "mensaje": "¿Qué documentos me faltan para sacar cita en el centro de salud?"
}
```
  - `docs_completados`: opcional (`list[str]`, por defecto `[]`).
  - `mensaje`: obligatorio (`str`), se hace `.strip()` y no puede estar vacío ni contener solo espacios.

- **Response `200 OK`:**
```json
{
  "respuesta": "Para Cita en Clínica Pública (Centro de Salud), te falta preparar: CURP impresa reciente (gob.mx/curp); Comprobante de domicilio menor a 3 meses.",
  "etiqueta_oficial": "Oficial · Salud",
  "pregunta_siguiente": "Ya cuentas con CURP impresa reciente (gob.mx/curp)?",
  "respuestas_rapidas": [
    "Abrir mi lista paso a paso",
    "Escanear un documento",
    "Ver telefono oficial"
  ]
}
```
  - `respuestas_rapidas`: siempre contiene entre **2 y 3** opciones cortas.

- **Errores:**
  - `422 Unprocessable Entity`: `perfil`, `idioma` o `tramite` fuera de los valores permitidos, campo requerido faltante o `mensaje` vacío / solo espacios.

---

### 5.3 `POST /api/scanner/analyze`

Analiza una fotografía o imagen de un documento oficial mediante `multipart/form-data`.

- **Headers:** `Content-Type: multipart/form-data`
- **Form Fields:**
  - `perfil`: `senior` | `bilingual` | `student` | `offline` (obligatorio)
  - `idioma`: `es` | `yua` | `nah` (obligatorio)
  - `file`: archivo binario de imagen (obligatorio)
- **Restricciones de `file`:**
  - **Tamaño máximo:** `10 MB` (`10 * 1024 * 1024` bytes = `10485760` bytes).
  - **Formatos permitidos:** `image/jpeg`, `image/jpg`, `image/png`, `image/webp`. (Si el cliente envía `application/octet-stream` o MIME vacío, el backend acepta el archivo si el nombre termina en `.jpg`, `.jpeg`, `.png` o `.webp`).

- **Response `200 OK`:**
```json
{
  "tipo_documento": "Hoja de cita médica",
  "titulo_corto": "Cita en Centro de Salud",
  "explicacion": "Documento que confirma tu consulta médica. Lleva identificación oficial, CURP y comprobante de domicilio.",
  "fecha_limite": "15 de diciembre de 2026",
  "folio": "FOLIO-12345",
  "alerta_faltante": "Recuerda llevar tu CURP impresa reciente.",
  "guia_id": "salud_cita_clinica"
}
```
  - `alerta_faltante`: `string | null`.
  - `guia_id`: estrictamente `"salud_cita_clinica"` o `"beca_apoyo_social"`.

- **Errores:**
  - `400 Bad Request`:
    - `"Formato de imagen no válido. Solo se aceptan archivos JPG, PNG o WebP."`
    - `"El archivo enviado está vacío."`
    - `"La imagen supera el tamaño máximo permitido de 10 MB."`
  - `422 Unprocessable Entity`: falta `perfil`, `idioma` o `file`, o `perfil`/`idioma` inválido.

---

### 5.4 `GET /api/guides`

Devuelve todas las guías verificadas y el glosario intercultural completo (útil para caché offline en Flutter).

- **Response `200 OK`:**
```json
{
  "guides": [
    {
      "id": "salud_cita_clinica",
      "tramite": "salud",
      "titulo": "Cita en Clínica Pública (Centro de Salud)",
      "etiqueta_oficial": "Oficial · Salud",
      "requisitos": [
        "Identificación oficial vigente (INE, original y copia)",
        "CURP impresa reciente (gob.mx/curp)",
        "Comprobante de domicilio menor a 3 meses (alternativa si falta: constancia gratuita de vecindad en comisaría o municipio)"
      ],
      "pasos": [
        "Reúne tu identificación oficial vigente, tu CURP impresa reciente y tu comprobante de domicilio antes de acudir a la clínica."
      ],
      "canal_oficial": {
        "institucion": "Centro de Salud Urbano",
        "horario": "Lun–Vie 08:00 a 15:00 h",
        "telefono": "800 004 4800",
        "url": "https://www.gob.mx/salud",
        "nota": "Atención gratuita sin intermediarios"
      }
    }
  ],
  "glossary": [
    {
      "termino_es": "Identificación oficial (INE)",
      "yua": "U ju'unil k'ajóolal (INE)",
      "nah": "Amoxtli tlen mitzixmati (INE)",
      "explicacion_sencilla": "Credencial con foto vigente emitida por el gobierno que comprueba quién eres para hacer cualquier trámite."
    }
  ]
}
```
*(La respuesta real incluye las 4 guías oficiales y los 15 términos del glosario).*

---

### 5.5 `GET /api/guides/{guide_id}`

Devuelve el detalle de una guía específica por su identificador.

- **Response `200 OK`:** objeto de la guía (misma estructura que cada elemento de `guides` en `/api/guides`).
- **Errores:**
  - `404 Not Found`: `{"detail": "Guía no encontrada."}` cuando `guide_id` no existe.

---

### 5.6 Reglas de UI para Flutter

1. **Texto limpio listo para TTS:** el backend elimina automáticamente formato Markdown (`**`, `__`, `#`, backticks, viñetas `-`/`*`/`+`/`•`, enlaces) y emojis en todos los campos de texto de `/api/assistant/chat` y `/api/scanner/analyze`. Puedes pasar `respuesta`, `pregunta_siguiente` y `explicacion` directamente al motor de voz (`flutter_tts`).
2. **Formato bilingüe (`yua` y `nah`):** cuando `idioma` es `"yua"` o `"nah"`, el campo `respuesta` (chat) y `explicacion` (escáner) incluyen primero la explicación breve en lengua indígena y debajo, tras un salto de párrafo (`\n\n`), la explicación en español sencillo. Puedes renderizarlo en el mismo bloque o dividir por `\n\n` si deseas destacarlo visualmente.
3. **Palabras clave en `respuestas_rapidas`:** el asistente incluye chips con palabras clave accionables:
   - Si una opción contiene `"lista"` (ej. `"Abrir mi lista paso a paso"`), navega al checklist/guía del trámite actual.
   - Si una opción contiene `"escanear"` (ej. `"Escanear un documento"`), abre el flujo de cámara/escáner.
   - En cualquier otro caso, envía el texto del chip como nuevo `mensaje` al chat.
4. **Valores normalizados en escáner:** si la foto no muestra fecha límite o folio legibles, el backend devuelve literalmente:
   - `fecha_limite`: `"[por verificar]"`
   - `folio`: `"[sin folio]"`
   Úsalos en la UI para mostrar un aviso visual suave de verificación manual, y contempla que `alerta_faltante` puede venir como `null`.

---

## 6. Ejemplo en Dart (`package:http`)

Agrega `http: ^1.2.0` en tu `pubspec.yaml` (`http_parser` viene incluido como dependencia transitiva de `http`):

```dart
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PasoClaroApiClient {
  PasoClaroApiClient({String? baseUrl})
      : baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://10.0.2.2:8000',
            );

  final String baseUrl;

  Future<bool> checkHealth() async {
    final uri = Uri.parse('$baseUrl/health');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['status'] == 'ok';
  }

  Future<Map<String, dynamic>> getGuides() async {
    final uri = Uri.parse('$baseUrl/api/guides');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) {
      throw HttpException('Error ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendChat({
    required String perfil, // senior | bilingual | student | offline
    required String idioma, // es | yua | nah
    required String tramite, // salud | tramites | educacion | empleo
    required String mensaje,
    List<String> docsCompletados = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/api/assistant/chat');
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'perfil': perfil,
            'idioma': idioma,
            'tramite': tramite,
            'docs_completados': docsCompletados,
            'mensaje': mensaje,
          }),
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw HttpException('Error ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> analyzeDocument({
    required File imageFile,
    required String perfil, // senior | bilingual | student | offline
    required String idioma, // es | yua | nah
  }) async {
    final uri = Uri.parse('$baseUrl/api/scanner/analyze');
    final request = http.MultipartRequest('POST', uri)
      ..fields['perfil'] = perfil
      ..fields['idioma'] = idioma;

    final ext = imageFile.path.split('.').last.toLowerCase();
    final subtype = switch (ext) {
      'png' => 'png',
      'webp' => 'webp',
      _ => 'jpeg',
    };

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', subtype),
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 20));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw HttpException('Error ${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
```
