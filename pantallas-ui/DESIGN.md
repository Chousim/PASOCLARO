---
name: PasoClaro
colors:
  surface: '#fbf8fc'
  surface-dim: '#dcd9dd'
  surface-bright: '#fbf8fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f2f7'
  surface-container: '#f0edf1'
  surface-container-high: '#eae7eb'
  surface-container-highest: '#e4e1e6'
  on-surface: '#1b1b1e'
  on-surface-variant: '#3f4946'
  inverse-surface: '#303033'
  inverse-on-surface: '#f3f0f4'
  outline: '#6f7975'
  outline-variant: '#bfc9c4'
  surface-tint: '#24695b'
  primary: '#004439'
  on-primary: '#ffffff'
  primary-container: '#135d4f'
  on-primary-container: '#90d3c1'
  inverse-primary: '#90d4c2'
  secondary: '#57605f'
  on-secondary: '#ffffff'
  secondary-container: '#d6dfdd'
  on-secondary-container: '#5a6361'
  tertiary: '#612c20'
  on-tertiary: '#ffffff'
  tertiary-container: '#7d4235'
  on-tertiary-container: '#ffb4a3'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#acf0dd'
  primary-fixed-dim: '#90d4c2'
  on-primary-fixed: '#00201a'
  on-primary-fixed-variant: '#005143'
  secondary-fixed: '#dbe4e2'
  secondary-fixed-dim: '#bfc8c7'
  on-secondary-fixed: '#151d1c'
  on-secondary-fixed-variant: '#404847'
  tertiary-fixed: '#ffdad3'
  tertiary-fixed-dim: '#ffb4a4'
  on-tertiary-fixed: '#380d05'
  on-tertiary-fixed-variant: '#6f372a'
  background: '#fbf8fc'
  on-background: '#1b1b1e'
  surface-variant: '#e4e1e6'
typography:
  headline-lg:
    fontFamily: Outfit
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.025em
  headline-md:
    fontFamily: Outfit
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Outfit
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  title-lg:
    fontFamily: Outfit
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-medium:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  label-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 20px
  label-meta:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-status:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Marca y estilo

Este sistema de diseño establece una claridad cívica luminosa y natural para una aplicación móvil accesible de acompañamiento ciudadano. Pensada para personas que gestionan servicios municipales, programas de apoyo público y trámites ciudadanos, la interfaz prioriza la legibilidad serena, la dignidad y la comprensión sin esfuerzo por encima de los adornos decorativos.

La estética combina el **minimalismo** con la precisión **corporativa y moderna**: amplios espacios en blanco, límites estructurales nítidos y tipografía de alto contraste crean una experiencia cercana pero confiable. Cada interacción está fundamentada en la accesibilidad WCAG AAA —áreas táctiles amplias, jerarquía visual clara y estados activos inconfundibles— para que cualquier persona, sin importar sus capacidades, pueda completar sus trámites con seguridad.

- **Tono visual:** Luminoso, sobrio y transparente. Sin emojis, sin negro puro (`#000000`) y sin tonos morados ni resplandores neón.
- **Iconografía:** Íconos lineales monocromáticos limpios con un grosor de trazo uniforme de `2px`.

## Colores

La paleta se apoya en tonos neutros cálidos y luminosos junto con un verde botánico profundo de carácter cívico, diseñados para cumplir con las relaciones de contraste WCAG AAA sin recurrir a la dureza del negro puro.

- **Lienzo y superficies:**
  - **Lienzo Alabastro (`#FAFAFA`):** Fondo principal de la aplicación.
  - **Superficie Papel Puro (`#FFFFFF`):** Superficie elevada para tarjetas y contenedores, acompañada de un Borde Susurro de `1px` (`#E4E4E7`).
  - **Superficie Piedra Suave (`#F4F4F5`):** Superficie secundaria para contenedores hundidos, campos de entrada y agrupaciones sutiles.
- **Acento principal:**
  - **Jade Agave (`#135D4F`):** Reservado para botones principales de llamada a la acción (CTA), anillos de selección activa y rellenos del ícono de micrófono.
  - **Niebla de Agave (`#ECF5F3`):** Superficie con tinte suave para tarjetas seleccionadas y estados de opciones activas.
- **Tipografía y bordes:**
  - **Tinta Carbón (`#18181B`):** Color principal de texto, que ofrece una lectura nítida sobre superficies claras sin usar negro puro.
  - **Carbón Pizarra (`#3F3F46`) y Grafito Secundario (`#52525B`):** Jerarquía de texto secundario y de apoyo.
  - **Borde Susurro (`#E4E4E7`):** Líneas estructurales finas de `1px` para tarjetas y divisores.

## Tipografía

El sistema tipográfico combina claridad geométrica con ritmos de lectura relajados y accesibles. Todos los encabezados van alineados a la izquierda con un espaciado entre letras compacto, mientras que el cuerpo de texto mantiene un tamaño mínimo de `16px` y un interlineado amplio para facilitar la lectura rápida.

- **Encabezados (`Outfit`):** Pesos SemiBold (`600`) y Bold (`700`) con espaciado entre letras negativo y compacto (`-0.01em` a `-0.025em`) para establecer una jerarquía clara sin ruido visual.
- **Cuerpo de texto (`Geist`):** Pesos Regular (`400`) y Medium (`500`) en `16px` y `18px` con interlineados amplios (`1.5x` a `1.625x`) que garantizan una lectura cómoda en pantallas móviles.
- **Estados y metadatos (`JetBrains Mono`):** Se usa exclusivamente para marcas de tiempo, números de folio o expediente, indicadores de paso e insignias de estado, diferenciando los metadatos del sistema del contenido narrativo.

