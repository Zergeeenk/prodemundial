# CLAUDE.md — Prode Mundialista BetArgento

Contexto del proyecto para retomarlo, desplegarlo o extenderlo con Claude Code.

## Qué es

Landing de un solo archivo (`prode-betargento.html`) donde un usuario carga su
pronóstico de los partidos de **Argentina en la fase de grupos del Mundial 2026**
(Grupo J). **Estética clara y minimal** (estilo app): fondo claro `#eef1f7`, tarjetas
blancas con borde fino, acento **azul** BetArgento, banderas reales en cuadraditos
redondeados. Se descartó el tema oscuro recargado (oro, confetti, reflectores, foto
de estadio, banderas en diagonal) por pedido del usuario: **"este estilo siempre,
con muchas cosas queda sobrecargado"**.

No mueve dinero ni procesa apuestas: es un juego de pronósticos sin valor monetario,
con aviso `+18 · Jugá responsable` en el pie.

## Stack

- **HTML + CSS + JS vanilla**, todo inline en un único archivo. Sin build, sin deps.
- Fuente: Google Fonts `Inter` (única; se sacó `Anton`).
- Persistencia: `localStorage` con fallback a un objeto en memoria si está bloqueado.
- Sin backend. Funciona abriendo el `.html` o subiéndolo a cualquier hosting estático.

## Estructura

```
prode-betargento.html   # única fuente de código; abrir directo en el navegador
Logo-bet.png            # logo BETARGENTO (header + pantalla de carga); contorno
                        #   negro, anda sobre fondo claro
Bandera Argentina.webp  # banderas reales (nombres con espacios → %20 al referenciar)
Bandera Argelia.jpg
Bandera austria.avif
jordania bandera.avif
Fondo.jpg / Fondo.avif  # foto de estadio del tema viejo; YA NO se usa (se puede borrar)
```

Todo el código vive en el `.html`: `<style>` en el `<head>`, markup del hero +
contenedor `#matches`, y un `<script>` IIFE al final que renderiza las tarjetas y
maneja estado. Las imágenes se cargan como assets relativos (mismo directorio).

## Datos de los partidos (Grupo J)

Definidos en el array `MATCHES` dentro del `<script>`. Fuente: fixture FIFA 2026.

| id | Partido               | Día                  | Hora (ARG) | Sede        | unlock        |
|----|-----------------------|----------------------|------------|-------------|---------------|
| m1 | Argentina vs Argelia  | Martes 16 de junio   | 22:00      | Kansas City | 16/06 00:00   |
| m2 | Argentina vs Austria  | Lunes 22 de junio    | 14:00      | Dallas      | 22/06 00:00   |
| m3 | Jordania vs Argentina | Sábado 27 de junio   | 23:00      | Kansas City | 27/06 00:00   |

Las banderas son **imágenes reales locales** (mapa `F` en el script): `Bandera
Argentina.webp`, `Bandera Argelia.jpg`, `Bandera austria.avif`, `jordania
bandera.avif` (nombres con espacios → se referencian con `%20`). Se muestran como
**cuadraditos redondeados** (`.flag`, `border-radius:13px`) arriba de cada equipo.
El fondo diagonal del tema viejo se eliminó.

**Orden en pantalla (alternado a pedido, NO sigue el local/visitante real):**
`home` = lado izquierdo, `away` = lado derecho. Argentina alterna izq/der/izq:

- m1: **Argentina** / Argelia
- m2: Austria / **Argentina** (espejado)
- m3: **Argentina** / Jordania

Como el orden visual no coincide con el local/visitante del fixture en m2 y m3,
cada match tiene `apiHomeLeft` (bool): indica si el "local" del evento de la API cae
a la izquierda en pantalla. `fetchResult` usa ese flag para poner cada marcador del
lado correcto (`h`=izquierda, `a`=derecha).

## Resultado real (TheSportsDB)

El prode se conecta al **resultado real** de cada partido sin backend, leyendo la API
gratuita de TheSportsDB desde el navegador (CORS habilitado):

- Endpoint: `searchevents.php?e=<evName>` con la clave de prueba `3`. Cada match
  tiene un campo `evName` (nombre del evento en inglés, ej. `Argentina_vs_Algeria`,
  `Jordan_vs_Argentina`) en el mismo orden home/away que la tarjeta.
- `fetchResult(m)` filtra el resultado por **liga + año**: `idLeague === '4429'`
  (FIFA World Cup) y `dateEvent` que empiece con `2026`. Devuelve `{h,a}` solo cuando
  `intHomeScore`/`intAwayScore` no están vacíos; si no, `null`.
- `checkResults()` corre al cargar y cada 90 s, para los partidos cuyo `kickoff` ya
  pasó. Cuando hay resultado, `showResult()` lo pinta y compara contra el pronóstico:
  **`exact`** (marcador exacto → badge azul lleno), **`win`** (acertó el ganador →
  badge azul claro) o **`miss`** (gris). `updateSummary()` actualiza `#summary`.
- **Congelado:** cada match tiene `kickoff` (hora del partido). `freezeTick()` (cada
  30 s) deshabilita los `+/-` cuando arranca el partido y muestra "Pronóstico cerrado
  · esperando resultado…". Es integridad best-effort (sin backend no se puede impedir
  que alguien borre su `localStorage`).
- **Bono + modal:** al acertar el **marcador exacto** (`cls==='exact'`) se muestra el
  banner `.bonus` ("Sacale captura y mandala al webchat") y salta la **ventana
  emergente** `#winModal` ("¡GANAMOS Y GANASTE! · 200% · +1500 fichas") vía `openWin()`.
  Cierra con `×`, click afuera o `Escape`. El link de ambos sale de la constante
  `BONUS_URL` (default `'#'`, cambiar por la URL del webchat/registro).

