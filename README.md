# C2K — CleanToKeyboard for Mac

> **Limpia tu teclado sin miedo.** C2K bloquea completamente el teclado de tu Mac durante un timer configurable para que puedas limpiarlo con calma — sin comandos accidentales, sin sustos.

<br>

## ¿Cómo funciona?

C2K vive en tu **barra de menú** (sin icono en el Dock). Cuando quieras limpiar tu teclado:

1. Click en el ícono ⌨️ en la barra de menú
2. Selecciona **"Limpiar teclado"**
3. Aparece un panel flotante con el timer en cuenta regresiva
4. **El teclado queda 100% bloqueado** — el mouse sigue funcionando con normalidad
5. Cuando termines, haz click en **"Terminado"** o espera que el timer llegue a cero
6. Suena un beep y el teclado se desbloquea automáticamente

<br>

## Características

| | |
|---|---|
| 🔒 **Teclado bloqueado al 100%** | Intercepta todas las teclas a nivel de sistema con CGEventTap |
| 🖱️ **Mouse siempre activo** | Puedes seguir usando el trackpad o mouse normalmente |
| ⏱️ **Timer configurable** | De 1 a 10 minutos — tú decides cuánto tiempo |
| 🔔 **Beep al terminar** | Sonido de aviso cuando el teclado se desbloquea |
| 🎨 **UI minimalista dark** | Panel flotante compacto, no cubre toda la pantalla |
| 💾 **Preferencias persistentes** | Recuerda tu duración preferida entre sesiones |
| 🚫 **Sin icono en el Dock** | App de barra de menú pura, no estorba |

<br>

## Requisitos

- macOS **13 Ventura** o superior
- Permiso de **Accesibilidad** (se solicita automáticamente la primera vez)

<br>

## Instalación

### Opción A — Compilar desde código fuente (recomendado)

Necesitas tener **Xcode Command Line Tools** instalado.

```bash
# 1. Clonar el repositorio
git clone https://github.com/fernamoreno10-cyber/C2K-MAC.git
cd C2K-MAC

# 2. Compilar y crear el .app
bash scripts/build-app.sh

# 3. Lanzar
open C2K.app
```

El script hace todo automáticamente:
- Compila en modo release
- Ensambla el bundle `C2K.app`
- Firma con ad-hoc codesign
- Listo para usar

---

### Opción B — Descargar el .app (si hay Release disponible)

1. Ve a la sección [**Releases**](https://github.com/fernamoreno10-cyber/C2K-MAC/releases) de este repositorio
2. Descarga `C2K.app.zip` de la última versión
3. Descomprime y arrastra `C2K.app` a tu carpeta **Aplicaciones**
4. Doble click para abrir

> **Nota:** Como la app no está firmada con una cuenta de desarrollador de Apple, macOS puede mostrar un aviso la primera vez. Para abrirla: click derecho → **Abrir** → **Abrir de todas formas**.

<br>

## Primer uso

La primera vez que hagas click en **"Limpiar teclado"**, macOS te pedirá permiso de Accesibilidad:

1. Se abre automáticamente **Ajustes del Sistema**
2. Ve a **Privacidad y Seguridad → Accesibilidad**
3. Activa el switch de **C2K**
4. Vuelve a hacer click en "Limpiar teclado"

Este permiso es necesario para que el bloqueo de teclado funcione a nivel de sistema. Solo se pide una vez.

<br>

## Configurar la duración

1. Click en ⌨️ en la barra de menú
2. Selecciona **"Configurar..."**
3. Arrastra el slider entre **1 y 10 minutos**
4. Click en **"Listo"**

La preferencia se guarda automáticamente.

<br>

## Estructura del proyecto

```
C2K-MAC/
├── Sources/
│   ├── KeyboardCleaner/        # Ejecutable (entry point)
│   │   └── main.swift
│   └── KeyboardCleanerLib/     # Librería principal
│       ├── AppDelegate.swift
│       ├── AppState.swift          # Timer + UserDefaults
│       ├── KeyboardBlocker.swift   # CGEventTap
│       ├── OverlayView.swift       # Panel flotante SwiftUI
│       ├── OverlayWindowController.swift
│       ├── SettingsView.swift      # Slider de duración
│       └── StatusBarController.swift
├── Tests/
│   └── KeyboardCleanerTests/
│       └── AppStateTests.swift     # 6 unit tests
├── scripts/
│   └── build-app.sh            # Script de build y firma
└── Package.swift               # Swift Package Manager
```

<br>

## Stack técnico

- **Swift 5.9** + **SwiftUI** + **AppKit**
- **CGEventTap** (CoreGraphics) para bloqueo de teclado a nivel sistema
- **Combine** para el timer reactivo
- **Swift Package Manager** para gestión de dependencias
- **Swift Testing** para los tests unitarios

<br>

## Desarrollo

```bash
# Compilar en modo debug
swift build

# Ejecutar tests
swift test

# Compilar en modo release + crear .app
bash scripts/build-app.sh
```

<br>

## Contribuir

Pull requests bienvenidos. Para cambios grandes, abre primero un issue para discutir qué te gustaría cambiar.

<br>

---

<div align="center">

Desarrollada con ♥ por **NEXO AI**

*Herramientas inteligentes para personas reales*

</div>