## Retícula y espaciado

Este sistema de diseño utiliza una **retícula fluida *mobile-first*** que se adapta con limpieza a distintos tamaños de pantalla, conservando amplios márgenes de respiro y áreas táctiles predecibles.

- **Móvil (`< 640px`):** Retícula fluida de 1 o 4 columnas con márgenes exteriores de `1.25rem` (`20px`) y medianiles (*gutters*) de `1rem` (`16px`). El contenido se apila verticalmente con un ritmo de `1rem` a `1.5rem` entre tarjetas.
- **Tableta (`640px – 1024px`):** Retícula fluida de 8 columnas con márgenes de `1.5rem` (`24px`) y medianiles de `1rem` (`16px`). Las tarjetas relacionadas pueden agruparse en filas de 2 columnas.
- **Escritorio (`> 1024px`):** Retícula fluida centrada de 12 columnas con un ancho máximo cómodo para lectura (`720px` para flujos de trámites enfocados y `1120px` para vistas generales de tablero) con márgenes de `2rem` (`32px`).

## Elevación y profundidad

La profundidad se transmite mediante **contornos de bajo contraste** combinados con **sombras ambientales sutiles**, manteniendo la interfaz asentada y similar al papel en lugar de flotante.

- **Tarjetas principales:** Superficie Papel Puro (`#FFFFFF`) sobre Lienzo Alabastro (`#FAFAFA`), delimitadas por un Borde Susurro nítido de `1px` (`#E4E4E7`) y una sombra ambiental suave y difusa (`0 4px 16px -2px rgba(24, 24, 27, 0.05)`).
- **Superficies hundidas:** La Superficie Piedra Suave (`#F4F4F5`) se asienta plana sobre el lienzo sin sombra para indicar regiones secundarias o agrupadas.
- **Estados activos y seleccionados:** Las tarjetas seleccionadas cambian a un relleno Niebla de Agave (`#ECF5F3`) con un anillo de selección Jade Agave (`#135D4F`) de `2px`, sustituyendo la elevación por sombra con un enfoque cromático claro.

## Formas

El lenguaje de formas es cercano y táctil, equilibrando contenedores suaves y acogedores con controles interactivos bien estructurados.

- **Tarjetas y contenedores:** Radio de borde de `24px` (`1.5rem`, `rounded-xl`) para todas las tarjetas principales, hojas modales y paneles agrupados.
- **Botones y controles interactivos:** Radio de borde de `16px` (`1rem`, `rounded-lg`) para botones planos táctiles, campos de texto y filas seleccionables en listas.
- **Metadatos e insignias:** Radio de borde de `8px` (`0.5rem`) para chips compactos de estado y etiquetas de metadatos en `JetBrains Mono`.

## Componentes

Todos los componentes están diseñados para cumplir con la accesibilidad WCAG AAA, incorporando estados de alto contraste, anillos de enfoque inconfundibles y áreas táctiles amplias.

- **Botones:** Botones planos táctiles con una altura mínima de `52px` y radio de borde de `16px`. Los botones principales (CTA) usan relleno Jade Agave (`#135D4F`) con texto Papel Puro (`#FFFFFF`) en `Geist` Medium. Los botones secundarios usan relleno Piedra Suave (`#F4F4F5`) con texto Tinta Carbón (`#18181B`) y un Borde Susurro de `1px` (`#E4E4E7`).
- **Tarjetas:** Superficie Papel Puro (`#FFFFFF`), radio de borde de `24px`, Borde Susurro de `1px` (`#E4E4E7`) y margen interno (*padding*) de `1.5rem` (`24px`). Las tarjetas seleccionadas usan relleno Niebla de Agave (`#ECF5F3`) con un borde Jade Agave (`#135D4F`) de `2px`.
- **Campos de entrada:** Altura mínima de `52px`, radio de borde de `16px`, fondo Piedra Suave (`#F4F4F5`) o Papel Puro (`#FFFFFF`) con un Borde Susurro de `1px` (`#E4E4E7`). Al enfocarse (estado activo), muestran un anillo Jade Agave (`#135D4F`) de `2px`.
- **Chips e insignias de estado:** Cápsulas compactas en `JetBrains Mono` (`12px`–`13px`) para el estatus del trámite, fechas límite o conteo de pasos. Los chips activos usan fondo Niebla de Agave (`#ECF5F3`) con texto Jade Agave (`#135D4F`).
- **Listas y filas de selección:** Filas de ancho completo con altura mínima de `56px`, margen interno de `16px` e íconos lineales monocromáticos de `2px`.
- **Casillas de verificación y botones de opción (*radio buttons*):** Áreas visuales de `24px × 24px` (envueltas en un contenedor táctil mínimo de `48px`) con bordes de `2px`; los estados marcados se rellenan con Jade Agave (`#135D4F`) y un indicador blanco nítido.
- **Acción de voz / micrófono:** Un botón táctil dedicado o disparador flotante de al menos `52px` con un ícono de micrófono de trazo de `2px` relleno en Jade Agave (`#135D4F`) cuando está activo.
```[cite: 1]