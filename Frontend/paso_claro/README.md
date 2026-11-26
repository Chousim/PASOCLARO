# PasoClaro — Frontend Móvil (Flutter)

**Tu puente multimodal hacia trámites, salud, educación y apoyos sin barreras** *(Reto 1 · Puentes de oportunidad — ODS 10)*.

Aplicación móvil ligera y accesible en Flutter que funciona como acompañante ciudadano (voz, texto y cámara), conectada a un backend FastAPI + Google Gemini y diseñada para operar también **100 % sin internet** en comunidades con baja conectividad.

---

## Funcionalidades principales

- **Bienvenida en 2 toques (sin registro ni formularios):** Adaptación inmediata a 4 perfiles (*Adultos mayores*, *Guías bilingües*, *Paso a paso* y *Modo sin internet*).
- **4 Caminos Claros y Modo Adultos Mayores:** Inicio adaptado con tipografía extra grande (`20px+`), alto contraste WCAG AAA y navegación en una sola columna para adultos mayores.
- **Asistente Conversacional Guiado (Voz y Chat):** Respuestas breves en español sencillo impulsadas por Gemini, lectura en voz alta con velocidad pausada (`flutter_tts`) y dictado por voz (`speech_to_text`).
- **Escáner Multimodal de Documentos:** Fotografía recetas médicas, hojas de referencia o convocatorias para extraer fecha límite, folio, explicación clara y requisitos faltantes.
- **Guías Bilingües y Checklist Offline:** Tarjetas de dos bandas en **maya yucateco** y **náhuatl** + español sencillo (estrictamente solo texto por respeto fonético), palomeo guardado localmente en el teléfono, *Detector de Huecos* y *Canal Oficial Verificado*.

---

## Estructura del proyecto (`lib/`)

```text
lib/
├── main.dart                     # Punto de entrada y navegación adaptativa
├── domain/models/                # Modelos de dominio (perfiles, idiomas, guías, chat, escáner)
├── data/
│   ├── services/                 # Cliente FastAPI, almacenamiento local y voz en español
│   └── repositories/             # Guías verificadas offline y repositorio principal
└── ui/
    ├── core/                     # Paleta WCAG AAA, ThemeData (Estándar y Adultos Mayores), estado global
    └── features/                 # onboarding, home, assistant, scanner y checklist
```

---

## Cómo ejecutar y compilar

### Requisitos
- Flutter SDK (`3.x` / Dart `^3.14.0`)
- Dispositivo Android físico o emulador

### 1. Instalar dependencias
```powershell
flutter pub get
```

### 2. Correr en desarrollo
Por defecto la app se conecta al backend desplegado en Render (`https://pasoclaro.onrender.com`), sin guardar ninguna llave de API en el código móvil (`GEMINI_API_KEY` vive únicamente en el servidor).

```powershell
flutter run
```

Para apuntar a un servidor local en desarrollo:
```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### 3. Generar APK de producción (Android)
```powershell
flutter build apk --release
```
El APK generado se encuentra en `build/app/outputs/flutter-apk/app-release.apk`.

### 4. Validar pruebas
```powershell
flutter analyze
flutter test
```
