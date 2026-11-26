# PasoClaro — Documentación Básica (Hackatón UVM Ingenio Incluyente)

**Reto:** Reto 1 · Puentes de oportunidad (Reducción de la brecha de acceso — ODS 10)  
**Equipo:** Carlos Ysidro Junco Vázquez, José Ángel León Cortés y Fidel Ernesto Jacinto Pérez  
**Repositorio:** https://github.com/Chousim/PASOCLARO.git  
**Bocetos y Wireframes (Stitch):** https://stitch.google.com/projects/7125630527258665541

---

## 1. Resumen ejecutivo

**PasoClaro** es una aplicación móvil ligera y accesible que actúa como un acompañante inteligente por voz, texto y cámara para traducir y simplificar trámites complejos de salud, educación, empleo y apoyos sociales en guías paso a paso disponibles sin conexión a internet. Está diseñada para adultos mayores, comunidades indígenas, migrantes, estudiantes de primera generación y personas en zonas con baja conectividad. Su innovación radica en combinar lectura multimodal de documentos oficiales, detección previa de requisitos faltantes y tarjetas bilingües escritas en lenguas originarias (maya yucateco y náhuatl) con español sencillo e íconos visuales.

---

## 2. Boceto y concepto

### El problema
La información oficial sobre trámites, servicios de salud, becas y apoyos sociales suele estar dispersa, escrita con jerga legal o médica y pensada para personas con alta alfabetización digital. Esta barrera deja fuera de derechos y oportunidades básicas a adultos mayores, hablantes de lenguas indígenas, población migrante, estudiantes de primera generación y habitantes de comunidades con conectividad intermitente, quienes abandonan procesos o pierden apoyos por no comprender los requisitos.

### Propuesta de solución
**PasoClaro** funciona como un traductor y guía personal entre el ciudadano y las instituciones públicas. Mediante una configuración inicial de dos toques o por voz, la aplicación adapta su interfaz al perfil de la persona, escucha sus dudas o lee fotografías de documentos oficiales, identifica qué papeles le faltan antes de acudir a una ventanilla y guarda un checklist paso a paso en el teléfono para consultarlo sin gastar datos móviles.