## Guardar / editar predicción

- Botón **por tarjeta** (`.savebtn`), no global. Al tocar "Guardar predicción" se setea
  `state[m].saved=true`, se **bloquean los `+/-`** (`setSteppers`) y el botón pasa a
  "✏️ Editar predicción" (`renderSaveBtn`). Tocar Editar revierte (`saved=false`).
- El flag `saved` se **persiste en `localStorage`** junto a `{h,a}`, así al recargar la
  predicción sigue bloqueada en modo Editar.
- **Botón demo** `#testbonus` ("🧪 Probar bono") simula un acierto exacto en el partido
  abierto (`showResult(m,{h,a}=pred)`) para previsualizar el bono/modal.
  **Quitar en producción** (está marcado en el código).

> ⚠️ **Gotcha de fechas:** TheSportsDB guarda `dateEvent` en **UTC**, así que los
> partidos de noche (hora ARG) figuran al día siguiente: Argentina-Argelia es
> `2026-06-17` y Jordania-Argentina `2026-06-28` en la API. Por eso el filtro usa
> **año**, no fecha exacta. No cambiar a comparar `dateISO` exacta o m1/m3 no matchean.

> Verificación: al 14/06/2026 los 3 fixtures existen en la API con score vacío y
> estado `NS`. El resultado real recién se puede ver cuando se juega cada partido.

## Lógica de desbloqueo

Función `isOpen(m)` decide si una tarjeta está abierta:

1. `?preview=1` en la URL → abre **todas** (para probar el diseño).
2. `m.forceOpen === true` → siempre abierta. **`m1` (debut) lo tiene en `true`.**
3. Si no, abre cuando `new Date() >= m.unlock` (medianoche local del día del partido).

Las tarjetas bloqueadas muestran un overlay `.lock` con candado y un **countdown**
(días/horas/min) que se refresca cada 30 s y recarga la página al llegar a cero.

> Nota: `m.unlock` usa hora **local del navegador**, no la hora de Argentina.
> Si se necesita anclar a `America/Argentina/Buenos_Aires`, calcular el unlock en
> UTC y comparar contra `Date.now()`.

## Diseño / tokens (tema claro)

Variables CSS en `:root`:

- `--bg #eef1f7` — fondo de página; `--card #ffffff` — tarjetas
- `--ink #16203a` — texto principal (navy); `--muted #8a94ac` — texto secundario
- `--line #e6eaf2` — bordes finos
- `--blue #1f5cff` (acento, CTA, Argentina), `--blue-dark #1147d8` (hover)
- `--blue-soft #eaf0ff` / `--blue-border #cfdcff` — fondos y bordes celestes (pills, badges)

Estética **minimal y clara**, sin animaciones decorativas. Tarjeta destacada
(`.featured`) solo se distingue con borde celeste + un pill "Ya disponible"; sin glow
ni barridos. Respeta `prefers-reduced-motion`.

**Tarjetas:** blancas, borde `--line`, `border-radius:16px`, sombra suave. Cada
`.card` tiene: pill destacado (solo m1), `.card-top` (`.matchday` + `.time` en
negrita), `.daymeta` (fecha · sede en gris), `.teams` (bandera cuadrada + nombre +
`.stepper` `− [score] +`) y el bloque `.result`.

**Pantalla de carga:** `#loader` (overlay claro `z-index:50`) con logo + spinner azul
+ "Cargando tu prode…". Se oculta (`.hide`) en el evento `load` con mínimo de 500 ms y
fallback a 4 s. Solo el logo va con `<link rel="preload">`.

## Cómo correr / desplegar

```bash
# local: abrir el archivo en el navegador, o servirlo
python3 -m http.server 8000     # luego http://localhost:8000/prode-betargento.html

# preview con todo desbloqueado
# http://localhost:8000/prode-betargento.html?preview=1
```

Deploy: subir el `.html` a Netlify, Vercel, GitHub Pages, S3 o el propio sitio de
BetArgento. No requiere nada más.

## Convenciones al editar

- Mantener **un solo archivo**, sin dependencias externas salvo Google Fonts.
- Colores siempre vía variables CSS (no hardcodear hex sueltos).
- Toda animación nueva tiene que quedar desactivada bajo `prefers-reduced-motion`.
- Números en pantalla redondeados (acá son enteros de goles, sin floats).
- Copys en español rioplatense, sentence case, sin prometer premios en dinero.

## Antes de publicar (producción)

- [ ] Poner la **URL real del webchat/registro** en `BONUS_URL` (hoy `'#'`).
- [ ] **Quitar el botón demo** `#testbonus` (HTML, CSS `.testbonus` y su handler JS).
- [ ] **Bases legales del bono** (200% + 1500 fichas): +18, términos y condiciones.

## Backlog / próximas tareas posibles

- [x] Banner/pieza "200% EXTRA" → hecho como bono al acertar + modal "GANAMOS Y GANASTE".
- [ ] Anclar `unlock`/`kickoff` a horario de Argentina (UTC) en vez de hora local.
- [ ] Sumar los cruces internos del Grupo J (Argelia-Austria, etc.) para prode completo.
- [ ] Botón "compartir" (Web Share API / copiar al portapapeles) del resumen del prode.
- [ ] Envío del prode a un backend/Sheet si se quiere recolectar participaciones.
- [ ] Avanzar a octavos/llaves si Argentina clasifica (nuevas tarjetas dinámicas).
