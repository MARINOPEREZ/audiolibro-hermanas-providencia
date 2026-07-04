# 📖 Audiolibro y PDF de libros

Herramienta web autónoma (un solo archivo HTML, sin instalación ni servidor) que convierte **fotos de las páginas de un libro** en:

- 📄 **PDF** ordenado y enderezado
- 📝 **Transcripción** automática (OCR en español, en tu navegador)
- 🎧 **Audiolibro**: lectura en voz alta con las voces de tu equipo, y **MP3 descargable**
- 🎞 **Presentación PowerPoint narrada**: una diapositiva por página, con audio que avanza al ritmo de la lectura

Todo se procesa **en tu navegador** — las imágenes y audios nunca salen de tu equipo. Solo se necesita internet la primera vez, para descargar los motores (OCR ~15 MB, voz ~2 MB) desde CDN públicos.

## 🚀 Usar en línea (GitHub Pages)

Abre la página publicada del proyecto (Settings → Pages de este repositorio) y listo. El libro de muestra **"EL PROYECTO de las Hermanas de la Providencia"** ya viene cargado para escuchar.

## 💻 Usar sin internet (local)

1. Descarga este repositorio (**Code → Download ZIP**) y descomprímelo.
2. Abre `index.html` con doble clic (Chrome o Edge).
3. La lectura del libro de muestra y la generación de PDF funcionan sin conexión; OCR y MP3 requieren internet solo la primera vez.

## 📚 Convertir un libro nuevo

1. Fotografía las páginas en orden (una foto por página o por doble página).
2. Pestaña **"Imágenes → PDF"**: carga las fotos, ordénalas o gíralas si hace falta, escribe el nombre del libro y pulsa **⚙ Generar PDF**. La transcripción se crea sola (OCR) y el libro queda listo para escuchar.
3. Pestaña **"Audiolibro"**: pulsa ▶ para escuchar, **⬇ Descargar MP3** para el audio, o **🎞 Generar PPT** para la presentación narrada. Si arrastras un MP3 del libro sobre la ventana antes de pulsar 🎞, ese audio se segmenta automáticamente por diapositiva.

## 🎙 Voz natural de Windows (opcional)

Para que el MP3 suene con la voz de Windows (p. ej. *Microsoft Helena*):

1. Arrastra el `.txt` del libro sobre **`Crear MP3 con voz de Windows.bat`** (una sola vez por libro).
2. El MP3 queda en la carpeta del libro y el botón **⬇ Descargar MP3** entregará esa versión automáticamente.
3. El mismo `.bat` acepta un *guion por diapositivas* (con marcas `### DIAPOSITIVA N ###`) para crear un audio por diapositiva.

> Requiere Windows con una voz de escritorio en español instalada (Configuración → Hora e idioma → Voz).

## 📁 Estructura

```
index.html                          ← el programa completo (autocontenido)
Crear MP3 con voz de Windows.bat    ← voz de Windows → MP3 (arrastrar el .txt)
Crear MP3 con voz de Windows.ps1
<Carpeta de cada libro>/            ← fotos + PDF + .txt + .mp3 del libro
```

La estructura importa: el programa busca el MP3 de cada libro en `NombreDelLibro/NombreDelLibro.mp3`, junto al `index.html`.

## ⚖️ Contenido y derechos

El código de esta herramienta es libre (licencia MIT). Los libros de muestra — *EL PROYECTO de las Hermanas de la Providencia* y *Oremos con Juan Martín Moyë* (textos de Juan Martín Moye, 1730–1793, edición de las Hermanas de la Providencia, Medellín) — se incluyen con fines devocionales y de demostración; sus derechos pertenecen a la congregación editora. Si representas a la editora y deseas que se retiren, se hará de inmediato.

## 🛠 Tecnología

HTML/JS puro en un solo archivo. Motores cargados por CDN al usarse: Tesseract.js (OCR español), meSpeak (síntesis espeak WASM), lamejs (codificador MP3), JSZip (ensamblado del PPTX con audio embebido y avance automático por diapositiva). Sin frameworks, sin servidor, sin telemetría.
