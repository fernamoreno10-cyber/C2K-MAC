# Keyboard Cleaner — Design Spec
**Date:** 2026-04-28  
**Stack:** Swift 5.9 + SwiftUI, macOS 13+  
**Status:** Approved

---

## Overview

App nativa macOS que bloquea todos los inputs del teclado mientras el usuario limpia físicamente el teclado. Vive en el menu bar, activa un overlay fullscreen al iniciar limpieza, y desbloquea automáticamente al vencer un timer configurable.

---

## Arquitectura de componentes

```
KeyboardCleanerApp          ← @main, AppDelegate + SwiftUI lifecycle
├── AppState                ← ObservableObject: isLocked, timeRemaining, duration
├── StatusBarController     ← NSStatusItem menu bar icon + menú contextual
├── KeyboardBlocker         ← CGEventTap: intercepta y cancela eventos de teclado
├── OverlayWindowController ← NSWindow fullscreen nivel screenSaver
├── OverlayView             ← SwiftUI: timer, barra progreso, estados, botón
└── SettingsView            ← SwiftUI sheet: slider duración (1–10 min)
```

---

## Flujo principal

1. App arranca → solo ícono en menu bar, sin ventana visible
2. Usuario hace clic en ícono → ítem "Limpiar teclado"
3. `KeyboardBlocker.start()` activa `CGEventTap` a nivel `.cgSessionEventTap`
4. `OverlayWindowController` presenta ventana fullscreen sobre todo
5. Timer corre cada segundo via `Timer.publish` en `AppState`
6. Al llegar a 0 **o** clic en botón "Terminado":
   - `KeyboardBlocker.stop()` elimina el tap
   - Overlay cierra
   - Sonido sutil del sistema (`NSSound.beep()`)

---

## Bloqueo de teclado — KeyboardBlocker

- **Nivel:** `.cgSessionEventTap` — intercepta antes de que cualquier app reciba el evento
- **Eventos bloqueados:** `.keyDown`, `.keyUp`, `.flagsChanged`
- **Eventos NO bloqueados:** mouse, trackpad — necesarios para clickear "Terminado"
- **Callback:** retorna `nil` para cada evento → el evento muere, no se propaga
- **Permiso requerido:** Accessibility (`AXIsProcessTrusted`)
  - Si no está autorizado: abre `System Settings > Privacy > Accessibility` automáticamente
- **Cleanup:** `CGEvent.tapEnable(tap, enable: false)` + `CFMachPortInvalidate` al detener

---

## Overlay — OverlayWindowController + OverlayView

**Window:**
- `NSWindow.level = .screenSaver` — flota sobre Dock, Spotlight, Mission Control
- `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]` — visible en todos los Spaces
- Sin barra de título, no redimensionable, cubre pantalla principal (`NSScreen.main`)

**OverlayView (SwiftUI) — spec visual exacta:**

| Elemento | Valor |
|---|---|
| Fondo | `#f5f5f7` |
| Ícono candado | stroke `#1d1d1f`, fondo círculo `#ffffff` |
| Label título | `"CLEAN MODE"`, uppercase, tracking 2px, color `#86868b` |
| Timer | tamaño 24px, peso 300, color `#1d1d1f`, `tabular-nums` |
| Barra progreso | ancho 320px, altura 6px, fill `#1d1d1f`, bg `#e0e0e0` |
| Dot teclado | `#ff3b30` + label `"Teclado bloqueado"` |
| Dot mouse | `#34c759` + label `"Mouse activo"` |
| Botón | texto `"Terminado"`, border `#d0d0d0`, bg `#ffffff`, text `#86868b`, pill 20px radius |

---

## Timer — AppState

- **Default:** 120 segundos (2 minutos)
- **Rango configurable:** 1–10 minutos
- **Mecanismo:** `Timer.publish(every: 1, on: .main, in: .common)` → decrementa `timeRemaining`
- **Al llegar a 0:** llama `KeyboardBlocker.stop()` + cierra overlay + `NSSound` feedback
- **Persiste duración:** `UserDefaults.standard` clave `"cleanDuration"`

---

## Menu Bar — StatusBarController

**Ícono:** SF Symbol `keyboard` (o `lock.fill` al estar activo)

**Menú contextual:**
- `Limpiar teclado` — inicia limpieza
- `Configurar...` — abre SettingsView como sheet
- `Salir` — `NSApp.terminate`

---

## Settings — SettingsView

`NSPanel` pequeño (no sheet — menu bar apps no tienen ventana principal para anclar sheets) con:
- Slider 1–10 minutos con label en tiempo real (`"2 min 30 seg"`)
- Botón "Listo" cierra el panel
- Cambios persisten inmediatamente en `UserDefaults`

---

## Permisos & distribución

- **Entitlement requerido:** `com.apple.security.accessibility` (solo si distribución App Store)
- **Sin App Store (recomendado):** sin sandbox, el CGEventTap funciona sin entitlement adicional
- **Info.plist:** `NSAccessibilityUsageDescription` + mensaje de por qué se necesita Accessibility
- **Firma:** local `codesign` para uso personal, o Developer ID para distribuir

---

## Archivos del proyecto

```
KeyboardCleaner/
├── KeyboardCleanerApp.swift
├── AppState.swift
├── StatusBarController.swift
├── KeyboardBlocker.swift
├── OverlayWindowController.swift
├── OverlayView.swift
└── SettingsView.swift
```