### Boceto de experiencia y flujo principal
* **Prototipo visual (Wireframes):** Diseñado en Stitch (https://stitch.google.com/projects/7125630527258665541).
* **Pantalla 1 — Selección rápida de perfil e idioma:** Botones grandes de alto contraste o activación por micrófono para elegir perfil (adulto mayor, comunidad indígena, migrante, estudiante de primera generación o modo ahorro de datos/offline) y lengua.
* **Pantalla 2 — Cuatro caminos claros:** Acceso visual mediante íconos grandes a **Salud**, **Trámites y Apoyos**, **Educación y Becas** y **Empleo** (con enfoque inicial del MVP en **Salud** y **Trámites**).
* **Pantalla 3 — Asistente y escáner:** Espacio para preguntar hablando o escribiendo, o tomar foto a una receta, citatorio o convocatoria.
* **Pantalla 4 — Guía paso a paso y checklist offline:** Lista verificable de requisitos con íconos, tarjetas bilingües (cuando aplica) y datos oficiales de contacto.

### Alineación con los ODS 10 y 11
* **ODS 10 (Reducción de las desigualdades):** Elimina barreras lingüísticas, digitales y burocráticas para que poblaciones históricamente desatendidas comprendan y ejerzan sus derechos en igualdad de condiciones, promoviendo la inclusión social y el acceso equitativo a servicios públicos.
* **ODS 11 (Ciudades y comunidades sostenibles):** Facilita que personas vulnerables y habitantes de zonas periféricas o rurales accedan de forma efectiva a los servicios básicos de su entorno (clínicas públicas, oficinas de atención y programas sociales), evitando viajes innecesarios y fortaleciendo la resiliencia comunitaria.
  * **Meta 11.1:** Asegurar el acceso universal de todas las personas a servicios básicos adecuados y asequibles.
  * **Meta 11.a:** Apoyar los vínculos económicos, sociales y ambientales positivos entre las zonas urbanas, periurbanas y rurales mediante una mejor conexión de la población con los servicios institucionales.

---

## 3. Documentación funcional

1. **Onboarding adaptativo (2 toques o por voz):** Configura el tamaño de letra, contraste, idioma y nivel de explicación desde la primera pantalla sin formularios largos.
2. **Navegación por 4 caminos claros:** Organiza la orientación en **Salud**, **Trámites y Apoyos**, **Educación y Becas** y **Empleo**, priorizando en el MVP los flujos de salud y trámites públicos.
3. **Asistente conversacional guiado (voz y texto):** Responde consultas en español con frases cortas, lenguaje cotidiano y lectura en voz alta pausada, proponiendo siempre una pregunta concreta para avanzar.
4. **Escáner multimodal de documentos oficiales:** Permite fotografiar recetas médicas, hojas de referencia, volantes o convocatorias para extraer datos clave, identificar fechas límite y explicar su contenido en palabras simples.
5. **Tarjetas bilingües en lenguas originarias (solo texto):** Genera guías escritas en formato bilingüe (**maya yucateco** o **náhuatl** en la parte superior y **español sencillo** en la parte inferior) acompañadas de íconos visuales de cada requisito, evitando errores de pronunciación de los lectores de voz convencionales.
6. **Detector de huecos y checklist interactivo offline:** Verifica qué documentos ya tiene el usuario, alerta sobre los faltantes, explica cómo obtenerlos y guarda la lista palomeable en el almacenamiento local del teléfono para consulta sin internet.
7. **Canalización oficial verificable:** Muestra al final de cada guía los enlaces gubernamentales, teléfonos y ubicaciones reales de atención para evitar intermediarios o sitios falsos.

---

## 4. Documentación técnica

### Arquitectura general
La solución sigue una arquitectura cliente-servidor ligera y sin estado (*stateless*) orientada a resiliencia en baja conectividad:
* **Cliente móvil:** Gestiona la accesibilidad visual, captura de audio e imágenes, renderizado de tarjetas y persistencia local para operar sin internet una vez generada la guía.
* **Backend orquestador:** Recibe la consulta junto con un contexto ligero de sesión, lee los requisitos oficiales desde archivos locales estructurados y ejecuta una única llamada hacia la API de Gemini.
* **Estrategia lingüística en una sola llamada:** Para el piloto en lenguas originarias (maya yucateco y náhuatl), Gemini realiza la simplificación semántica y la traducción escrita apoyándose en un mini glosario validado de términos institucionales (basado en glosarios del INALI y guías interculturales de salud), sin depender de motores externos de síntesis de voz ni servicios adicionales de traducción.

### Stack tecnológico
* **Frontend móvil:** Flutter (interfaz de alto contraste, tipografía escalable, reconocimiento y síntesis de voz en español, cámara y almacenamiento local con **SQLite / Hive**).
* **Backend / API:** Python con **FastAPI**, desplegado en **Render**.
* **Motor de Inteligencia Artificial:** **Gemini API** (capacidades multimodales para audio e imagen, simplificación de lenguaje, traducción controlada con glosario y *Structured Outputs* en JSON).
* **Gestión de datos (Arquitectura *Stateless*):** El servidor en Render opera sin base de datos externa; consulta archivos **JSON estáticos** con los requisitos oficiales verificados para garantizar latencia mínima y cero fallos de conexión, mientras que toda la persistencia de guías y checklists ocurre localmente en el dispositivo móvil.

### Integración de Gemini en el flujo de la aplicación
1. **Entrada de datos:** La app en Flutter envía al backend el audio, texto o fotografía del documento junto con un objeto JSON ligero de contexto (`{perfil, idioma, nivel_lectura, tramite, docs_completados}`).
2. **Enriquecimiento con contexto oficial:** FastAPI recupera los requisitos verificados desde sus archivos JSON estáticos y adjunta el *system prompt* con reglas de lenguaje claro y el mini glosario validado en maya yucateco y náhuatl.
3. **Procesamiento multimodal y salida estructurada:** Gemini interpreta el documento o consulta, detecta requisitos faltantes y devuelve una respuesta estricta en **JSON (*Structured Outputs*)** con los pasos ordenados, textos bilingües, identificadores de íconos y enlaces oficiales.
4. **Caché local offline:** Flutter renderiza las tarjetas interactivas y almacena el JSON resultante en el dispositivo para que el usuario pueda consultar y marcar su checklist sin conexión.

---

## 5. Manual de usuario

### Paso 1: Instalar y abrir la aplicación
1. Descarga el archivo instalador (**APK**) de **PasoClaro** en tu teléfono Android desde `[PENDIENTE: Enlace de descarga del APK — se publicará en la Fase 3]` y ábrelo para instalar la aplicación (si tu teléfono solicita permiso para instalar aplicaciones externas, acéptalo).
2. Toca el ícono de **PasoClaro** en la pantalla de tu teléfono para abrirla. No necesitas crear una cuenta ni recordar contraseñas.

### Paso 2: Elegir cómo quieres que te ayude
1. En la primera pantalla verás botones grandes. Toca la opción que mejor se adapte a ti (por ejemplo: **Letra grande y voz**, **Lengua indígena**, **Otro idioma** o **Ahorro de datos**).
2. Si lo prefieres, toca el botón grande del **micrófono** y di con tus propias palabras qué necesitas.

### Paso 3: Elegir el tema de tu consulta
Toca uno de los **4 botones principales** en la pantalla de inicio:
* **Salud:** Para saber cómo sacar una cita médica, dónde atenderte o entender una receta.
* **Trámites y Apoyos:** Para conocer requisitos de documentos oficiales o programas sociales.
* **Educación y Becas:** Para entender cómo inscribirte o pedir una beca paso a paso.
* **Empleo:** Para recibir orientación básica sobre búsqueda de trabajo.

### Paso 4: Preguntar o tomar foto a un documento
Dentro del tema elegido tienes tres formas de pedir ayuda:
* **Hablando:** Mantén presionado el botón del micrófono, haz tu pregunta en voz alta y suéltalo para escuchar y leer la respuesta.
* **Escribiendo:** Escribe tu duda en el cuadro de texto y toca **Enviar**.
* **Con la cámara:** Toca el botón de **Tomar foto**, apunta hacia tu receta médica, hoja de cita o folleto y toma la fotografía. La aplicación te explicará qué dice el papel y qué fechas son importantes.

### Paso 5: Revisar qué te falta y guardar tu lista sin internet
1. La aplicación te hará preguntas cortas para revisar qué papeles ya tienes en casa y te avisará si te falta alguno y dónde conseguirlo.
2. Verás una **lista de pasos con dibujos** (como tu identificación, CURP o receta). Si elegiste una lengua indígena, verás las instrucciones escritas en tu lengua arriba y en español sencillo abajo.
3. Toca cada cuadro para marcar los documentos que ya juntaste. Esta lista se guarda automáticamente en tu teléfono: **puedes volver a abrirla aunque no tengas señal ni saldo de internet** mientras vas camino a tu cita o estás en la fila.
4. Al final de la lista encontrarás los teléfonos, direcciones o páginas oficiales reales a donde debes acudir.

---

## 6. Accesibilidad e impacto

### Características de accesibilidad
* **Diseño sin fricción:** Inicio en dos toques o mediante voz, sin registros complejos ni formularios extensos.
* **Adaptación visual y auditiva:** Tipografía extra grande, paleta de alto contraste y lectura en voz alta pausada en español para adultos mayores o personas con baja visión.
* **Lenguaje claro:** Traducción de términos médicos, legales y administrativos a explicaciones cotidianas aptas para cualquier nivel de lectura.
* **Pertinencia cultural y lingüística:** Tarjetas escritas bilingües (piloto en maya yucateco y náhuatl + español sencillo) acompañadas de íconos universales que permiten la lectura directa o el acompañamiento de familiares y promotores comunitarios, evitando distorsiones fonéticas.
* **Disponibilidad sin internet:** Almacenamiento local de guías y checklists para funcionar en comunidades rurales, transporte o edificios públicos sin señal.

### Impacto esperado
* **Mayor comprensión:** Incrementar el porcentaje de personas que identifican correctamente todos los documentos requeridos antes de iniciar un trámite.
* **Ahorro de tiempo y recursos:** Reducir el tiempo necesario para entender una convocatoria o proceso frente a la lectura directa de portales oficiales, evitando vueltas innecesarias en ventanilla.
* **Inclusión efectiva:** Permitir que personas sin experiencia digital ni conocimiento previo de la burocracia completen su preparación mediante voz, fotografías o tarjetas bilingües, conectándolas únicamente con canales institucionales verificados.